# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/npc"

class NPCTest < Minitest::Test
  def setup
    @dialogue = [
      "Greetings, brave adventurer!",
      "The Dark Lord grows stronger each day.",
      "I've heard rumors of a secret passage."
    ]
    @npc = NPC.new("Old Guard", "A weathered guard with gray hair", @dialogue)
  end

  def test_creates_npc_with_correct_attributes
    assert_equal "Old Guard", @npc.name
    assert_equal "A weathered guard with gray hair", @npc.description
  end

  def test_npc_initializes_with_not_talked_state
    npc = NPC.new("Test", "Test NPC", ["Hello"])
    assert_equal :not_talked, npc.state
  end

  def test_npc_initializes_with_zero_talked_count
    npc = NPC.new("Test", "Test NPC", ["Hello"])
    assert_equal 0, npc.talked_count
  end

  def test_raises_error_for_nil_name
    assert_raises(ArgumentError) do
      NPC.new(nil, "Description", ["Hello"])
    end
  end

  def test_raises_error_for_empty_name
    assert_raises(ArgumentError) do
      NPC.new("", "Description", ["Hello"])
    end
  end

  def test_raises_error_for_nil_description
    assert_raises(ArgumentError) do
      NPC.new("Name", nil, ["Hello"])
    end
  end

  def test_raises_error_for_empty_description
    assert_raises(ArgumentError) do
      NPC.new("Name", "", ["Hello"])
    end
  end

  def test_raises_error_for_nil_dialogue
    assert_raises(ArgumentError) do
      NPC.new("Name", "Description", nil)
    end
  end

  def test_raises_error_for_empty_dialogue_array
    assert_raises(ArgumentError) do
      NPC.new("Name", "Description", [])
    end
  end

  def test_talk_returns_first_dialogue_on_first_call
    dialogue = @npc.talk
    assert_equal "Greetings, brave adventurer!", dialogue
  end

  def test_talk_increments_talked_count
    initial_count = @npc.talked_count
    @npc.talk
    assert_equal initial_count + 1, @npc.talked_count
  end

  def test_talk_changes_state_to_talked
    @npc.talk
    assert_equal :talked, @npc.state
  end

  def test_talk_cycles_through_dialogue
    first = @npc.talk
    second = @npc.talk
    third = @npc.talk

    assert_equal "Greetings, brave adventurer!", first
    assert_equal "The Dark Lord grows stronger each day.", second
    assert_equal "I've heard rumors of a secret passage.", third
  end

  def test_talk_loops_back_to_first_dialogue
    @dialogue.length.times { @npc.talk }  # Exhaust all dialogue
    next_dialogue = @npc.talk

    # Should loop back to first dialogue
    assert_equal "Greetings, brave adventurer!", next_dialogue
  end

  def test_talked_count_continues_increasing
    10.times { @npc.talk }
    assert_equal 10, @npc.talked_count
  end

  def test_single_dialogue_string_works
    npc = NPC.new("Simple NPC", "A simple character", ["Only one thing to say"])

    dialogue1 = npc.talk
    dialogue2 = npc.talk

    assert_equal "Only one thing to say", dialogue1
    assert_equal "Only one thing to say", dialogue2
  end

  def test_serialization_to_hash
    @npc.talk  # Change state
    @npc.talk  # Increment count

    hash = @npc.to_h

    assert_equal "Old Guard", hash[:name]
    assert_equal "A weathered guard with gray hair", hash[:description]
    assert_equal @dialogue, hash[:dialogue]
    assert_equal :talked, hash[:state]
    assert_equal 2, hash[:talked_count]
  end

  def test_deserialization_from_hash
    data = {
      name: "Test NPC",
      description: "Test description",
      dialogue: ["Line 1", "Line 2"],
      state: :talked,
      talked_count: 5
    }

    npc = NPC.from_h(data)

    assert_equal "Test NPC", npc.name
    assert_equal "Test description", npc.description
    assert_equal :talked, npc.state
    assert_equal 5, npc.talked_count
  end

  def test_deserialization_preserves_dialogue_state
    # Talk twice, then serialize and deserialize
    @npc.talk
    @npc.talk

    data = @npc.to_h
    restored = NPC.from_h(data)

    # Next dialogue should be the third one
    assert_equal "I've heard rumors of a secret passage.", restored.talk
  end

  def test_deserialization_with_string_keys
    data = {
      'name' => "String Keys",
      'description' => "Uses string keys",
      'dialogue' => ["Hello"],
      'state' => 'talked',
      'talked_count' => 3
    }

    npc = NPC.from_h(data)

    assert_equal "String Keys", npc.name
    assert_equal :talked, npc.state
    assert_equal 3, npc.talked_count
  end
end
