require 'test_helper'

class ItemTest < Minitest::Test
  def test_creates_item_with_name_and_description
    item = Item.new("Test Item", "A test description")
    assert_equal "Test Item", item.name
    assert_equal "A test description", item.description
    assert_equal :misc, item.type
  end

  def test_raises_error_for_empty_name
    assert_raises(ArgumentError) { Item.new("", "desc") }
  end

  def test_raises_error_for_empty_description
    assert_raises(ArgumentError) { Item.new("name", "") }
  end

  def test_serializes_basic_item
    item = Item.new("Test", "Desc", :misc)
    hash = item.to_h
    assert_equal "Test", hash[:name]
    assert_equal :misc, hash[:type]
  end
end

class WeaponTest < Minitest::Test
  def setup
    @weapon = Weapon.new("Iron Sword", "A sharp blade", 10)
  end

  def test_creates_weapon_with_attack_bonus
    assert_equal "Iron Sword", @weapon.name
    assert_equal 10, @weapon.attack_bonus
    assert_equal :weapon, @weapon.type
  end

  def test_raises_error_for_negative_attack_bonus
    assert_raises(ArgumentError) { Weapon.new("Bad", "desc", -5) }
  end

  def test_equippable_returns_true
    assert @weapon.equippable?
  end

  def test_to_h_includes_attack_bonus
    hash = @weapon.to_h
    assert_equal 10, hash[:attack_bonus]
  end
end

class ArmorTest < Minitest::Test
  def setup
    @armor = Armor.new("Steel Shield", "Sturdy protection", 8)
  end

  def test_creates_armor_with_defense_bonus
    assert_equal "Steel Shield", @armor.name
    assert_equal 8, @armor.defense_bonus
    assert_equal :armor, @armor.type
  end

  def test_raises_error_for_negative_defense_bonus
    assert_raises(ArgumentError) { Armor.new("Bad", "desc", -3) }
  end

  def test_equippable_returns_true
    assert @armor.equippable?
  end
end

class PotionTest < Minitest::Test
  def setup
    @potion = Potion.new("Health Potion", "Restores HP", 30)
    @player = Player.new("Test")
  end

  def test_creates_potion_with_heal_amount
    assert_equal "Health Potion", @potion.name
    assert_equal 30, @potion.heal_amount
    assert_equal :potion, @potion.type
  end

  def test_raises_error_for_non_positive_heal_amount
    assert_raises(ArgumentError) { Potion.new("Bad", "desc", 0) }
    assert_raises(ArgumentError) { Potion.new("Bad", "desc", -10) }
  end

  def test_usable_and_consumable_return_true
    assert @potion.usable?
    assert @potion.consumable?
  end

  def test_use_heals_the_player
    @player.health = 50
    result = @potion.use(@player)
    assert_equal "Healed 30 HP", result
    assert_equal 80, @player.health
  end
end

class KeyTest < Minitest::Test
  def setup
    @key = Key.new("Master Key", "Opens many doors")
  end

  def test_creates_a_key_item
    assert_equal "Master Key", @key.name
    assert_equal :key, @key.type
  end

  def test_usable_returns_false
    refute @key.usable?
  end
end
