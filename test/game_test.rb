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

  def test_handle_look_examines_item_in_inventory
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    sword = Weapon.new("Test Sword", "A sharp blade", 5)
    @game.player.add_item(sword)
    assert_output(/Test Sword.*A sharp blade/m) { @game.handle_look(["Test", "Sword"]) }
  end

  def test_handle_look_examines_item_in_room
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    potion = Potion.new("Test Potion", "Healing elixir", 20)
    @game.current_room.add_item(potion)
    assert_output(/Test Potion.*Healing elixir/m) { @game.handle_look(["Test", "Potion"]) }
  end

  def test_handle_look_shows_weapon_stats
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    sword = Weapon.new("Test Sword", "A sharp blade", 5)
    @game.player.add_item(sword)
    assert_output(/Attack Bonus: \+5/) { @game.handle_look(["Test", "Sword"]) }
  end

  def test_handle_look_shows_armor_stats
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    armor = Armor.new("Test Armor", "Protective gear", 3)
    @game.player.add_item(armor)
    assert_output(/Defense Bonus: \+3/) { @game.handle_look(["Test", "Armor"]) }
  end

  def test_handle_solve_displays_puzzle_description
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    @game.instance_variable_set(:@current_room, @game.rooms[:library])
    assert_output(/I speak without a mouth/m) { @game.handle_solve([]) }
  end

  def test_handle_solve_with_correct_answer
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    @game.instance_variable_set(:@current_room, @game.rooms[:library])
    assert_output(/Correct!/) { @game.handle_solve(["echo"]) }
  end

  def test_treasure_room_is_locked
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    treasure_room = @game.rooms[:treasure_room]
    refute treasure_room.can_enter?(@game.player)
  end

  def test_treasure_room_unlockable_with_master_key
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    # Move to library (south of treasure room)
    @game.instance_variable_set(:@current_room, @game.rooms[:library])
    @game.player.move_to_room(@game.rooms[:library])
    treasure_room = @game.rooms[:treasure_room]
    # Give player master key
    master_key = Key.new("Master Key", "An ornate key")
    @game.player.add_item(master_key)
    # Unlock the door
    @game.handle_unlock(["north"])
    # Now should be able to enter
    assert treasure_room.can_enter?(@game.player)
  end

  def test_handle_move_displays_room_automatically
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    # Moving to a new room should automatically display room description
    assert_output(/ARMORY/m) { @game.handle_move(["north"]) }
  end

  def test_handle_solve_with_puzzle_word_shows_question
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    @game.instance_variable_set(:@current_room, @game.rooms[:library])
    # "solve puzzle" should show question, not treat "puzzle" as answer
    output = capture_io { @game.handle_solve(["puzzle"]) }.join
    assert_match(/I speak without a mouth/m, output)
    refute_match(/Incorrect/m, output)
  end

  def test_locked_room_blocks_entry_even_with_key
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    # Give player the master key
    master_key = Key.new("Master Key", "An ornate key")
    @game.player.add_item(master_key)
    # Move to library
    @game.instance_variable_set(:@current_room, @game.rooms[:library])
    @game.player.move_to_room(@game.rooms[:library])
    # Try to go north to treasure room - should be blocked
    assert_output(/locked/i) { @game.handle_move(["north"]) }
    # Should still be in library
    assert_equal @game.rooms[:library], @game.current_room
  end

  def test_save_and_load_preserves_game_state
    @game.instance_variable_set(:@player, Player.new("TestPlayer"))
    @game.initialize_world
    # Move to armory
    @game.handle_move(["north"])
    # Save game
    @game.handle_save(["test_save_load"])
    # Create new game and load
    new_game = Game.new
    new_game.handle_load(["test_save_load"])
    # Should be in armory
    assert_equal "Armory", new_game.current_room.name
    assert_equal "TestPlayer", new_game.player.name
    # Clean up
    File.delete("saves/test_save_load.json") if File.exist?("saves/test_save_load.json")
  end

  def test_game_has_narrator
    assert_instance_of Narrator, @game.narrator
  end

  def test_narrator_enabled_by_default
    assert @game.narrator.enabled?
  end

  def test_display_prologue_shows_backstory
    output = capture_io { @game.display_prologue }.join
    assert_match(/Dark Lord/i, output)
    assert_match(/Princess/i, output)
    assert_match(/kingdom/i, output)
  end

  def test_victory_message_mentions_princess
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.instance_variable_set(:@win_condition_met, true)
    output = capture_io { @game.display_goodbye }.join
    assert_match(/princess/i, output)
  end

  def test_narrator_comments_on_movement
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world

    # Get output without narrator
    @game.narrator.disable
    output_without = capture_io { @game.handle_move(["north"]) }.join

    # Reset position and get output with narrator
    @game.instance_variable_set(:@current_room, @game.rooms[:entrance])
    @game.player.move_to_room(@game.current_room)
    @game.narrator.enable
    output_with = capture_io { @game.handle_move(["north"]) }.join

    # With narrator should have more content
    assert output_with.length > output_without.length, "Narrator should add commentary to output"
  end

  def test_narrator_can_be_disabled
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    @game.narrator.disable
    output = capture_io { @game.handle_move(["north"]) }.join
    # Should NOT contain narrator commentary when disabled
    refute_match(/hero|adventurer|ventured/i, output)
  end

  def test_handle_narrator_shows_status_without_args
    output = capture_io { @game.handle_narrator([]) }.join
    assert_match(/enabled|disabled/i, output)
  end

  def test_handle_narrator_enables_narrator
    @game.narrator.disable
    output = capture_io { @game.handle_narrator(["on"]) }.join
    assert @game.narrator.enabled?
    assert_match(/enabled/i, output)
  end

  def test_handle_narrator_disables_narrator
    @game.narrator.enable
    output = capture_io { @game.handle_narrator(["off"]) }.join
    refute @game.narrator.enabled?
    assert_match(/disabled/i, output)
  end

  def test_handle_narrator_invalid_option
    output = capture_io { @game.handle_narrator(["invalid"]) }.join
    assert_match(/invalid/i, output)
  end

  def test_map_item_exists_in_entrance
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    assert @game.current_room.has_item?("Tower Map"), "Map should be in entrance hall"
  end

  def test_handle_look_map_displays_map
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    output = capture_io { @game.handle_look(["Tower", "Map"]) }.join
    assert_match(/DARK TOWER MAP/i, output)
    assert_match(/Legend:/i, output)
  end

  def test_map_shows_current_location
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    output = capture_io { @game.handle_look(["Tower", "Map"]) }.join
    # Should show [X] for current location (Entrance)
    assert_match(/\[X\]/, output)
  end

  def test_map_shows_visited_rooms
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    # Take the map first
    @game.handle_take(["Tower", "Map"])
    # Move to courtyard (west) which has no enemies, then move back
    @game.handle_move(["west"])
    @game.handle_move(["east"])
    # Now we're back at entrance, courtyard should show as visited
    output = capture_io { @game.handle_look(["Tower", "Map"]) }.join
    # Should show [Courtyard] for visited room that's not current
    assert_match(/\[Courtyard\]/, output)
    # Should show [X] for current location (Entrance)
    assert_match(/\[X\]/, output)
    # Entrance is current, so should NOT show [Entrance] separately
    refute_match(/\[Entrance\]/, output)
  end

  def test_map_shows_unvisited_rooms
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    output = capture_io { @game.handle_look(["Tower", "Map"]) }.join
    # Should show [ ] for unvisited rooms
    assert_match(/\[ \]/, output)
  end

  def test_map_legend_explains_symbols
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world
    output = capture_io { @game.handle_look(["Tower", "Map"]) }.join
    assert_match(/\[X\] = Current location/, output)
    assert_match(/\[Name\] = Visited room/, output)
    assert_match(/\[ \] = Unvisited room/, output)
  end

  def test_game_does_not_end_when_dark_lord_killed_without_talking_to_princess
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world

    # Kill all enemies in throne room (Dark Lord)
    throne_room = @game.rooms[:throne_room]
    throne_room.instance_variable_get(:@enemies).clear

    # Check win condition
    @game.send(:check_win_condition)

    # Game should NOT be over yet (princess not talked to)
    refute @game.instance_variable_get(:@game_over), "Game should not end without talking to Princess"
    refute @game.instance_variable_get(:@win_condition_met), "Win condition should not be met"
  end

  def test_game_ends_when_dark_lord_killed_and_princess_talked_to
    @game.instance_variable_set(:@player, Player.new("Test"))
    @game.initialize_world

    # Kill all enemies in throne room (Dark Lord)
    throne_room = @game.rooms[:throne_room]
    throne_room.instance_variable_get(:@enemies).clear

    # Talk to Princess Elena
    princess = @game.instance_variable_get(:@princess)
    princess.talk

    # Check win condition
    @game.send(:check_win_condition)

    # Game SHOULD be over now (Dark Lord dead AND princess talked to)
    assert @game.instance_variable_get(:@game_over), "Game should end after defeating Dark Lord and talking to Princess"
    assert @game.instance_variable_get(:@win_condition_met), "Win condition should be met"
  end
end
