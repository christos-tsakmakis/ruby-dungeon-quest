class Enemy
  attr_reader :name, :description, :health, :max_health, :attack_power, :defense
  attr_accessor :loot

  def initialize(name, description, health, attack_power, defense = 0)
    raise ArgumentError, "Name cannot be empty" if name.nil? || name.empty?
    raise ArgumentError, "Health must be positive" if health <= 0
    raise ArgumentError, "Attack power must be non-negative" if attack_power < 0
    raise ArgumentError, "Defense must be non-negative" if defense < 0

    @name = name
    @description = description
    @health = health
    @max_health = health
    @attack_power = attack_power
    @defense = defense
    @loot = []
  end

  def attack(target)
    raise ArgumentError, "Target cannot be nil" if target.nil?
    raise "Enemy is dead and cannot attack" if dead?

    damage = calculate_damage(target)
    actual_damage = target.take_damage(damage)

    {
      attacker: @name,
      target: target.name,
      damage: actual_damage,
      target_health: target.health
    }
  end

  def take_damage(damage)
    raise ArgumentError, "Damage cannot be negative" if damage < 0

    actual_damage = [damage - @defense, 0].max
    @health -= actual_damage
    @health = [@health, 0].max
    actual_damage
  end

  def alive?
    @health > 0
  end

  def dead?
    !alive?
  end

  def add_loot(item)
    raise ArgumentError, "Item cannot be nil" if item.nil?

    @loot << item
  end

  def drop_loot
    dropped = @loot.dup
    @loot.clear
    dropped
  end

  def stats
    <<~STATS
      Name: #{@name}
      Description: #{@description}
      Health: #{@health}/#{@max_health}
      Attack Power: #{@attack_power}
      Defense: #{@defense}
      Status: #{alive? ? "Alive" : "Dead"}
    STATS
  end

  def to_h
    {
      name: @name,
      description: @description,
      health: @health,
      max_health: @max_health,
      attack_power: @attack_power,
      defense: @defense,
      loot: @loot.map { |item| item.respond_to?(:to_h) ? item.to_h : { name: item.name } }
    }
  end

  def self.from_h(data, items_lookup = {})
    enemy = new(
      data[:name] || data['name'],
      data[:description] || data['description'],
      data[:max_health] || data['max_health'],
      data[:attack_power] || data['attack_power'],
      data[:defense] || data['defense'] || 0
    )

    enemy.instance_variable_set(:@health, data[:health] || data['health'])

    loot_data = data[:loot] || data['loot'] || []
    loot_data.each do |item_data|
      item_name = item_data.is_a?(Hash) ? (item_data[:name] || item_data['name']) : item_data
      item = items_lookup[item_name]
      enemy.add_loot(item) if item
    end

    enemy
  end

  private

  def calculate_damage(target)
    base_damage = @attack_power
    variance = rand(-2..2)
    [base_damage + variance, 1].max
  end
end

class Boss < Enemy
  attr_reader :special_ability_name, :special_ability_cooldown

  def initialize(name, description, health, attack_power, defense, special_ability_name)
    super(name, description, health, attack_power, defense)
    @special_ability_name = special_ability_name
    @special_ability_cooldown = 0
    @max_cooldown = 3
  end

  def attack(target)
    if @special_ability_cooldown == 0 && rand < 0.3
      use_special_ability(target)
    else
      @special_ability_cooldown = [@special_ability_cooldown - 1, 0].max
      super(target)
    end
  end

  def use_special_ability(target)
    raise ArgumentError, "Target cannot be nil" if target.nil?
    raise "Boss is dead and cannot use special ability" if dead?

    damage = (@attack_power * 1.5).to_i
    actual_damage = target.take_damage(damage)
    @special_ability_cooldown = @max_cooldown

    {
      attacker: @name,
      target: target.name,
      damage: actual_damage,
      target_health: target.health,
      special: @special_ability_name
    }
  end

  def to_h
    super.merge(
      special_ability_name: @special_ability_name,
      special_ability_cooldown: @special_ability_cooldown
    )
  end
end
