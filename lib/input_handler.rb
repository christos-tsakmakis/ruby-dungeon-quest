class InputHandler
  COMMANDS = {
    move: %w[go move walk travel north south east west up down n s e w],
    look: %w[look examine inspect],
    inventory: %w[inventory inv i items],
    take: %w[take get pickup grab],
    drop: %w[drop leave discard],
    use: %w[use consume drink eat],
    equip: %w[equip wield wear],
    unequip: %w[unequip unwield remove],
    attack: %w[attack fight hit strike],
    flee: %w[flee run escape retreat],
    unlock: %w[unlock open],
    solve: %w[solve answer attempt],
    stats: %w[stats status health],
    help: %w[help commands h ?],
    save: %w[save],
    load: %w[load],
    quit: %w[quit exit q]
  }.freeze

  def initialize
    @command_map = build_command_map
  end

  def parse(input)
    raise ArgumentError, "Input cannot be nil" if input.nil?

    cleaned_input = input.strip.downcase
    return { action: :empty, args: [] } if cleaned_input.empty?

    words = cleaned_input.split(/\s+/)
    command_word = words.first
    args = words[1..]

    action = @command_map[command_word]

    if action
      { action: action, args: args, raw: cleaned_input }
    else
      { action: :unknown, args: words, raw: cleaned_input }
    end
  end

  def parse_direction(direction_str)
    direction_map = {
      'north' => :north, 'n' => :north,
      'south' => :south, 's' => :south,
      'east' => :east, 'e' => :east,
      'west' => :west, 'w' => :west,
      'up' => :up, 'u' => :up,
      'down' => :down, 'd' => :down
    }

    direction_map[direction_str.downcase]
  end

  def help_text
    <<~HELP
      Available Commands:

      Movement:
        go/move <direction> - Move in a direction (north, south, east, west, up, down)
        Shortcuts: n, s, e, w, u, d

      Interaction:
        look/examine - Look around the current room
        take/get <item> - Pick up an item
        drop <item> - Drop an item from inventory
        use <item> - Use or consume an item
        attack/fight <enemy> - Attack an enemy

      Information:
        inventory/inv/i - View your inventory
        stats/status - View your character stats
        help - Show this help message

      Game:
        save <filename> - Save your game
        load <filename> - Load a saved game
        quit/exit - Quit the game
    HELP
  end

  def valid_command?(input)
    parsed = parse(input)
    parsed[:action] != :unknown && parsed[:action] != :empty
  end

  def suggest_commands(input)
    return [] if input.nil? || input.empty?

    cleaned = input.strip.downcase
    suggestions = @command_map.keys.select { |cmd| cmd.start_with?(cleaned) }
    suggestions.take(5)
  end

  private

  def build_command_map
    map = {}
    COMMANDS.each do |action, aliases|
      aliases.each do |cmd|
        map[cmd] = action
      end
    end
    map
  end
end
