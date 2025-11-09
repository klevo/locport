# frozen_string_literal: true

require "thor"
require "locport/indexer"

module Locport
  class Main < Thor
    COLOR_FAINT  = "\e[2m"

    default_task :list

    def self.exit_on_failure?
      true
    end

    desc "index [PATH]", "Add project path(s) to locport"
    method_option :recursive, type: :boolean, default: false, aliases: "-r"
    def index(*paths)
      paths.each do |path|
        say "Indexing "
        say path, :blue
        indexer.index(path, recursive: options.recursive, shell:)
      end

      indexer.save

      say "Done ✓", :green
    end

    desc "add [HOST[:PORT]]", "Add a new host to .localhost file. \
      Without arguments current directory name will be used and random port number assigned."
    def add(host = "#{File.basename(Dir.pwd)}.localhost")
      address = indexer.create_address host

      say_address_conflicts address
      
      if @conflicts_found
        say "Can't add due to conflicts"
        exit 1
      end

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
      say "Index file: #{indexer.storage_path}"
    end

    private
      def indexer
        @indexer ||= Indexer.new
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
