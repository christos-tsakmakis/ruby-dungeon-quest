require 'test_helper'

class InputHandlerTest < Minitest::Test
  def setup
    @handler = InputHandler.new
  end

  def test_parse_move_command
    result = @handler.parse("go north")
    assert_equal :move, result[:action]
    assert_equal ["north"], result[:args]
  end

  def test_parse_take_command
    result = @handler.parse("take sword")
    assert_equal :take, result[:action]
    assert_equal ["sword"], result[:args]
  end

  def test_parse_multi_word_arguments
    result = @handler.parse("take iron sword")
    assert_equal :take, result[:action]
    assert_equal ["iron", "sword"], result[:args]
  end

  def test_parse_handles_empty_input
    result = @handler.parse("")
    assert_equal :empty, result[:action]
  end

  def test_parse_handles_unknown_commands
    result = @handler.parse("dance")
    assert_equal :unknown, result[:action]
  end

  def test_parse_is_case_insensitive
    result = @handler.parse("LOOK")
    assert_equal :look, result[:action]
  end

  def test_parse_handles_extra_whitespace
    result = @handler.parse("  go   north  ")
    assert_equal :move, result[:action]
  end

  def test_parse_raises_error_for_nil
    assert_raises(ArgumentError) { @handler.parse(nil) }
  end

  def test_parse_direction_full_names
    assert_equal :north, @handler.parse_direction("north")
    assert_equal :south, @handler.parse_direction("south")
  end

  def test_parse_direction_shortcuts
    assert_equal :north, @handler.parse_direction("n")
    assert_equal :south, @handler.parse_direction("s")
    assert_equal :east, @handler.parse_direction("e")
    assert_equal :west, @handler.parse_direction("w")
  end

  def test_parse_direction_case_insensitive
    assert_equal :north, @handler.parse_direction("NORTH")
  end

  def test_parse_direction_returns_nil_for_invalid
    assert_nil @handler.parse_direction("invalid")
  end

  def test_valid_command_returns_true_for_valid
    assert @handler.valid_command?("look")
    assert @handler.valid_command?("go north")
  end

  def test_valid_command_returns_false_for_invalid
    refute @handler.valid_command?("dance")
    refute @handler.valid_command?("")
  end

  def test_suggest_commands_based_on_partial_input
    suggestions = @handler.suggest_commands("lo")
    assert_includes suggestions, "look"
    assert_includes suggestions, "load"
  end

  def test_suggest_commands_returns_empty_for_no_matches
    suggestions = @handler.suggest_commands("xyz")
    assert_empty suggestions
  end

  def test_suggest_commands_limits_to_5
    suggestions = @handler.suggest_commands("a")
    assert_operator suggestions.length, :<=, 5
  end

  def test_suggest_commands_handles_empty_input
    assert_equal [], @handler.suggest_commands("")
  end

  def test_help_text_returns_help_information
    help = @handler.help_text
    assert_includes help, "Available Commands"
    assert_includes help, "Movement"
    assert_includes help, "inventory"
  end
end
