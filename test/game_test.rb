require 'test_helper'

class GameTest < Minitest::Test
  def setup
    @game = Game.new
  end

  def test_creates_new_game_with_initial_state
    assert_nil @game.player
    assert_empty @game.rooms
    refute @game.game_over
  end

  def test_setup_player_creates_player_with_given_name
    @game.stub :gets, "TestHero\n" do
      @game.setup_player
      assert_equal "TestHero", @game.player.name
    end
  end

  def test_setup_player_uses_default_name_for_empty_input
    @game.stub :gets, "\n" do
      @game.setup_player
      assert_equal "Adventurer", @game.player.name
    end
  end

  def test_initialize_world_creates_all_rooms
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    assert_includes @game.rooms.keys, :entrance
    assert_includes @game.rooms.keys, :armory
    assert_includes @game.rooms.keys, :library
    assert_includes @game.rooms.keys, :dungeon
    assert_includes @game.rooms.keys, :treasure_room
    assert_includes @game.rooms.keys, :throne_room
  end

  def test_initialize_world_places_player_in_entrance
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    assert_equal "Entrance Hall", @game.current_room.name
    assert_equal @game.current_room, @game.player.current_room
  end

  def test_initialize_world_marks_entrance_as_visited
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    assert @game.current_room.visited
  end

  def test_handle_move_moves_to_connected_room
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    @game.handle_move(["north"])
    assert_equal "Armory", @game.current_room.name
  end

  def test_handle_move_does_not_move_to_nonexistent_direction
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    current = @game.current_room
    @game.handle_move(["south"])
    assert_equal current, @game.current_room
  end

  def test_handle_move_prints_error_for_invalid_direction
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    assert_output(/Invalid direction/) { @game.handle_move(["invalid"]) }
  end

  def test_handle_take_allows_player_to_take_items
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    item = @game.current_room.items.first
    if item
      item_name = item.name
      @game.handle_take([item_name])
      assert @game.player.has_item?(item_name)
    else
      skip "No items in entrance room"
    end
  end

  def test_handle_drop_allows_player_to_drop_items
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    item = Item.new("Test Item", "A test")
    @game.player.add_item(item)
    @game.handle_drop(["Test", "Item"])
    assert @game.current_room.has_item?("Test Item")
  end
end
