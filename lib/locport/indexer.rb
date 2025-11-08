# frozen_string_literal: true

require "find"
require "socket"

module Locport
  Address = Struct.new(:host, :port)

  class Indexer
    APP_NAME = "locport"
    DOTFILE = ".localhost"
    DATA_FILE = "projects"

    attr_reader :dotfiles

    def initialize(home_path: Dir.home, storage_base_dir: default_storage_base_dir)
      @home_path = home_path
      @storage_base_dir = storage_base_dir
      @dotfiles = load_dotfiles
      @projects = {}
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

    def projects
      {}.tap do |result|
        @dotfiles.each do |path|
          File.read(path).lines do |line|
            path_s = File.dirname path.to_s

            key = if path_s.start_with?(@home_path.to_s)
              path_s.sub(@home_path.to_s, "~")
            else
              path_s
            end

            result[key] ||= []

            if line.strip =~ /^(.+):(\d+)$/
              result[key] << Address.new($1, $2.to_i)
            end
          end
        rescue Errno::ENOENT
        end
      end.sort.to_h
    end

    def port_open?(port)
      Socket.tcp("127.0.0.1", port, connect_timeout: 0.01) {}  # 10ms timeout
      true
    rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, SocketError
      false
    end

    def load_dotfiles
      File.read(storage_path).lines.map(&:strip).reject(&:empty?).map { |path| Pathname.new(path).join(DOTFILE) }
    rescue Errno::ENOENT
      []
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

    private
      def storage_dir
        File.join @storage_base_dir, APP_NAME
      end

      def storage_path
        File.join storage_dir, DATA_FILE
      end
  end
end
