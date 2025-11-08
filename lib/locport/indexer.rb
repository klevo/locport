# frozen_string_literal: true

require "find"

module Locport
  class Indexer
    DOTFILE = ".localhost"

    attr_reader :projects

    def initialize
      @projects = {}
    end

    def index(path, recursive: false)
      start_path = path.to_s

      [].tap do |result|
        Find.find(start_path) do |path|
          break if !recursive && File.directory?(path) && path.size > start_path.size

          if File.basename(path) == DOTFILE && File.file?(path)
            result << Pathname.new(path)
          end
        end
      rescue Errno::ENOENT
      end
    end
  end
end
