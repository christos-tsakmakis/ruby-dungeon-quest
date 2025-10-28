class Puzzle
  attr_reader :name, :description, :reward, :attempts_left

  def initialize(name, description, max_attempts: 3)
    raise ArgumentError, "Name cannot be empty" if name.nil? || name.empty?
    raise ArgumentError, "Description cannot be empty" if description.nil? || description.empty?
    raise ArgumentError, "Max attempts must be positive" if max_attempts <= 0

    @name = name
    @description = description
    @max_attempts = max_attempts
    @attempts_left = max_attempts
    @solved = false
    @reward = nil
  end

  def set_reward(reward)
    raise ArgumentError, "Reward cannot be nil" if reward.nil?

    @reward = reward
  end

  def solved?
    @solved
  end

  def failed?
    @attempts_left <= 0 && !@solved
  end

  def can_attempt?
    @attempts_left > 0 && !@solved
  end

  def attempt(answer)
    raise "Puzzle is already solved" if @solved
    raise "No attempts left" unless can_attempt?

    @attempts_left -= 1
    success = check_answer(answer)

    if success
      @solved = true
      {
        success: true,
        message: "Correct! #{@description}",
        reward: @reward
      }
    else
      {
        success: false,
        message: "Incorrect. Attempts remaining: #{@attempts_left}",
        reward: nil
      }
    end
  end

  def reset
    @attempts_left = @max_attempts
    @solved = false
  end

  def to_h
    {
      name: @name,
      description: @description,
      max_attempts: @max_attempts,
      attempts_left: @attempts_left,
      solved: @solved,
      reward: @reward.respond_to?(:to_h) ? @reward.to_h : (@reward ? { name: @reward.name } : nil)
    }
  end

  def self.from_h(data, items_lookup = {})
    puzzle_type = data[:type] || data['type'] || 'riddle'

    case puzzle_type
    when 'riddle'
      RiddlePuzzle.from_h(data, items_lookup)
    when 'code'
      CodePuzzle.from_h(data, items_lookup)
    when 'sequence'
      SequencePuzzle.from_h(data, items_lookup)
    else
      puzzle = new(
        data[:name] || data['name'],
        data[:description] || data['description'],
        max_attempts: data[:max_attempts] || data['max_attempts'] || 3
      )
      puzzle.instance_variable_set(:@attempts_left, data[:attempts_left] || data['attempts_left'])
      puzzle.instance_variable_set(:@solved, data[:solved] || data['solved'] || false)

      reward_data = data[:reward] || data['reward']
      if reward_data
        reward_name = reward_data.is_a?(Hash) ? (reward_data[:name] || reward_data['name']) : reward_data
        reward = items_lookup[reward_name]
        puzzle.set_reward(reward) if reward
      end

      puzzle
    end
  end

  protected

  def check_answer(answer)
    false
  end
end

class RiddlePuzzle < Puzzle
  def initialize(name, description, answer, max_attempts: 3)
    super(name, description, max_attempts: max_attempts)
    raise ArgumentError, "Answer cannot be empty" if answer.nil? || answer.empty?

    @answer = answer.downcase.strip
  end

  def self.from_h(data, items_lookup = {})
    puzzle = new(
      data[:name] || data['name'],
      data[:description] || data['description'],
      data[:answer] || data['answer'],
      max_attempts: data[:max_attempts] || data['max_attempts'] || 3
    )

    puzzle.instance_variable_set(:@attempts_left, data[:attempts_left] || data['attempts_left'])
    puzzle.instance_variable_set(:@solved, data[:solved] || data['solved'] || false)

    reward_data = data[:reward] || data['reward']
    if reward_data
      reward_name = reward_data.is_a?(Hash) ? (reward_data[:name] || reward_data['name']) : reward_data
      reward = items_lookup[reward_name]
      puzzle.set_reward(reward) if reward
    end

    puzzle
  end

  def to_h
    super.merge(answer: @answer, type: 'riddle')
  end

  protected

  def check_answer(answer)
    answer.downcase.strip == @answer
  end
end

class CodePuzzle < Puzzle
  def initialize(name, description, code, max_attempts: 3)
    super(name, description, max_attempts: max_attempts)
    raise ArgumentError, "Code cannot be empty" if code.nil? || code.empty?

    @code = code.to_s.strip
  end

  def self.from_h(data, items_lookup = {})
    puzzle = new(
      data[:name] || data['name'],
      data[:description] || data['description'],
      data[:code] || data['code'],
      max_attempts: data[:max_attempts] || data['max_attempts'] || 3
    )

    puzzle.instance_variable_set(:@attempts_left, data[:attempts_left] || data['attempts_left'])
    puzzle.instance_variable_set(:@solved, data[:solved] || data['solved'] || false)

    reward_data = data[:reward] || data['reward']
    if reward_data
      reward_name = reward_data.is_a?(Hash) ? (reward_data[:name] || reward_data['name']) : reward_data
      reward = items_lookup[reward_name]
      puzzle.set_reward(reward) if reward
    end

    puzzle
  end

  def to_h
    super.merge(code: @code, type: 'code')
  end

  protected

  def check_answer(answer)
    answer.to_s.strip == @code
  end
end

class SequencePuzzle < Puzzle
  def initialize(name, description, sequence, max_attempts: 3)
    super(name, description, max_attempts: max_attempts)
    raise ArgumentError, "Sequence cannot be empty" if sequence.nil? || sequence.empty?

    @sequence = sequence.map(&:to_s).map(&:strip)
  end

  def self.from_h(data, items_lookup = {})
    puzzle = new(
      data[:name] || data['name'],
      data[:description] || data['description'],
      data[:sequence] || data['sequence'],
      max_attempts: data[:max_attempts] || data['max_attempts'] || 3
    )

    puzzle.instance_variable_set(:@attempts_left, data[:attempts_left] || data['attempts_left'])
    puzzle.instance_variable_set(:@solved, data[:solved] || data['solved'] || false)

    reward_data = data[:reward] || data['reward']
    if reward_data
      reward_name = reward_data.is_a?(Hash) ? (reward_data[:name] || reward_data['name']) : reward_data
      reward = items_lookup[reward_name]
      puzzle.set_reward(reward) if reward
    end

    puzzle
  end

  def to_h
    super.merge(sequence: @sequence, type: 'sequence')
  end

  protected

  def check_answer(answer)
    user_sequence = answer.to_s.split(',').map(&:strip)
    user_sequence == @sequence
  end
end
