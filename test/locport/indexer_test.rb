# frozen_string_literal: true

module Locport
  class IndexerTest < Minitest::Test
    def setup
      @indexer = Indexer.new
      @projects_path = File.expand_path("../fixtures/projects", __dir__)
      assert Dir.exist?(@projects_path)
    end

    def test_index
      @indexer.index(@projects_path)
    end

    def test_empty_projects
      assert_empty @indexer.projects
    end

    def test_projects
      skip
      
      @indexer.index(@projects_path)

      expected = {
        "~/projects/alpha" => [
          [ "http://alpha.localhost", 30000 ],
          [ "http://sub.alpha.localhost", 30001 ],
          [ "livereload", 40003 ]
        ],
        "~/projects/beta" => [
          [ "http://beta.localhost", 31000 ]
        ]
      }
      assert_equal expected, @indexer.projects
    end
  end
end
