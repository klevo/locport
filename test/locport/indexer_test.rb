# frozen_string_literal: true

module Locport
  class IndexerTest < Minitest::Test
    def setup
      @projects_path = Pathname.new File.expand_path("../fixtures/projects", __dir__)
      assert Dir.exist?(@projects_path)
      storage_base_dir = File.expand_path("../fixtures/data")
      @indexer = Indexer.new(home_path: File.dirname(@projects_path), storage_base_dir:)
    end

    def test_default_storage_base_dir
      indexer = Indexer.new
      refute_predicate indexer.default_storage_base_dir, :empty?
    end

    def test_index
      expected = [ @projects_path.join("alpha/.localhost") ]
      assert_equal expected, @indexer.index(@projects_path.join("alpha"))
      assert_equal expected, @indexer.dotfiles

      # Indexing another directory adds onto existing dotfiles
      @indexer.index(@projects_path.join("beta"))
      assert_equal 2, @indexer.dotfiles.size
      assert_equal expected.first, @indexer.dotfiles.first

      # Idempotency
      @indexer.index(@projects_path.join("beta"))
      assert_equal 2, @indexer.dotfiles.size
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

    def test_save_index_and_load_dotfiles
      tmpdir = Dir.mktmpdir
      indexer = Indexer.new(storage_base_dir: tmpdir)
      indexer.index(@projects_path, recursive: true)

      assert indexer.save
      assert File.exist?("#{tmpdir}/locport/projects")

      expected = [
        @projects_path.join("alpha"),
        @projects_path.join("beta")
      ]
      assert_equal expected.join("\n"), File.read("#{tmpdir}/locport/projects")
      assert_equal expected.map { |path| path.join(Indexer::DOTFILE) }, indexer.load_dotfiles
    ensure
      FileUtils.rm_rf tmpdir
    end

    def test_projects
      @indexer.index(@projects_path, recursive: true)

      expected = {
        "~/projects/alpha" => [
          Address.new("http://alpha.localhost", 30000, @projects_path.join("alpha", ".localhost").to_s, 0),
          Address.new("http://sub.alpha.localhost", 30001, @projects_path.join("alpha", ".localhost").to_s, 1),
          Address.new("livereload", 40003, @projects_path.join("alpha", ".localhost").to_s, 2)
        ],
        "~/projects/beta" => [
          Address.new("http://beta.localhost", 31000, @projects_path.join("beta", ".localhost").to_s, 0)
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
