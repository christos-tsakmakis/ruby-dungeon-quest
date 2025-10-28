require 'test_helper'

class EnemyTest < Minitest::Test
  def setup
    @enemy = Enemy.new("Goblin", "A fierce goblin", 50, 12, 3)
    @player = Player.new("Hero")
    @loot = Item.new("Gold", "Shiny gold")
  end

  def test_creates_enemy_with_correct_stats
    assert_equal "Goblin", @enemy.name
    assert_equal 50, @enemy.health
    assert_equal 50, @enemy.max_health
    assert_equal 12, @enemy.attack_power
    assert_equal 3, @enemy.defense
  end

  def test_raises_error_for_invalid_parameters
    assert_raises(ArgumentError) { Enemy.new("", "desc", 10, 5) }
    assert_raises(ArgumentError) { Enemy.new("name", "desc", 0, 5) }
    assert_raises(ArgumentError) { Enemy.new("name", "desc", 10, -1) }
  end

  def test_attack_deals_damage
    result = @enemy.attack(@player)
    assert_equal "Goblin", result[:attacker]
    assert_equal "Hero", result[:target]
    assert_operator result[:damage], :>, 0
  end

  def test_attack_raises_error_for_nil_target
    assert_raises(ArgumentError) { @enemy.attack(nil) }
  end

  def test_attack_raises_error_when_dead
    @enemy.take_damage(100)
    error = assert_raises(RuntimeError) { @enemy.attack(@player) }
    assert_equal "Enemy is dead and cannot attack", error.message
  end

  def test_take_damage_reduces_health
    actual = @enemy.take_damage(10)
    assert_equal 7, actual
    assert_equal 43, @enemy.health
  end

  def test_take_damage_does_not_reduce_below_zero
    @enemy.take_damage(100)
    assert_equal 0, @enemy.health
  end

  def test_take_damage_raises_error_for_negative
    assert_raises(ArgumentError) { @enemy.take_damage(-5) }
  end

  def test_alive_and_dead_when_alive
    assert @enemy.alive?
    refute @enemy.dead?
  end

  def test_alive_and_dead_when_dead
    @enemy.take_damage(100)
    refute @enemy.alive?
    assert @enemy.dead?
  end

  def test_add_loot_adds_to_enemy
    @enemy.add_loot(@loot)
    assert_includes @enemy.loot, @loot
  end

  def test_drop_loot_drops_all_and_clears
    @enemy.add_loot(@loot)
    dropped = @enemy.drop_loot
    assert_includes dropped, @loot
    assert_empty @enemy.loot
  end

  def test_add_loot_raises_error_for_nil
    assert_raises(ArgumentError) { @enemy.add_loot(nil) }
  end
end

class BossTest < Minitest::Test
  def setup
    @boss = Boss.new("Dark Lord", "Evil boss", 100, 20, 10, "Fireball")
    @player = Player.new("Hero")
  end

  def test_creates_boss_with_special_ability
    assert_equal "Dark Lord", @boss.name
    assert_equal "Fireball", @boss.special_ability_name
  end

  def test_use_special_ability_for_extra_damage
    result = @boss.use_special_ability(@player)
    assert_equal "Fireball", result[:special]
    assert_operator result[:damage], :>, 20
  end

  def test_use_special_ability_raises_error_when_dead
    @boss.take_damage(200)
    assert_raises(RuntimeError) { @boss.use_special_ability(@player) }
  end

  def test_use_special_ability_raises_error_for_nil_target
    assert_raises(ArgumentError) { @boss.use_special_ability(nil) }
  end
end
