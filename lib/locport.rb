# frozen_string_literal: true

require "thor"
require "fileutils"

APP_NAME = "locport"
DATA_FILE = "projects"

module Locport
  class Main < Thor
    def self.exit_on_failure?
      true
    end

    desc "index [PATH]", "Index a project"
    def index(path = Dir.pwd)
      say "Indexing #{path}"
      say projects_file_path
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

      def projects_file_path
        FileUtils.mkdir_p(storage_dir)
        File.join(storage_dir, DATA_FILE)
      end

      def append_to_projects(line)
        File.open(projects_file_path, "a") do |f|
          f.puts(line)
        end
      end
  end
end
