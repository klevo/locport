# frozen_string_literal: true

module Locport
  class IndexerTest < Minitest::Test
    def setup
      @projects_path = Pathname.new File.expand_path("../fixtures/projects", __dir__)
      assert Dir.exist?(@projects_path)
      @indexer = Indexer.new(home_path: File.dirname(@projects_path))
    end

    def test_index
      expected = [ @projects_path.join("alpha/.localhost") ]
      assert_equal expected, @indexer.index(@projects_path.join("alpha"))
    end

    def test_empty_index
      assert_empty @indexer.index(@projects_path)
      assert_empty @indexer.index(@projects_path.join("doesnt-exist"))
    end

    def test_index_recursively
      expected = [
        @projects_path.join("alpha/.localhost"),
        @projects_path.join("beta/.localhost")
      ]
      assert_equal expected, @indexer.index(@projects_path, recursive: true)
    end

    def test_empty_projects
      assert_empty @indexer.projects
    end

    def test_projects
      @indexer.index(@projects_path, recursive: true)

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

    def test_port_open
      # port 0 means "assign an available port"
      server = TCPServer.new('127.0.0.1', 0)
      port = server.addr[1]
      assert @indexer.port_open?(port)

      server.close
      refute @indexer.port_open?(port)
    end
  end
end
