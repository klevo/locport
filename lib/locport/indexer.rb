# frozen_string_literal: true

module Locport
  class Indexer
    DOTFILE = ".localhost"

    attr_reader :projects

    def initialize
      @projects = {}
    end

    def index(path)
      project_path = Pathname.new(path).cleanpath
      project_path.join(DOTFILE)
    end
  end
end
