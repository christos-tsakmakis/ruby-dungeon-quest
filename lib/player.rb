class Player
  attr_accessor :name, :health, :max_health, :attack_power, :defense
  attr_reader :inventory, :current_room

  def initialize(name)
    @name = name
    @health = 100
    @max_health = 100
    @attack_power = 10
    @defense = 5
    @inventory = []
    @current_room = nil
  end

  def add_item(item)
    raise ArgumentError, "Item cannot be nil" if item.nil?

    @inventory << item
    apply_item_effects(item) if item.respond_to?(:equippable?) && item.equippable?
  end

  def remove_item(item)
    return false unless @inventory.include?(item)

    @inventory.delete(item)
    remove_item_effects(item) if item.respond_to?(:equippable?) && item.equippable?
    true
  end

  def has_item?(item_name)
    @inventory.any? { |item| item.name.downcase == item_name.downcase }
  end

  def get_item(item_name)
    @inventory.find { |item| item.name.downcase == item_name.downcase }
  end

  def use_item(item_name)
    item = get_item(item_name)
    return nil unless item
    return "Cannot use this item" unless item.respond_to?(:usable?) && item.usable?

    effect = item.use(self)
    remove_item(item) if item.consumable?
    effect
  end

  def take_damage(damage)
    actual_damage = [damage - @defense, 0].max
    @health -= actual_damage
    @health = [@health, 0].max
    actual_damage
  end

  def heal(amount)
    raise ArgumentError, "Heal amount must be positive" if amount < 0

    old_health = @health
    @health = [@health + amount, @max_health].min
    @health - old_health
  end

  def alive?
    @health > 0
  end

  def dead?
    !alive?
  end

  def move_to_room(room)
    raise ArgumentError, "Room cannot be nil" if room.nil?

    @current_room = room
  end

  def inventory_list
    return "Inventory is empty" if @inventory.empty?

    @inventory.map.with_index { |item, i| "#{i + 1}. #{item.name} - #{item.description}" }.join("\n")
  end

  def stats
    <<~STATS
      Name: #{@name}
      Health: #{@health}/#{@max_health}
      Attack Power: #{@attack_power}
      Defense: #{@defense}
      Items: #{@inventory.length}
    STATS
  end

  def to_h
    {
      name: @name,
      health: @health,
      max_health: @max_health,
      attack_power: @attack_power,
      defense: @defense,
      inventory: @inventory.map { |item| item.respond_to?(:to_h) ? item.to_h : item.name }
    }
  end

  def self.from_h(data, items_lookup = {})
    player = new(data[:name] || data['name'])
    player.health = data[:health] || data['health']
    player.max_health = data[:max_health] || data['max_health']
    player.attack_power = data[:attack_power] || data['attack_power']
    player.defense = data[:defense] || data['defense']

    inventory_data = data[:inventory] || data['inventory'] || []
    inventory_data.each do |item_data|
      if item_data.is_a?(Hash)
        item = items_lookup[item_data[:name] || item_data['name']]
        player.add_item(item) if item
      end
    end

    player
  end

  private

  def apply_item_effects(item)
    @attack_power += item.attack_bonus if item.respond_to?(:attack_bonus)
    @defense += item.defense_bonus if item.respond_to?(:defense_bonus)
    @max_health += item.health_bonus if item.respond_to?(:health_bonus)
  end

  def remove_item_effects(item)
    @attack_power -= item.attack_bonus if item.respond_to?(:attack_bonus)
    @defense -= item.defense_bonus if item.respond_to?(:defense_bonus)
    @max_health -= item.health_bonus if item.respond_to?(:health_bonus)
    @health = [@health, @max_health].min
  end
end
