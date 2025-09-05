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
    default_task :list
    
    def self.exit_on_failure?
      true
    end

    desc "index [PATH]", "Index a project"
    def index(path = Dir.pwd, silent: false)
      project_path = Pathname.new(path).cleanpath
      dotfile_path = project_path.join(DOTFILE)

      unless File.exist?(dotfile_path)
        say_error "#{dotfile_path} file doesn't exist", :red
        say_error "You can create it from within that directory with `locport add`"
        exit 1
      end

      append_to_projects project_path.to_s

      unless silent
        say "Indexing ", :green
        say project_path
      end
    end

    desc "add [HOST[:PORT]]", "Add a new host to .localhost file. \
      Without arguments current directory name will be used and random port number assigned."
    def add(host = "#{File.basename(Dir.pwd)}.localhost")
      host_with_port, port = ensure_port(host.strip)

      # if taken_by_path = port_taken?(port)
      #   say_error "Port #{port} is already taken by #{taken_by_path}"
      #   exit 1
      # end

      append_to_dotfile host_with_port
      index silent: true

      say "#{host_with_port} ", :bold 
      say "added ", :green
      say "to #{DOTFILE}"
    rescue HostAlreadyAddedError => e
      say_error e.message, :red
      exit 1
    end

    desc "list", "List indexed projects, hosts and ports"
    def list
      table_data = projects.map do |(dir, host, port)|
        [ dir.sub(Dir.home, "~"), "http://#{host}:#{port}" ]
      end
      print_table [ [ "Project", "URL" ] ] + table_data, borders: true
    end

    desc "info", "Display tool information"
    def info
      say "Projects index: #{projects_file_path}"
    end

    class HostAlreadyAddedError < StandardError; end

    private
      def projects
        @projects ||= load_projects
      end

      def load_projects
        result = []

        File.read(projects_file_path).lines.each do |project_path|
          project_path = project_path.strip
          dotfile_path = Pathname.new(project_path).join(DOTFILE)
          next unless File.exist?(dotfile_path)

          hosts = File.read(dotfile_path).lines

          hosts.each do |host_with_port|
            host, port = host_with_port.strip.split(":")
            result << [ project_path, host, port ]
          end
        end

        result
      end

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
        path_present = File.exist?(projects_file_path) && File.read(projects_file_path).lines.any? do
          it.strip == line
        end

        return if path_present 

        File.open(projects_file_path, "a") do |f|
          f.puts(line)
        end
      end

      def append_to_dotfile(line)
        host = line.split(":").first

        host_present = File.exist?(DOTFILE) && File.read(DOTFILE).lines.any? do
          it.split(":").first == host
        end

        if host_present
          raise HostAlreadyAddedError, "#{host} is already present in #{DOTFILE}"
        end

        File.open(DOTFILE, "a") do |f|
          f.puts(line)
        end
      end
  end
end
