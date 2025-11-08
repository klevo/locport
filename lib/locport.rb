# frozen_string_literal: true

require "thor"
require "locport/indexer"

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
      host = host_with_port.split(":").first

      if used_ports.include?(port)
        say_error "Port #{port} is "
        say_error "already used. ", :red
        say_error "See `locport list`"
        exit 1
      end

      if used_hosts.include?(host)
        say_error "Host '#{host}' is " 
        say_error "already used. ", :red
        say_error "See `locport list`"
        exit 1
      end

      append_to_dotfile host_with_port
      index silent: true

      say "#{host_with_port} ", :bold 
      say "added ", :green
      say "to #{DOTFILE}"
    end

    desc "list", "List indexed projects, hosts and ports"
    def list
      table_data = []
      used_ports = []
      used_hosts = []
      conflicts_found = false

      indexer.projects.each do |dir, addresses|
        addresses.each do |(host, port)|
          table_data << [ dir.sub(Dir.home, "~"), "http://#{host}:#{port}" ]

          if used_ports.include?(port)
            conflicts_found = true
            table_data << [ "", "╰ Port used before" ]
          else
            used_ports << port
          end

          if used_hosts.include?(host)
            conflicts_found = true
            table_data << [ "", "╰ Host used before" ]
          else
            used_hosts << host
          end
        end
      end

      print_table [ [ "Indexer", "URL" ] ] + table_data, borders: true

      if conflicts_found
        say "Conflicts found!", :red
        exit 1
      else
        say "All hosts and ports are unique ✓", :green
      end
    end

    desc "info", "Display tool information"
    def info
      say "Indexers index: #{projects_file_path}"
    end

    private
      def indexer
        @indexer ||= Indexer.new
      end

      def projects
        load_projects
        @projects 
      end

      def used_ports
        load_projects
        @used_ports
      end

      def used_hosts
        load_projects
        @used_hosts
      end

      def load_projects
        @projects = []
        @used_ports = []
        @used_hosts = []

        File.read(projects_file_path).lines.each do |project_path|
          project_path = project_path.strip
          dotfile_path = Pathname.new(project_path).join(DOTFILE)
          next unless File.exist?(dotfile_path)

          hosts = File.read(dotfile_path).lines

          hosts.each do |host_with_port|
            host, port = host_with_port.strip.split(":")
            port = port.to_i
            @projects << [ project_path, host, port ]

            unless @used_ports.include?(port)
              @used_ports << port
            end

            unless @used_hosts.include?(host)
              @used_hosts << host
            end
          end
        end

        @projects
      rescue Errno::ENOENT
        @projects
      end

      def ensure_port(host)
        if host =~ /:([\d]+)$/
          [ host, $1.to_i ]
        else
          port = find_unused_port
          [ "#{host}:#{port}", port ]
        end
      end

      def find_unused_port
        loop do
          port = rand PORT_RANGE
          return port unless used_ports.include?(port)
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
        File.open(DOTFILE, "a") do |f|
          f.puts(line)
        end
      end
  end
end
