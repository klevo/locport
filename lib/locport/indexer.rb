# frozen_string_literal: true

require "find"

module Locport
  class Indexer
    DOTFILE = ".localhost"

    attr_reader :projects

    def initialize
      @projects = {}
    end

    def index(start_path, recursive: false)
      unless recursive
        return index_directory(start_path)
      else
        [].tap do |result|
          Find.find(start_path) do |path|
            if File.basename(path) == DOTFILE && File.file?(path)
              result << Pathname.new(path)
            end
          end
        end
      end
    end

    private
      def index_directory(path)
        project_path = Pathname.new(path).cleanpath
        project_path.join(DOTFILE)
      end
  end
end
