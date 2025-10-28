class Room
  attr_reader :name, :description, :items, :enemies, :puzzle
  attr_accessor :visited

  def initialize(name, description)
    raise ArgumentError, "Name cannot be empty" if name.nil? || name.empty?
    raise ArgumentError, "Description cannot be empty" if description.nil? || description.empty?

    @name = name
    @description = description
    @connections = {}
    @items = []
    @enemies = []
    @puzzle = nil
    @visited = false
    @locked = false
    @required_key = nil
  end

  def connect(direction, room, bidirectional: false)
    raise ArgumentError, "Direction cannot be nil" if direction.nil?
    raise ArgumentError, "Room cannot be nil" if room.nil?
    raise ArgumentError, "Cannot connect room to itself" if room == self

    @connections[direction.to_sym] = room
    room.connect(opposite_direction(direction), self) if bidirectional
  end

  def connected?(direction)
    @connections.key?(direction.to_sym)
  end

  def get_connected_room(direction)
    @connections[direction.to_sym]
  end

  def available_exits
    @connections.keys
  end

  def exits_description
    return "No exits available" if @connections.empty?

    "Available exits: #{@connections.keys.join(', ')}"
  end

  def add_item(item)
    raise ArgumentError, "Item cannot be nil" if item.nil?

    @items << item
  end

  def remove_item(item)
    @items.delete(item)
  end

  def has_item?(item_name)
    @items.any? { |item| item.name.downcase == item_name.downcase }
  end

  def get_item(item_name)
    @items.find { |item| item.name.downcase == item_name.downcase }
  end

  def items_description
    return "No items here" if @items.empty?

    "You see: #{@items.map(&:name).join(', ')}"
  end

  def add_enemy(enemy)
    raise ArgumentError, "Enemy cannot be nil" if enemy.nil?

    @enemies << enemy
  end

  def remove_enemy(enemy)
    @enemies.delete(enemy)
  end

  def has_enemies?
    @enemies.any? { |enemy| enemy.alive? }
  end

  def alive_enemies
    @enemies.select(&:alive?)
  end

  def enemies_description
    return "" unless has_enemies?

    "Enemies: #{alive_enemies.map(&:name).join(', ')}"
  end

  def set_puzzle(puzzle)
    raise ArgumentError, "Puzzle cannot be nil" if puzzle.nil?

    @puzzle = puzzle
  end

  def has_puzzle?
    !@puzzle.nil? && !@puzzle.solved?
  end

  def lock(required_key = nil)
    @locked = true
    @required_key = required_key
  end

  def unlock
    @locked = false
  end

  def locked?
    @locked
  end

  def can_enter?(player)
    return true unless @locked
    return true if @required_key.nil?

    player.has_item?(@required_key)
  end

  def full_description
    parts = [@description]
    parts << items_description unless @items.empty?
    parts << enemies_description if has_enemies?
    parts << "There is a puzzle here" if has_puzzle?
    parts << exits_description
    parts.join("\n")
  end

  def mark_visited
    @visited = true
  end

  def to_h
    {
      name: @name,
      description: @description,
      visited: @visited,
      locked: @locked,
      required_key: @required_key,
      items: @items.map { |item| item.respond_to?(:to_h) ? item.to_h : { name: item.name } },
      puzzle: @puzzle.respond_to?(:to_h) ? @puzzle.to_h : nil
    }
  end

  def self.from_h(data, items_lookup = {}, puzzles_lookup = {})
    room = new(data[:name] || data['name'], data[:description] || data['description'])
    room.visited = data[:visited] || data['visited'] || false

    if data[:locked] || data['locked']
      room.lock(data[:required_key] || data['required_key'])
    end

    items_data = data[:items] || data['items'] || []
    items_data.each do |item_data|
      item_name = item_data.is_a?(Hash) ? (item_data[:name] || item_data['name']) : item_data
      item = items_lookup[item_name]
      room.add_item(item) if item
    end

    puzzle_data = data[:puzzle] || data['puzzle']
    if puzzle_data
      puzzle_name = puzzle_data.is_a?(Hash) ? (puzzle_data[:name] || puzzle_data['name']) : puzzle_data
      puzzle = puzzles_lookup[puzzle_name]
      room.set_puzzle(puzzle) if puzzle
    end

    room
  end

  private

  def opposite_direction(direction)
    opposites = {
      north: :south,
      south: :north,
      east: :west,
      west: :east,
      up: :down,
      down: :up
    }
    opposites[direction.to_sym]
  end
end
