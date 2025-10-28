require 'test_helper'
require 'fileutils'

class SaveManagerTest < Minitest::Test
  def setup
    @save_manager = SaveManager.new
    @game_state = { player: { name: "Hero", health: 100 }, room: "entrance" }
  end

  def teardown
    FileUtils.rm_rf('saves') if Dir.exist?('saves')
  end

  def test_save_game_saves_to_file
    assert @save_manager.save_game(@game_state, "test_save")
    assert File.exist?('saves/test_save.json')
  end

  def test_save_game_raises_error_for_nil_state
    assert_raises(ArgumentError) { @save_manager.save_game(nil, "test") }
  end

  def test_save_game_raises_error_for_empty_filename
    assert_raises(ArgumentError) { @save_manager.save_game(@game_state, "") }
  end

  def test_save_game_sanitizes_filename
    @save_manager.save_game(@game_state, "my save!")
    assert File.exist?('saves/my_save_.json')
  end

  def test_load_game_loads_from_file
    @save_manager.save_game(@game_state, "test_save")
    loaded = @save_manager.load_game("test_save")
    assert_equal "Hero", loaded[:player][:name]
  end

  def test_load_game_raises_error_for_nonexistent_file
    assert_raises(RuntimeError) { @save_manager.load_game("missing") }
  end

  def test_load_game_raises_error_for_empty_filename
    assert_raises(ArgumentError) { @save_manager.load_game("") }
  end

  def test_delete_save_deletes_file
    @save_manager.save_game(@game_state, "test_save")
    assert @save_manager.delete_save("test_save")
    refute File.exist?('saves/test_save.json')
  end

  def test_delete_save_returns_false_for_nonexistent
    refute @save_manager.delete_save("missing")
  end

  def test_list_saves_returns_empty_when_no_saves
    assert_equal [], @save_manager.list_saves
  end

  def test_list_saves_lists_all_files
    @save_manager.save_game(@game_state, "save1")
    @save_manager.save_game(@game_state, "save2")
    saves = @save_manager.list_saves
    assert_equal 2, saves.length
    assert_includes saves.map { |s| s[:name] }, "save1"
    assert_includes saves.map { |s| s[:name] }, "save2"
  end

  def test_save_exists_returns_false_when_missing
    refute @save_manager.save_exists?("missing")
  end

  def test_save_exists_returns_true_when_exists
    @save_manager.save_game(@game_state, "test_save")
    assert @save_manager.save_exists?("test_save")
  end

  def test_get_save_info_returns_information
    @save_manager.save_game(@game_state, "test_save")
    info = @save_manager.get_save_info("test_save")
    assert_equal "test_save", info[:name]
    assert_operator info[:size], :>, 0
    assert_instance_of Time, info[:modified]
  end

  def test_get_save_info_returns_nil_for_nonexistent
    assert_nil @save_manager.get_save_info("missing")
  end
end
