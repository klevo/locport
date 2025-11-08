# frozen_string_literal: true

require "find"

module Locport
  class Indexer
    DOTFILE = ".localhost"

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

      @dotfiles
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
  end
end
