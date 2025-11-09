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
    COLOR_FAINT  = "\e[2m"

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
      address = indexer.create_address host

      say_address_conflicts address
      exit 1 if @conflicts_found

      indexer.append_address_to_dotfile address

      say "#{address.host}:#{address.port} ", :bold 
      say "added ✓", :green
    end

    desc "list", "List indexed projects, hosts and ports"
    def list
      indexer.projects.each do |dir, addresses|
        say dir, :blue

        shell.indent do
          addresses.each do |address|
            port_color = indexer.port_listening?(address.port) ? :green : COLOR_FAINT
            say "• ", port_color

            shell.indent(-1) do
              say [ display_host(address.host), address.port ].join(":")
            end

            say_address_conflicts address
          end
        end
      end

      if @conflicts_found
        say "Conflicts found", :red
        exit 1
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

      def display_host(host)
        if host.include?("://")
          host
        else
          "http://#{host}"
        end
      end

      def say_address_conflicts(address)
        if address.port_conflicts
          @conflicts_found = true

          address.port_conflicts.each do |conflicting_address|
            say "╰ Port also at #{conflicting_address.path}:#{conflicting_address.line_number}", :red
          end
        end

        if address.host_conflicts
          @conflicts_found = true

          address.host_conflicts.each do |conflicting_address|
            say "╰ Host also at #{conflicting_address.path}:#{conflicting_address.line_number}", :red
          end
        end
      end
  end
end
