# frozen_string_literal: true

require "thor"
require "fileutils"
require "pathname"

APP_NAME = "locport"
DATA_FILE = "projects"
DOTFILE = ".localhost"
PORT_RANGE = (30_000..60_000)

module Locport
  class Main < Thor
    def self.exit_on_failure?
      true
    end

    desc "index [PATH]", "Index a project"
    def index(path = Dir.pwd)
      dotfile_path = Pathname.new(path).join(DOTFILE)

      unless File.exist?(dotfile_path)
        say_error "#{dotfile_path} file doesn't exist", :red
        say_error "You can create it from within that directory with `locport add`"
        exit 1
      end

      say "Indexing #{dotfile_path}"
    end

    desc "add [HOST[:PORT]]", "Add a new host to .localhost file. \
      Without arguments current directory name will be used and random port number assigned."
    def add(host = "#{File.basename(Dir.pwd)}.localhost")
      host_with_port, port = ensure_port(host.strip)

      # append_to_dotfile()

      say host_with_port
      say port
    end

    private
      def ensure_port(host)
        if host =~ /:([\d]+)$/
          [ host, $1.to_i ]
        else
          port = rand PORT_RANGE
          [ "#{host}:#{port}", port ]
        end
      end

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

      def projects_file_path
        FileUtils.mkdir_p(storage_dir)
        File.join(storage_dir, DATA_FILE)
      end

      def append_to_projects(line)
        File.open(projects_file_path, "a") do |f|
          f.puts(line)
        end
      end

      def append_to_dotfile(line)
        File.open(DOTFILE, "a") do |f|
          f.puts(line)
        end
      end
  end
end
