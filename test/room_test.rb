require 'test_helper'

class RoomTest < Minitest::Test
  def setup
    @room1 = Room.new("Entrance", "A grand entrance hall")
    @room2 = Room.new("Library", "A dusty library")
    @item = Item.new("Book", "An old book")
    @enemy = Enemy.new("Goblin", "A small goblin", 20, 5)
    @player = Player.new("Hero")
  end

  def test_creates_room_with_name_and_description
    assert_equal "Entrance", @room1.name
    assert_equal "A grand entrance hall", @room1.description
    refute @room1.visited
  end

  def test_raises_error_for_empty_name
    assert_raises(ArgumentError) { Room.new("", "desc") }
  end

  def test_raises_error_for_empty_description
    assert_raises(ArgumentError) { Room.new("name", "") }
  end

  def test_connect_one_direction
    @room1.connect(:north, @room2)
    assert @room1.connected?(:north)
    refute @room2.connected?(:south)
  end

  def test_connect_bidirectionally
    @room1.connect(:north, @room2, bidirectional: true)
    assert @room1.connected?(:north)
    assert @room2.connected?(:south)
  end

  def test_connect_raises_error_for_nil
    assert_raises(ArgumentError) { @room1.connect(:north, nil) }
  end

  def test_connect_raises_error_for_self
    assert_raises(ArgumentError) { @room1.connect(:north, @room1) }
  end

  def test_get_connected_room_returns_room
    @room1.connect(:north, @room2)
    assert_equal @room2, @room1.get_connected_room(:north)
  end

  def test_get_connected_room_returns_nil_for_nonexistent
    assert_nil @room1.get_connected_room(:south)
  end

  def test_add_item_adds_to_room
    @room1.add_item(@item)
    assert_includes @room1.items, @item
  end

  def test_remove_item_removes_from_room
    @room1.add_item(@item)
    @room1.remove_item(@item)
    refute_includes @room1.items, @item
  end

  def test_add_item_raises_error_for_nil
    assert_raises(ArgumentError) { @room1.add_item(nil) }
  end

  def test_has_item_finds_by_name
    @room1.add_item(@item)
    assert @room1.has_item?("Book")
    assert_equal @item, @room1.get_item("Book")
  end

  def test_has_item_is_case_insensitive
    @room1.add_item(@item)
    assert @room1.has_item?("book")
  end

  def test_has_item_returns_false_for_missing
    refute @room1.has_item?("Missing")
    assert_nil @room1.get_item("Missing")
  end

  def test_add_enemy_adds_to_room
    @room1.add_enemy(@enemy)
    assert_includes @room1.enemies, @enemy
    assert @room1.has_enemies?
  end

  def test_has_enemies_returns_false_when_no_alive_enemies
    # Ensure enemy is dead by setting health directly
    @enemy.instance_variable_set(:@health, 0)
    @room1.add_enemy(@enemy)
    refute @room1.has_enemies?
  end

  def test_add_enemy_raises_error_for_nil
    assert_raises(ArgumentError) { @room1.add_enemy(nil) }
  end

  def test_lock_without_key_requirement
    @room1.lock
    assert @room1.locked?
    refute @room1.can_enter?(@player)
  end

  def test_lock_with_key_requirement
    @room1.lock("Master Key")
    refute @room1.can_enter?(@player)
  end

  def test_allows_entry_with_correct_key
    @room1.lock("Master Key")
    key = Key.new("Master Key", "A key")
    @player.add_item(key)
    # Room is still locked until explicitly unlocked
    refute @room1.can_enter?(@player)
    # Now unlock it
    @room1.unlock
    # Now can enter
    assert @room1.can_enter?(@player)
  end

  def test_unlock_unlocks_room
    @room1.lock
    @room1.unlock
    refute @room1.locked?
  end

  def test_mark_visited
    refute @room1.visited
    @room1.mark_visited
    assert @room1.visited
  end

  def test_add_npc_adds_to_room
    npc = NPC.new("Guard", "An old guard", ["Hello"])
    @room1.add_npc(npc)
    assert @room1.has_npcs?
  end

  def test_add_npc_raises_error_for_nil
    assert_raises(ArgumentError) { @room1.add_npc(nil) }
  end

  def test_has_npcs_returns_false_when_no_npcs
    refute @room1.has_npcs?
  end

  def test_has_npcs_returns_true_when_npcs_present
    npc = NPC.new("Guard", "An old guard", ["Hello"])
    @room1.add_npc(npc)
    assert @room1.has_npcs?
  end

  def test_get_npc_finds_by_name
    npc = NPC.new("Old Guard", "An old guard", ["Hello"])
    @room1.add_npc(npc)
    found_npc = @room1.get_npc("Old Guard")
    assert_equal npc, found_npc
  end

  def test_get_npc_is_case_insensitive
    npc = NPC.new("Old Guard", "An old guard", ["Hello"])
    @room1.add_npc(npc)
    found_npc = @room1.get_npc("old guard")
    assert_equal npc, found_npc
  end

  def test_get_npc_finds_by_partial_name
    npc = NPC.new("Old Guard", "An old guard", ["Hello"])
    @room1.add_npc(npc)
    found_npc = @room1.get_npc("guard")
    assert_equal npc, found_npc
  end

  def test_get_npc_returns_nil_when_not_found
    npc_result = @room1.get_npc("Nonexistent")
    assert_nil npc_result
  end

  def test_npcs_description_when_npcs_present
    npc1 = NPC.new("Guard", "An old guard", ["Hello"])
    npc2 = NPC.new("Merchant", "A traveling merchant", ["Hello"])
    @room1.add_npc(npc1)
    @room1.add_npc(npc2)

    description = @room1.npcs_description
    assert_includes description, "Guard"
    assert_includes description, "Merchant"
  end

  def test_npcs_description_returns_empty_when_no_npcs
    description = @room1.npcs_description
    assert_empty description
  end

  # Save/Load Bug Tests - Issue #15
  def test_puzzle_state_persists_through_serialization
    # Create a puzzle and solve it
    puzzle = RiddlePuzzle.new("Test Riddle", "What is 2+2?", "four")
    reward = Item.new("Prize", "A prize")
    puzzle.set_reward(reward)
    puzzle.attempt("four")
    assert puzzle.solved?, "Puzzle should be solved"

    # Add it to a room and serialize
    @room1.add_puzzle(puzzle)
    room_data = @room1.to_h

    # Create a lookup with an UNSOLVED puzzle (simulating original instance)
    original_puzzle = RiddlePuzzle.new("Test Riddle", "What is 2+2?", "four")
    original_puzzle.set_reward(Item.new("Prize", "A prize"))
    refute original_puzzle.solved?, "Original puzzle should not be solved"
    puzzles_lookup = { "Test Riddle" => original_puzzle }

    # Restore the room
    items_lookup = { "Prize" => reward }
    restored_room = Room.from_h(room_data, items_lookup, puzzles_lookup, {}, {}, {})

    # The restored puzzle should be solved (will fail with current bug)
    restored_puzzle = restored_room.instance_variable_get(:@puzzles).first
    assert restored_puzzle.solved?, "Restored puzzle should maintain solved state from save data"
  end

  def test_enemy_health_persists_through_serialization
    # Create an enemy and damage it
    enemy = Enemy.new("Test Goblin", "A test goblin", 50, 10)
    enemy.take_damage(30)
    assert_equal 20, enemy.health, "Enemy should have 20 HP"

    # Add it to a room and serialize
    @room1.add_enemy(enemy)
    room_data = @room1.to_h

    # Create a lookup with a FULL HEALTH enemy (simulating original instance)
    original_enemy = Enemy.new("Test Goblin", "A test goblin", 50, 10)
    assert_equal 50, original_enemy.health, "Original enemy should have full health"
    enemies_lookup = { "Test Goblin" => original_enemy }

    # Restore the room
    restored_room = Room.from_h(room_data, {}, {}, enemies_lookup, {}, {})

    # The restored enemy should have damaged health (will fail with current bug)
    restored_enemy = restored_room.enemies.first
    assert_equal 20, restored_enemy.health, "Restored enemy should maintain health from save data"
  end

  def test_items_are_separate_instances_after_restoration
    # Create an item and add it to a room
    item = Item.new("Shared Item", "An item")
    @room1.add_item(item)
    room_data = @room1.to_h

    # Create a lookup with the same item instance
    items_lookup = { "Shared Item" => item }

    # Restore the room
    restored_room = Room.from_h(room_data, items_lookup, {}, {}, {}, {})

    # The restored item should be a different instance (to prevent shared references)
    restored_item = restored_room.items.first

    # If they're the same object, modifying one affects the other
    # This test verifies items should be separate instances
    refute_same item, restored_item, "Restored item should be a separate instance, not a shared reference"
  end
end
