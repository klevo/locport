# frozen_string_literal: true

require "thor"

module Locport
  class Main < Thor
    def self.exit_on_failure?
      true
    end

    desc "index [PATH]", "Index a project"
    def index(path = Dir.pwd)
      say "Indexing #{path}"
    end
  end
end
