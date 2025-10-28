require 'test_helper'

class PlayerTest < Minitest::Test
  def setup
    @player = Player.new("TestHero")
    @player.dodge_chance = 0
    @player.block_chance = 0
    @player.crit_chance = 0
    @sword = Weapon.new("Test Sword", "A test weapon", 5)
    @potion = Potion.new("Test Potion", "A test potion", 20)
    @room = Room.new("Test Room", "A test room")
  end

  def test_creates_player_with_correct_initial_stats
    assert_equal "TestHero", @player.name
    assert_equal 100, @player.health
    assert_equal 100, @player.max_health
    assert_equal 10, @player.attack_power
    assert_equal 5, @player.defense
    assert_empty @player.inventory
  end

  def test_add_item_adds_to_inventory
    @player.add_item(@potion)
    assert_includes @player.inventory, @potion
  end

  def test_add_item_raises_error_for_nil
    error = assert_raises(ArgumentError) { @player.add_item(nil) }
    assert_equal "Item cannot be nil", error.message
  end

  def test_add_item_does_not_auto_equip
    @player.add_item(@sword)
    assert_equal 10, @player.attack_power  # No auto-equip
    assert_includes @player.inventory, @sword
  end

  def test_equip_weapon_applies_effects
    @player.add_item(@sword)
    @player.equip("Test Sword")
    assert_equal 15, @player.attack_power
    assert_equal @sword, @player.equipped_weapon
    refute_includes @player.inventory, @sword  # Moved from inventory to equipped
  end

  def test_unequip_weapon_removes_effects
    @player.add_item(@sword)
    @player.equip("Test Sword")
    @player.unequip("Test Sword")
    assert_equal 10, @player.attack_power
    assert_nil @player.equipped_weapon
    assert_includes @player.inventory, @sword  # Back in inventory
  end

  def test_remove_item_removes_from_inventory
    @player.add_item(@sword)
    @player.remove_item(@sword)
    refute_includes @player.inventory, @sword
  end

  def test_remove_item_returns_false_when_not_in_inventory
    other_sword = Weapon.new("Other", "desc", 3)
    refute @player.remove_item(other_sword)
  end

  def test_has_item_returns_true_when_player_has_item
    @player.add_item(@sword)
    assert @player.has_item?("Test Sword")
  end

  def test_has_item_is_case_insensitive
    @player.add_item(@sword)
    assert @player.has_item?("test sword")
  end

  def test_has_item_returns_false_when_missing
    refute @player.has_item?("Missing Item")
  end

  def test_get_item_returns_item_if_found
    @player.add_item(@sword)
    assert_equal @sword, @player.get_item("Test Sword")
  end

  def test_get_item_returns_nil_if_not_found
    assert_nil @player.get_item("Missing")
  end

  def test_use_item_uses_consumable
    @player.health = 50
    @player.add_item(@potion)
    result = @player.use_item("Test Potion")
    assert_equal "Healed 20 HP", result
    assert_equal 70, @player.health
  end

  def test_use_item_removes_consumable_after_use
    @player.add_item(@potion)
    @player.use_item("Test Potion")
    refute_includes @player.inventory, @potion
  end

  def test_use_item_returns_nil_for_nonexistent_item
    assert_nil @player.use_item("Missing")
  end

  def test_take_damage_reduces_health
    result = @player.take_damage(15)
    assert_equal 10, result[:damage]
    assert_equal false, result[:dodged]
    assert_equal 90, @player.health
  end

  def test_take_damage_does_not_reduce_below_zero
    @player.take_damage(200)
    assert_equal 0, @player.health
  end

  def test_take_damage_does_no_damage_if_attack_less_than_defense
    result = @player.take_damage(3)
    assert_equal 0, result[:damage]
    assert_equal 100, @player.health
  end

  def test_heal_heals_player
    @player.health = 50
    healed = @player.heal(30)
    assert_equal 30, healed
    assert_equal 80, @player.health
  end

  def test_heal_does_not_heal_above_max
    @player.health = 50
    healed = @player.heal(100)
    assert_equal 50, healed
    assert_equal 100, @player.health
  end

  def test_heal_raises_error_for_negative_amount
    assert_raises(ArgumentError) { @player.heal(-10) }
  end

  def test_alive_and_dead_when_alive
    assert @player.alive?
    refute @player.dead?
  end

  def test_alive_and_dead_when_dead
    @player.health = 0
    refute @player.alive?
    assert @player.dead?
  end

  def test_move_to_room
    @player.move_to_room(@room)
    assert_equal @room, @player.current_room
  end

  def test_move_to_room_raises_error_for_nil
    assert_raises(ArgumentError) { @player.move_to_room(nil) }
  end

  def test_to_h_serializes_to_hash
    hash = @player.to_h
    assert_equal "TestHero", hash[:name]
    assert_equal 100, hash[:health]
  end

  def test_from_h_deserializes_from_hash
    hash = { name: "Restored", health: 75, max_health: 100, attack_power: 12, defense: 6, inventory: [] }
    restored = Player.from_h(hash)
    assert_equal "Restored", restored.name
    assert_equal 75, restored.health
  end
end
