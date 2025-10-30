# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/narrator"

class NarratorTest < Minitest::Test
  def setup
    @narrator = Narrator.new
  end

  def test_narrator_initializes_with_enabled_state
    assert @narrator.enabled?
  end

  def test_narrator_can_be_disabled
    @narrator.disable
    refute @narrator.enabled?
  end

  def test_narrator_can_be_enabled
    @narrator.disable
    @narrator.enable
    assert @narrator.enabled?
  end

  def test_narrate_returns_nil_when_disabled
    @narrator.disable
    result = @narrator.narrate(:move, direction: "north")
    assert_nil result
  end

  def test_narrate_returns_string_when_enabled
    result = @narrator.narrate(:move, direction: "north")
    assert_instance_of String, result
    refute_empty result
  end

  def test_narrate_movement_action
    result = @narrator.narrate(:move, direction: "north")
    assert_instance_of String, result
    # Should contain some narrative about movement
    assert result.length > 10
  end

  def test_narrate_combat_action
    result = @narrator.narrate(:attack, enemy: "Goblin")
    assert_instance_of String, result
    assert result.length > 10
  end

  def test_narrate_item_pickup
    result = @narrator.narrate(:take, item: "Health Potion")
    assert_instance_of String, result
    assert result.length > 10
  end

  def test_narrate_item_use
    result = @narrator.narrate(:use, item: "Health Potion")
    assert_instance_of String, result
    assert result.length > 10
  end

  def test_narrate_equip
    result = @narrator.narrate(:equip, item: "Iron Sword")
    assert_instance_of String, result
    assert result.length > 10
  end

  def test_narrate_flee
    result = @narrator.narrate(:flee)
    assert_instance_of String, result
    assert result.length > 10
  end

  def test_narrate_puzzle_solve
    result = @narrator.narrate(:solve, puzzle: "Riddle")
    assert_instance_of String, result
    assert result.length > 10
  end

  def test_narrate_death
    result = @narrator.narrate(:death)
    assert_instance_of String, result
    assert result.length > 10
  end

  def test_narrate_victory
    result = @narrator.narrate(:victory)
    assert_instance_of String, result
    assert result.length > 10
  end

  def test_narrate_unknown_action_returns_nil
    result = @narrator.narrate(:unknown_action)
    assert_nil result
  end

  def test_commentary_has_variation
    # Call narrate multiple times for same action
    results = 10.times.map { @narrator.narrate(:move, direction: "north") }

    # Should have at least 2 different responses in 10 tries
    # (unless we're extremely unlucky with randomness)
    unique_results = results.uniq
    assert unique_results.length >= 2, "Expected variation in narrator responses"
  end

  def test_narrate_handles_missing_context
    # Should work even without context parameters
    result = @narrator.narrate(:move)
    assert_instance_of String, result
  end

  def test_serialization_to_hash
    @narrator.disable
    hash = @narrator.to_h

    assert_equal false, hash[:enabled]
  end

  def test_deserialization_from_hash
    data = { enabled: false }
    narrator = Narrator.from_h(data)

    refute narrator.enabled?
  end

  def test_deserialization_with_enabled_state
    data = { enabled: true }
    narrator = Narrator.from_h(data)

    assert narrator.enabled?
  end

  def test_dodge_narration
    result = @narrator.narrate(:dodge, enemy: "Cave Troll")
    assert_instance_of String, result
    assert result.length > 10
  end

  def test_block_narration
    result = @narrator.narrate(:block, enemy: "Goblin")
    assert_instance_of String, result
    assert result.length > 10
  end

  def test_critical_hit_narration
    result = @narrator.narrate(:critical_hit, enemy: "Dark Knight")
    assert_instance_of String, result
    assert result.length > 10
  end

  def test_unlock_door_narration
    result = @narrator.narrate(:unlock, direction: "north")
    assert_instance_of String, result
    assert result.length > 10
  end

  def test_look_narration
    result = @narrator.narrate(:look)
    assert_instance_of String, result
    assert result.length > 10
  end
end
