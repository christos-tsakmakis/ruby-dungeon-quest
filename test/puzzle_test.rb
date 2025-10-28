require 'test_helper'

class PuzzleTest < Minitest::Test
  def setup
    @puzzle = Puzzle.new("Test Puzzle", "Solve this", max_attempts: 3)
    @reward = Item.new("Prize", "A reward")
  end

  def test_creates_puzzle_with_correct_properties
    assert_equal "Test Puzzle", @puzzle.name
    assert_equal 3, @puzzle.attempts_left
    refute @puzzle.solved?
  end

  def test_raises_error_for_invalid_parameters
    assert_raises(ArgumentError) { Puzzle.new("", "desc") }
    assert_raises(ArgumentError) { Puzzle.new("name", "") }
    assert_raises(ArgumentError) { Puzzle.new("name", "desc", max_attempts: 0) }
  end

  def test_set_reward
    @puzzle.set_reward(@reward)
    assert_equal @reward, @puzzle.reward
  end

  def test_set_reward_raises_error_for_nil
    assert_raises(ArgumentError) { @puzzle.set_reward(nil) }
  end

  def test_can_attempt_returns_true_when_attempts_remain
    assert @puzzle.can_attempt?
  end

  def test_can_attempt_returns_false_when_no_attempts_left
    3.times { @puzzle.instance_variable_set(:@attempts_left, @puzzle.attempts_left - 1) }
    refute @puzzle.can_attempt?
  end

  def test_reset_resets_to_initial_state
    @puzzle.instance_variable_set(:@attempts_left, 0)
    @puzzle.instance_variable_set(:@solved, true)
    @puzzle.reset
    assert_equal 3, @puzzle.attempts_left
    refute @puzzle.solved?
  end
end

class RiddlePuzzleTest < Minitest::Test
  def setup
    @riddle = RiddlePuzzle.new("Riddle", "What am I?", "echo", max_attempts: 3)
    @reward = Item.new("Prize", "A reward")
  end

  def test_creates_riddle_puzzle
    assert_equal "Riddle", @riddle.name
  end

  def test_raises_error_for_empty_answer
    assert_raises(ArgumentError) { RiddlePuzzle.new("R", "desc", "") }
  end

  def test_attempt_succeeds_with_correct_answer
    @riddle.set_reward(@reward)
    result = @riddle.attempt("echo")
    assert result[:success]
    assert_equal @reward, result[:reward]
    assert @riddle.solved?
  end

  def test_attempt_fails_with_incorrect_answer
    @riddle.set_reward(@reward)
    result = @riddle.attempt("wrong")
    refute result[:success]
    assert_equal 2, @riddle.attempts_left
  end

  def test_attempt_is_case_insensitive
    @riddle.set_reward(@reward)
    result = @riddle.attempt("ECHO")
    assert result[:success]
  end

  def test_attempt_raises_error_when_already_solved
    @riddle.set_reward(@reward)
    @riddle.attempt("echo")
    error = assert_raises(RuntimeError) { @riddle.attempt("echo") }
    assert_equal "Puzzle is already solved", error.message
  end

  def test_attempt_raises_error_when_no_attempts_left
    3.times { @riddle.attempt("wrong") }
    error = assert_raises(RuntimeError) { @riddle.attempt("echo") }
    assert_equal "No attempts left", error.message
  end
end

class CodePuzzleTest < Minitest::Test
  def setup
    @code = CodePuzzle.new("Lock", "Enter code", "1234")
  end

  def test_attempt_succeeds_with_correct_code
    result = @code.attempt("1234")
    assert result[:success]
  end

  def test_attempt_fails_with_incorrect_code
    result = @code.attempt("5678")
    refute result[:success]
  end
end

class SequencePuzzleTest < Minitest::Test
  def setup
    @seq = SequencePuzzle.new("Pattern", "Enter sequence", ["red", "blue", "green"])
  end

  def test_attempt_succeeds_with_correct_sequence
    result = @seq.attempt("red, blue, green")
    assert result[:success]
  end

  def test_attempt_fails_with_incorrect_sequence
    result = @seq.attempt("blue, red, green")
    refute result[:success]
  end

  def test_attempt_fails_with_wrong_length
    result = @seq.attempt("red, blue")
    refute result[:success]
  end
end
