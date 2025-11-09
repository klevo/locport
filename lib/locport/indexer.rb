# frozen_string_literal: true

require "find"
require "socket"

module Locport
  Address = Struct.new(:host, :port, :path, :line_number, :host_conflicts, :port_conflicts)

  class Indexer
    APP_NAME = "locport"
    DOTFILE = ".localhost"
    DATA_FILE = "projects"
    PORT_RANGE = (30_000..60_000)

    attr_reader :dotfiles, :projects, :addresses

    def initialize(home_path: Dir.home, storage_base_dir: default_storage_base_dir)
      @home_path = home_path
      @storage_base_dir = storage_base_dir
      @dotfiles = load_dotfiles
      @projects = load_projects
    end

    def index(path, recursive: false)
      start_path = path.to_s

      begin
        Find.find(start_path) do |path|
          break if !recursive && File.directory?(path) && path.size > start_path.size

          if File.basename(path) == DOTFILE && File.file?(path)
            @dotfiles << Pathname.new(path)
          end
        end
      rescue Errno::ENOENT
      end

      @dotfiles = @dotfiles.uniq.sort
    end

    def load_dotfiles
      File.read(storage_path).lines.map(&:strip).reject(&:empty?).map { |path| Pathname.new(path).join(DOTFILE) }
    rescue Errno::ENOENT
      []
    end

    def load_projects
      @projects = {}.tap do |result|
        @addresses = []

        @dotfiles.each do |path|
          File.read(path).each_line.with_index do |line, index|
            dir = File.dirname path.to_s

            key, source = cannonize_project_dir dir
            result[key] ||= []

            if line.strip =~ /^(.+):(\d+)$/
              address = Address.new($1, $2.to_i, source, index + 1)
              result[key] << address
              @addresses << address
            end
          end
        rescue Errno::ENOENT
        end

        reveal_address_conflicts
      end.sort.to_h
    end

    def port_listening?(port)
      Socket.tcp("127.0.0.1", port, connect_timeout: 0.01) {}  # 10ms timeout
      true
    rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, SocketError
      false
    end

    def save
      FileUtils.mkdir_p storage_dir
      File.write storage_path, @dotfiles.map { |path| File.dirname(path) }.join("\n")
    end

    def default_storage_base_dir
      if Gem.win_platform?
        ENV["APPDATA"] || File.join(Dir.home, "AppData", "Roaming")
      else
        ENV["XDG_DATA_HOME"] || File.join(Dir.home, ".local", "share")
      end
    end

    def create_address(value, dir: Dir.pwd)
      _, source = cannonize_project_dir dir

      address = if value.strip =~ /^(.+):(\d+)$/
        Address.new($1, $2.to_i, source)
      else
        Address.new(value, find_unused_port, source)
      end

      @addresses << address
      reveal_address_conflicts

      address
    end

    def append_address_to_dotfile(address, dir: Dir.pwd)
      _, _, fullpath = cannonize_project_dir dir

      File.open(fullpath, "a") do |file|
        file.puts("#{address.host}:#{address.port}")
      end
    end

    private
      def storage_dir
        File.join @storage_base_dir, APP_NAME
      end

      def storage_path
        File.join storage_dir, DATA_FILE
      end

      def cannonize_project_dir(dir)
        key = if dir.start_with?(@home_path.to_s)
          dir.sub(@home_path.to_s, "~")
        else
          dir
        end

        source = "#{key}/#{DOTFILE}"
        fullpath = "#{dir}/#{DOTFILE}"

        [ key, source, fullpath ]
      end

      def reveal_address_conflicts
        @addresses.each do |address|
          address.host_conflicts = nil
          address.port_conflicts = nil
        end

        @addresses.each do |address|
          @addresses.each do |other_address|
            next if address == other_address

            if address.host == other_address.host
              address.host_conflicts ||= []
              address.host_conflicts << other_address
            end

            if address.port == other_address.port
              address.port_conflicts ||= []
              address.port_conflicts << other_address
            end
          end
        end
      end

      def find_unused_port
        loop do
          port = rand PORT_RANGE
          return port unless @addresses.any? { |address| address.port == port } || port_listening?(port)
        end
      end
  end
end
