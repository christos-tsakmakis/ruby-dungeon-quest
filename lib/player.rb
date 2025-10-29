class Player
  attr_accessor :name, :health, :max_health, :attack_power, :defense, :dodge_chance, :block_chance, :crit_chance, :crit_multiplier
  attr_reader :inventory, :current_room, :equipped_weapon, :equipped_armor

  def initialize(name)
    @name = name
    @health = 100
    @max_health = 100
    @attack_power = 10
    @defense = 5
    @dodge_chance = 0.15
    @block_chance = 0.10
    @crit_chance = 0.20
    @crit_multiplier = 2.0
    @inventory = []
    @current_room = nil
    @equipped_weapon = nil
    @equipped_armor = nil
  end

  def add_item(item)
    raise ArgumentError, "Item cannot be nil" if item.nil?

    @inventory << item
    # No longer auto-equip - use equip command instead
  end

  def remove_item(item)
    return false unless @inventory.include?(item)

    @inventory.delete_at(@inventory.index(item))
    # Note: This doesn't unequip the item, use unequip for that
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

  def equip(item_name)
    item = get_item(item_name)
    return "You don't have that item" unless item
    return "That item cannot be equipped" unless item.respond_to?(:equippable?) && item.equippable?

    if item.respond_to?(:attack_bonus)
      # It's a weapon
      unequip_weapon if @equipped_weapon
      @equipped_weapon = item
      remove_item(item)
      apply_item_effects(item)
      "Equipped #{item.name}"
    elsif item.respond_to?(:defense_bonus)
      # It's armor
      unequip_armor if @equipped_armor
      @equipped_armor = item
      remove_item(item)
      apply_item_effects(item)
      "Equipped #{item.name}"
    else
      "Cannot equip #{item.name}"
    end
  end

  def unequip_weapon
    return "No weapon equipped" unless @equipped_weapon

    item = @equipped_weapon
    remove_item_effects(item)
    @equipped_weapon = nil
    add_item(item)
    "Unequipped #{item.name}"
  end

  def unequip_armor
    return "No armor equipped" unless @equipped_armor

    item = @equipped_armor
    remove_item_effects(item)
    @equipped_armor = nil
    add_item(item)
    "Unequipped #{item.name}"
  end

  def unequip(item_name)
    # Check if it's the equipped weapon
    if @equipped_weapon && @equipped_weapon.name.downcase == item_name.downcase
      return unequip_weapon
    end

    # Check if it's the equipped armor
    if @equipped_armor && @equipped_armor.name.downcase == item_name.downcase
      return unequip_armor
    end

    "That item is not equipped"
  end

  def take_damage(damage)
    # Check for dodge (complete avoidance)
    if rand < @dodge_chance
      return { damage: 0, dodged: true, blocked: false }
    end

    # Check for block (50% damage reduction)
    if rand < @block_chance
      damage = (damage * 0.5).to_i
      blocked = true
    else
      blocked = false
    end

    # Apply defense reduction
    actual_damage = [damage - @defense, 0].max
    @health -= actual_damage
    @health = [@health, 0].max

    { damage: actual_damage, dodged: false, blocked: blocked }
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

    # Group items by name and count them
    item_counts = Hash.new(0)
    item_details = {}
    @inventory.each do |item|
      item_counts[item.name] += 1
      item_details[item.name] = item.description
    end

    # Build inventory display
    item_counts.map.with_index { |(name, count), i|
      count_str = count > 1 ? " (x#{count})" : ""
      "#{i + 1}. #{name}#{count_str} - #{item_details[name]}"
    }.join("\n")
  end

  def stats
    weapon_name = @equipped_weapon ? @equipped_weapon.name : "None"
    armor_name = @equipped_armor ? @equipped_armor.name : "None"

    <<~STATS
      Name: #{@name}
      Health: #{@health}/#{@max_health}
      Attack Power: #{@attack_power}
      Defense: #{@defense}
      Dodge Chance: #{(@dodge_chance * 100).round}%
      Block Chance: #{(@block_chance * 100).round}%
      Crit Chance: #{(@crit_chance * 100).round}%
      Crit Multiplier: #{@crit_multiplier}x
      Weapon: #{weapon_name}
      Armor: #{armor_name}
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
      dodge_chance: @dodge_chance,
      block_chance: @block_chance,
      crit_chance: @crit_chance,
      crit_multiplier: @crit_multiplier,
      inventory: @inventory.map { |item| item.respond_to?(:to_h) ? item.to_h : item.name },
      equipped_weapon: @equipped_weapon&.to_h,
      equipped_armor: @equipped_armor&.to_h
    }
  end

  def self.from_h(data, items_lookup = {})
    player = new(data[:name] || data['name'])
    player.health = data[:health] || data['health']
    player.max_health = data[:max_health] || data['max_health']
    player.attack_power = data[:attack_power] || data['attack_power']
    player.defense = data[:defense] || data['defense']
    player.dodge_chance = data[:dodge_chance] || data['dodge_chance'] || 0.15
    player.block_chance = data[:block_chance] || data['block_chance'] || 0.15
    player.crit_chance = data[:crit_chance] || data['crit_chance'] || 0.20
    player.crit_multiplier = data[:crit_multiplier] || data['crit_multiplier'] || 2.0

    inventory_data = data[:inventory] || data['inventory'] || []
    inventory_data.each do |item_data|
      if item_data.is_a?(Hash)
        item = items_lookup[item_data[:name] || item_data['name']]
        player.add_item(item) if item
      end
    end

    # Restore equipped items
    if data[:equipped_weapon] || data['equipped_weapon']
      weapon_data = data[:equipped_weapon] || data['equipped_weapon']
      weapon = items_lookup[weapon_data[:name] || weapon_data['name']]
      player.instance_variable_set(:@equipped_weapon, weapon)
      player.send(:apply_item_effects, weapon) if weapon
    end

    if data[:equipped_armor] || data['equipped_armor']
      armor_data = data[:equipped_armor] || data['equipped_armor']
      armor = items_lookup[armor_data[:name] || armor_data['name']]
      player.instance_variable_set(:@equipped_armor, armor)
      player.send(:apply_item_effects, armor) if armor
    end

    player
  end

  private

  def apply_item_effects(item)
    @attack_power += item.attack_bonus if item.respond_to?(:attack_bonus)
    @defense += item.defense_bonus if item.respond_to?(:defense_bonus)
    @max_health += item.health_bonus if item.respond_to?(:health_bonus)
    @dodge_chance += item.dodge_bonus if item.respond_to?(:dodge_bonus)
    @block_chance += item.block_bonus if item.respond_to?(:block_bonus)
    @crit_chance += item.crit_bonus if item.respond_to?(:crit_bonus)
  end

  def remove_item_effects(item)
    @attack_power -= item.attack_bonus if item.respond_to?(:attack_bonus)
    @defense -= item.defense_bonus if item.respond_to?(:defense_bonus)
    @max_health -= item.health_bonus if item.respond_to?(:health_bonus)
    @dodge_chance -= item.dodge_bonus if item.respond_to?(:dodge_bonus)
    @block_chance -= item.block_bonus if item.respond_to?(:block_bonus)
    @crit_chance -= item.crit_bonus if item.respond_to?(:crit_bonus)
    @health = [@health, @max_health].min
  end
end
