# frozen_string_literal: true

# NPC (Non-Player Character) class for dialogue and interactions
class NPC
  attr_reader :name, :description, :state, :talked_count

  def initialize(name, description, dialogue)
    raise ArgumentError, "Name cannot be nil" if name.nil?
    raise ArgumentError, "Name cannot be empty" if name.empty?
    raise ArgumentError, "Description cannot be nil" if description.nil?
    raise ArgumentError, "Description cannot be empty" if description.empty?
    raise ArgumentError, "Dialogue cannot be nil" if dialogue.nil?
    raise ArgumentError, "Dialogue cannot be empty" if dialogue.empty?

    @name = name
    @description = description
    @dialogue = dialogue
    @state = :not_talked
    @talked_count = 0
    @current_dialogue_index = 0
  end

  # Returns the next dialogue line and updates NPC state
  def talk
    dialogue_line = @dialogue[@current_dialogue_index]

    # Update state after first talk
    @state = :talked if @state == :not_talked

    # Increment talked count
    @talked_count += 1

    # Move to next dialogue (cycle back to start if at end)
    @current_dialogue_index = (@current_dialogue_index + 1) % @dialogue.length

    dialogue_line
  end

  # Serializes NPC to a hash for saving
  def to_h
    {
      name: @name,
      description: @description,
      dialogue: @dialogue,
      state: @state,
      talked_count: @talked_count,
      current_dialogue_index: @current_dialogue_index
    }
  end

  # Deserializes NPC from a hash
  def self.from_h(data)
    # Handle both symbol and string keys
    name = data[:name] || data['name']
    description = data[:description] || data['description']
    dialogue = data[:dialogue] || data['dialogue']
    state = data[:state] || data['state']
    talked_count = data[:talked_count] || data['talked_count'] || 0
    current_dialogue_index = data[:current_dialogue_index] || data['current_dialogue_index'] || 0

    # Convert state to symbol if it's a string
    state = state.to_sym if state.is_a?(String)

    npc = new(name, description, dialogue)
    npc.instance_variable_set(:@state, state)
    npc.instance_variable_set(:@talked_count, talked_count)
    npc.instance_variable_set(:@current_dialogue_index, current_dialogue_index)
    npc
  end
end
