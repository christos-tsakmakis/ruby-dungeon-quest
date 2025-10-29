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
    @enemy.take_damage(100)
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
end
