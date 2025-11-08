# frozen_string_literal: true

require "find"
require "socket"

module Locport
  class Indexer
    APP_NAME = "locport"
    DOTFILE = ".localhost"
    DATA_FILE = "projects"

    attr_reader :projects, :dotfiles

    def initialize(home_path: Dir.home)
      @projects = {}
      @dotfiles = []
      @home_path = home_path
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
              result[key] << [ $1, $2.to_i ]
            end
          end
        end
      end
    end

    def port_open?(port)
      Socket.tcp("127.0.0.1", port, connect_timeout: 0.01) {}  # 10ms timeout
      true
    rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, SocketError
      false
    end

    def save(dir_path = storage_dir)
      FileUtils.mkdir_p(dir_path)
      path = Pathname.new(dir_path).join DATA_FILE
      File.write path, @dotfiles.join("\n")
    end

    private
      def storage_base_dir
        if Gem.win_platform?
          ENV["APPDATA"] || File.join(Dir.home, "AppData", "Roaming")
        else
          ENV["XDG_DATA_HOME"] || File.join(Dir.home, ".local", "share")
        end
      end

      def storage_dir
        File.join(storage_base_dir, APP_NAME)
      end
  end
end
