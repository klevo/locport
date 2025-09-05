# frozen_string_literal: true

require "thor"

module Locport
  class Main < Thor
    def self.exit_on_failure?
      true
    end
  end
end
