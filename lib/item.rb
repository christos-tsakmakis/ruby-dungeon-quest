class Item
  attr_reader :name, :description, :type

  def initialize(name, description, type = :misc)
    raise ArgumentError, "Name cannot be empty" if name.nil? || name.empty?
    raise ArgumentError, "Description cannot be empty" if description.nil? || description.empty?

    @name = name
    @description = description
    @type = type
  end

  def usable?
    false
  end

  def equippable?
    false
  end

  def consumable?
    false
  end

  def to_h
    {
      name: @name,
      description: @description,
      type: @type
    }
  end

  def self.from_h(data)
    type = (data[:type] || data['type']).to_sym
    name = data[:name] || data['name']
    description = data[:description] || data['description']

    case type
    when :weapon
      Weapon.new(
        name,
        description,
        data[:attack_bonus] || data['attack_bonus'] || 0,
        data[:crit_bonus] || data['crit_bonus'] || 0
      )
    when :armor
      Armor.new(
        name,
        description,
        data[:defense_bonus] || data['defense_bonus'] || 0,
        data[:dodge_bonus] || data['dodge_bonus'] || 0,
        data[:block_bonus] || data['block_bonus'] || 0
      )
    when :potion
      Potion.new(
        name,
        description,
        data[:heal_amount] || data['heal_amount'] || 0
      )
    when :key
      Key.new(name, description)
    else
      new(name, description, type)
    end
  end
end

class Weapon < Item
  attr_reader :attack_bonus, :crit_bonus

  def initialize(name, description, attack_bonus, crit_bonus = 0)
    super(name, description, :weapon)
    raise ArgumentError, "Attack bonus must be non-negative" if attack_bonus < 0
    raise ArgumentError, "Crit bonus must be non-negative" if crit_bonus < 0

    @attack_bonus = attack_bonus
    @crit_bonus = crit_bonus
  end

  def equippable?
    true
  end

  def to_h
    super.merge(attack_bonus: @attack_bonus, crit_bonus: @crit_bonus)
  end
end

class Armor < Item
  attr_reader :defense_bonus, :dodge_bonus, :block_bonus

  def initialize(name, description, defense_bonus, dodge_bonus = 0, block_bonus = 0)
    super(name, description, :armor)
    raise ArgumentError, "Defense bonus must be non-negative" if defense_bonus < 0
    raise ArgumentError, "Dodge bonus must be non-negative" if dodge_bonus < 0
    raise ArgumentError, "Block bonus must be non-negative" if block_bonus < 0

    @defense_bonus = defense_bonus
    @dodge_bonus = dodge_bonus
    @block_bonus = block_bonus
  end

  def equippable?
    true
  end

  def to_h
    super.merge(defense_bonus: @defense_bonus, dodge_bonus: @dodge_bonus, block_bonus: @block_bonus)
  end
end

class Potion < Item
  attr_reader :heal_amount

  def initialize(name, description, heal_amount)
    super(name, description, :potion)
    raise ArgumentError, "Heal amount must be positive" if heal_amount <= 0

    @heal_amount = heal_amount
  end

  def usable?
    true
  end

  def consumable?
    true
  end

  def use(player)
    actual_heal = player.heal(@heal_amount)
    "Healed #{actual_heal} HP"
  end

  def to_h
    super.merge(heal_amount: @heal_amount)
  end
end

class Key < Item
  def initialize(name, description)
    super(name, description, :key)
  end

  def usable?
    false
  end
end
