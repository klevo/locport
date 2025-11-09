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

    def test_load_projects
      @indexer.index(@projects_path, recursive: true)

      a = Address.new("http://alpha.localhost", 30000, "~/projects/alpha/.localhost", 1)
      b = Address.new("http://sub.alpha.localhost", 30001, "~/projects/alpha/.localhost", 2)
      c = Address.new("livereload", 40003, "~/projects/alpha/.localhost", 3)
      d = Address.new("http://beta.localhost", 31000, "~/projects/beta/.localhost", 1)
      e = Address.new("livereload", 40002, "~/projects/beta/.localhost", 5)
      f = Address.new("conflict.localhost", 30001, "~/projects/beta/.localhost", 6)

      b.port_conflicts = [ f ]
      c.host_conflicts = [ e ]
      f.port_conflicts = [ b ]
      e.host_conflicts = [ c ]

      expected = {
        "~/projects/alpha" => [ a, b, c ],
        "~/projects/beta" => [ d, e, f ]
      }
      assert_equal expected, @indexer.load_projects
    end

    def test_port_open
      # port 0 means "assign an available port"
      server = TCPServer.new('127.0.0.1', 0)
      port = server.addr[1]
      assert @indexer.port_open?(port)

      server.close
      refute @indexer.port_open?(port)
    end

    def test_create_address_without_conflicts
      dir = Dir.mktmpdir

      address = @indexer.create_address("hello.localhost:7777", dir:)
      assert_equal "hello.localhost", address.host
      assert_equal 7777, address.port
      assert_nil address.port_conflicts
      assert_nil address.host_conflicts
    ensure
      FileUtils.rm_rf dir
    end

    def test_create_address_with_conflicts
      dir = Dir.mktmpdir

      @indexer.index(@projects_path, recursive: true)
      @indexer.load_projects
      e, f = @indexer.addresses.last(2)

      address = @indexer.create_address("conflict.localhost:40002", dir:)
      assert_equal address, @indexer.addresses.last
      assert_equal "conflict.localhost", address.host
      assert_equal 40002, address.port
      assert_equal [ e ], address.port_conflicts
      assert_equal [ f ], address.host_conflicts
    ensure
      FileUtils.rm_rf dir
    end
  end
end
