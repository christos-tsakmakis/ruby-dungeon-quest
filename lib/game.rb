require_relative 'player'
require_relative 'room'
require_relative 'item'
require_relative 'enemy'
require_relative 'puzzle'
require_relative 'save_manager'
require_relative 'input_handler'
require_relative 'narrator'

class Game
  attr_reader :player, :current_room, :rooms, :game_over, :narrator

  def initialize
    @player = nil
    @rooms = {}
    @current_room = nil
    @input_handler = InputHandler.new
    @save_manager = SaveManager.new
    @narrator = Narrator.new
    @game_over = false
    @win_condition_met = false
  end

  def start
    display_welcome
    display_help
    setup_player
    display_prologue
    initialize_world
    game_loop
    display_goodbye
  end

  def setup_player
    print "Enter your character's name: "
    input = gets
    return if input.nil?  # Handle EOF/Ctrl+D
    name = input.chomp
    name = "Adventurer" if name.empty?
    @player = Player.new(name)
    puts "\nWelcome, #{@player.name}! Your adventure begins...\n\n"
  end

  def initialize_world
    create_rooms
    create_items
    create_enemies
    create_puzzles
    connect_rooms
    place_items_in_rooms
    place_enemies_in_rooms
    place_puzzles_in_rooms
    lock_rooms

    @current_room = @rooms[:entrance]
    @player.move_to_room(@current_room)
    @current_room.mark_visited
  end

  def game_loop
    until @game_over
      print "\n> "
      input = gets
      break if input.nil?  # Handle EOF/Ctrl+D
      process_command(input.chomp)
      check_game_state
    end
  end

  def process_command(input)
    parsed = @input_handler.parse(input)

    case parsed[:action]
    when :move
      handle_move(parsed[:args])
    when :look
      handle_look(parsed[:args])
    when :inventory
      display_inventory
    when :take
      handle_take(parsed[:args])
    when :drop
      handle_drop(parsed[:args])
    when :use
      handle_use(parsed[:args])
    when :equip
      handle_equip(parsed[:args])
    when :unequip
      handle_unequip(parsed[:args])
    when :attack
      handle_attack(parsed[:args])
    when :flee
      handle_flee
    when :unlock
      handle_unlock(parsed[:args])
    when :solve
      handle_solve(parsed[:args])
    when :stats
      display_stats
    when :narrator
      handle_narrator(parsed[:args])
    when :help
      display_help
    when :save
      handle_save(parsed[:args])
    when :load
      handle_load(parsed[:args])
    when :quit
      handle_quit
    when :empty
      # Do nothing for empty input
    when :unknown
      puts "Unknown command. Type 'help' for available commands."
    end
  end

  def handle_move(args)
    if args.empty?
      puts "Move where? (north, south, east, west, up, down)"
      return
    end

    direction = @input_handler.parse_direction(args.first)
    unless direction
      puts "Invalid direction. Use: north, south, east, west, up, or down"
      return
    end

    unless @current_room.connected?(direction)
      puts "You cannot go that way."
      return
    end

    next_room = @current_room.get_connected_room(direction)

    unless next_room.can_enter?(@player)
      puts "The way is locked. You need a #{next_room.instance_variable_get(:@required_key)} to enter."
      return
    end

    if @current_room.has_enemies?
      puts "You cannot leave while enemies are still alive!"
      return
    end

    @current_room = next_room
    @player.move_to_room(@current_room)
    @current_room.mark_visited

    # Narrator commentary
    commentary = @narrator.narrate(:move, direction: direction.to_s)
    puts commentary if commentary

    display_room(force: true)
  end

  def handle_look(args)
    # If no arguments, show the room
    if args.empty?
      # Narrator commentary for looking
      commentary = @narrator.narrate(:look)
      puts commentary if commentary

      display_room(force: true)
      return
    end

    # Try to find and examine an item
    item_name = args.join(' ')

    # Check player inventory first
    item = @player.get_item(item_name)

    # If not in inventory, check room
    item ||= @current_room.get_item(item_name)

    if item
      puts "\n==== #{item.name} ===="
      puts item.description

      # Show additional info for equipment
      if item.is_a?(Weapon)
        puts "Attack Bonus: +#{item.attack_bonus}"
        puts "Crit Bonus: +#{(item.crit_bonus * 100).round}%" if item.crit_bonus > 0
      elsif item.is_a?(Armor)
        puts "Defense Bonus: +#{item.defense_bonus}"
        puts "Dodge Bonus: +#{(item.dodge_bonus * 100).round}%" if item.dodge_bonus > 0
        puts "Block Bonus: +#{(item.block_bonus * 100).round}%" if item.block_bonus > 0
      elsif item.is_a?(Potion)
        puts "Healing: #{item.heal_amount} HP"
      end
      puts "=" * (item.name.length + 10)
    else
      puts "You don't see '#{item_name}' here."
    end
  end

  def handle_take(args)
    if args.empty?
      puts "Take what?"
      return
    end

    item_name = args.join(' ')
    item = @current_room.get_item(item_name)

    unless item
      puts "There is no '#{item_name}' here."
      return
    end

    @current_room.remove_item(item)
    @player.add_item(item)

    # Narrator commentary
    commentary = @narrator.narrate(:take, item: item.name)
    puts commentary if commentary

    puts "You picked up #{item.name}."
  end

  def handle_drop(args)
    if args.empty?
      puts "Drop what?"
      return
    end

    item_name = args.join(' ')
    item = @player.get_item(item_name)

    unless item
      puts "You don't have '#{item_name}'."
      return
    end

    @player.remove_item(item)
    @current_room.add_item(item)

    # Narrator commentary
    commentary = @narrator.narrate(:drop, item: item.name)
    puts commentary if commentary

    puts "You dropped #{item.name}."
  end

  def handle_use(args)
    if args.empty?
      puts "Use what?"
      return
    end

    item_name = args.join(' ')

    # Narrator commentary (before use)
    commentary = @narrator.narrate(:use, item: item_name)
    puts commentary if commentary

    result = @player.use_item(item_name)

    if result.nil?
      puts "You don't have '#{item_name}'."
    elsif result.is_a?(String)
      puts result
    end
  end

  def handle_equip(args)
    if args.empty?
      puts "Equip what?"
      return
    end

    item_name = args.join(' ')

    # Narrator commentary (before equip)
    commentary = @narrator.narrate(:equip, item: item_name)
    puts commentary if commentary

    result = @player.equip(item_name)
    puts result
  end

  def handle_unequip(args)
    if args.empty?
      puts "Unequip what?"
      return
    end

    item_name = args.join(' ')

    # Narrator commentary (before unequip)
    commentary = @narrator.narrate(:unequip, item: item_name)
    puts commentary if commentary

    result = @player.unequip(item_name)
    puts result
  end

  def handle_attack(args)
    unless @current_room.has_enemies?
      puts "There are no enemies to attack here."
      return
    end

    enemies = @current_room.alive_enemies
    target = enemies.first

    if args.any?
      enemy_name = args.join(' ')
      target = enemies.find { |e| e.name.downcase.include?(enemy_name) }
      unless target
        puts "No enemy named '#{enemy_name}' here."
        return
      end
    end

    combat_round(target)
  end

  def combat_round(enemy)
    puts "\n--- Combat Round ---"

    # Narrator commentary for attack
    commentary = @narrator.narrate(:attack, enemy: enemy.name)
    puts commentary if commentary

    # Player attack with critical hit chance
    player_damage = @player.attack_power + rand(-2..2)
    is_crit = rand < @player.crit_chance
    player_damage = (player_damage * @player.crit_multiplier).to_i if is_crit
    player_damage = [player_damage, 1].max
    enemy_damage_result = enemy.take_damage(player_damage)

    # Display player attack result with additional narrator commentary
    if enemy_damage_result[:dodged]
      # Narrator for enemy dodge
      dodge_commentary = @narrator.narrate(:dodge, enemy: enemy.name)
      puts dodge_commentary if dodge_commentary
      puts "You attack #{enemy.name} but it DODGES!"
    elsif enemy_damage_result[:blocked]
      # Narrator for enemy block
      block_commentary = @narrator.narrate(:block, enemy: enemy.name)
      puts block_commentary if block_commentary
      puts "You attack #{enemy.name} for #{enemy_damage_result[:damage]} damage! [BLOCKED]"
    else
      # Narrator for critical hit
      if is_crit
        crit_commentary = @narrator.narrate(:critical_hit, enemy: enemy.name)
        puts crit_commentary if crit_commentary
      end
      crit_msg = is_crit ? " CRITICAL HIT!" : ""
      puts "You attack #{enemy.name} for #{enemy_damage_result[:damage]} damage!#{crit_msg}"
    end

    if enemy.dead?
      puts "#{enemy.name} has been defeated!"
      handle_enemy_death(enemy)
      return
    end

    # Enemy attack
    enemy_attack = enemy.attack(@player)

    # Display enemy attack result
    if enemy_attack[:dodged]
      puts "#{enemy.name} attacks but you DODGE!"
    elsif enemy_attack[:blocked]
      puts "#{enemy.name} attacks you for #{enemy_attack[:damage]} damage! [BLOCKED]"
    else
      crit_msg = enemy_attack[:critical] ? " CRITICAL HIT!" : ""
      puts "#{enemy.name} attacks you for #{enemy_attack[:damage]} damage!#{crit_msg}"
    end

    if @player.dead?
      puts "You have been defeated!"
      @game_over = true
    end
  end

  def handle_enemy_death(enemy)
    @current_room.remove_enemy(enemy)
    loot = enemy.drop_loot

    unless loot.empty?
      puts "#{enemy.name} dropped: #{loot.map(&:name).join(', ')}"
      loot.each { |item| @current_room.add_item(item) }
    end

    check_win_condition
  end

  def handle_flee
    unless @current_room.has_enemies?
      puts "There are no enemies to flee from."
      return
    end

    # Narrator commentary for fleeing
    commentary = @narrator.narrate(:flee)
    puts commentary if commentary

    # 50% chance to escape
    if rand < 0.5
      # Find connected rooms
      available_exits = @current_room.connections.keys
      if available_exits.empty?
        puts "You failed to flee! There's nowhere to run!"
        return
      end

      # Pick random exit
      exit_direction = available_exits.sample
      target_room = @current_room.get_connected_room(exit_direction)

      @player.move_to_room(target_room)
      @current_room = target_room
      puts "You successfully fled to the #{@current_room.name}!"
      display_room(force: true)
    else
      puts "You failed to escape!"
      # Enemy gets a free attack
      enemy = @current_room.alive_enemies.first
      if enemy
        enemy_attack = enemy.attack(@player)
        puts "#{enemy.name} attacks you as you try to flee for #{enemy_attack[:damage]} damage!"

        if @player.dead?
          puts "You have been defeated!"
          @game_over = true
        end
      end
    end
  end

  def handle_unlock(args)
    if args.empty?
      puts "Unlock which direction?"
      return
    end

    direction = @input_handler.parse_direction(args.first)
    unless direction
      puts "Invalid direction."
      return
    end

    target_room = @current_room.get_connected_room(direction)
    unless target_room
      puts "There is no exit in that direction."
      return
    end

    unless target_room.locked?
      puts "That room is not locked."
      return
    end

    if target_room.required_key.nil?
      # Room is locked but doesn't need a key, just unlock it
      target_room.unlock

      # Narrator commentary for unlock
      commentary = @narrator.narrate(:unlock, direction: direction.to_s)
      puts commentary if commentary

      puts "You unlocked the door!"
    else
      # Check if player has the required key
      if @player.has_item?(target_room.required_key)
        target_room.unlock

        # Narrator commentary for unlock
        commentary = @narrator.narrate(:unlock, direction: direction.to_s)
        puts commentary if commentary

        puts "You used the #{target_room.required_key} to unlock the door!"
      else
        puts "You need a #{target_room.required_key} to unlock this door."
      end
    end
  end

  def handle_solve(args)
    # If no puzzle in room
    if @current_room.puzzles.empty?
      puts "There are no puzzles here."
      return
    end

    # If no args, check if there's only one puzzle
    if args.empty?
      if @current_room.puzzles.length == 1
        puzzle = @current_room.puzzles.first
        puts "\n#{puzzle.description}"
        puts "\nType 'solve <answer>' to attempt the puzzle."
      else
        puts "There are multiple puzzles here. Specify which one: #{@current_room.puzzles.map(&:name).join(', ')}"
      end
      return
    end

    # First word might be puzzle name or answer (if only 1 puzzle)
    if @current_room.puzzles.length == 1 && args.length >= 1
      puzzle = @current_room.puzzles.first

      # Check if first arg looks like a puzzle name reference (not a real answer)
      first_word = args.first.downcase
      if first_word == "puzzle" || puzzle.name.downcase.include?(first_word)
        # Looks like they're trying to reference the puzzle, show description
        puts "\n#{puzzle.description}"
        puts "\nType 'solve <answer>' to attempt the puzzle."
        return
      end

      # Single puzzle room - treat all args as the answer
      answer = args.join(' ')
    else
      # Multiple puzzles - first arg is puzzle name, rest is answer
      puzzle_name = args.first
      answer = args[1..].join(' ')

      puzzle = @current_room.puzzles.find { |p| p.name.downcase.include?(puzzle_name.downcase) }
      unless puzzle
        puts "There is no puzzle called '#{puzzle_name}' here."
        return
      end

      # If no answer provided, show the puzzle
      if answer.empty?
        puts "\n#{puzzle.description}"
        puts "\nType 'solve #{puzzle_name} <answer>' to attempt the puzzle."
        return
      end
    end

    # Narrator commentary for solve attempt
    commentary = @narrator.narrate(:solve, puzzle: puzzle.name)
    puts commentary if commentary

    # Attempt to solve
    result = puzzle.attempt(answer)

    if result[:success]
      puts "Correct! You solved the puzzle!"
      if result[:reward]
        @current_room.add_item(result[:reward])
        puts "You received: #{result[:reward].name}!"
      end
    else
      puts "Incorrect! #{puzzle.attempts_left} attempts remaining."
    end
  rescue RuntimeError => e
    puts e.message
  end

  def handle_save(args)
    filename = args.empty? ? "quicksave" : args.join('_')

    game_state = {
      player: @player.to_h,
      current_room: @current_room.name,
      rooms: @rooms.transform_values(&:to_h)
    }

    if @save_manager.save_game(game_state, filename)
      puts "Game saved successfully as '#{filename}'."
    else
      puts "Failed to save game."
    end
  rescue StandardError => e
    puts "Error saving game: #{e.message}"
  end

  def handle_load(args)
    if args.empty?
      puts "Specify a save file to load."
      return
    end

    filename = args.join('_')

    begin
      game_state = @save_manager.load_game(filename)
      restore_game_state(game_state)
      puts "Game loaded successfully from '#{filename}'."
      display_room(force: true)
    rescue StandardError => e
      puts "Error loading game: #{e.message}"
    end
  end

  def handle_quit
    print "Are you sure you want to quit? (y/n): "
    input = gets
    return if input.nil?  # Handle EOF/Ctrl+D
    response = input.chomp.downcase
    @game_over = true if response == 'y' || response == 'yes'
  end

  def handle_narrator(args)
    if args.empty?
      status = @narrator.enabled? ? "enabled" : "disabled"
      puts "Narrator is currently #{status}. Use 'narrator on' or 'narrator off' to toggle."
      return
    end

    command = args.first.downcase
    case command
    when 'on', 'enable', 'enabled'
      @narrator.enable
      puts "Narrator enabled."
    when 'off', 'disable', 'disabled'
      @narrator.disable
      puts "Narrator disabled."
    else
      puts "Invalid option. Use 'narrator on' or 'narrator off'."
    end
  end

  def display_room(force: false)
    return if @current_room.visited && !force

    puts "\n" + "=" * 50
    puts @current_room.name.upcase
    puts "=" * 50
    puts @current_room.full_description
    puts "=" * 50
  end

  def display_inventory
    puts "\n--- Inventory ---"
    puts @player.inventory_list
  end

  def display_stats
    puts "\n--- Character Stats ---"
    puts @player.stats
  end

  def display_help
    puts "\n" + @input_handler.help_text
  end

  def display_welcome
    puts <<~WELCOME

      ╔═══════════════════════════════════════════════╗
      ║         DUNGEON QUEST: THE DARK TOWER        ║
      ╚═══════════════════════════════════════════════╝

      A text-based adventure game where you explore
      a mysterious tower filled with monsters, puzzles,
      and treasures. Will you survive?

    WELCOME
  end

  def display_prologue
    player_name = @player ? @player.name : "brave adventurer"

    puts <<~PROLOGUE

      ╔═══════════════════════════════════════════════╗
      ║                 THE LEGEND BEGINS             ║
      ╚═══════════════════════════════════════════════╝

      Long ago, the kingdom lived in peace under the
      rule of King Aldric and his beloved daughter,
      Princess Elena. But one fateful night, the Dark
      Lord emerged from the shadows and kidnapped the
      princess, imprisoning her in his tower fortress.

      You are #{player_name}, a brave adventurer who
      has volunteered to rescue Princess Elena and
      defeat the Dark Lord. The tower looms before you,
      filled with monsters, traps, and dark magic.

      Your quest begins now...

    PROLOGUE
  end

  def display_goodbye
    if @win_condition_met
      puts <<~WIN

        ╔═══════════════════════════════════════════════╗
        ║           CONGRATULATIONS, HERO!             ║
        ╚═══════════════════════════════════════════════╝

        You have conquered the Dark Tower and defeated
        the Dark Lord! Princess Elena is free at last,
        and peace has returned to the kingdom.

        Your name will be remembered in legends!

      WIN
    else
      puts "\nThanks for playing! Goodbye.\n\n"
    end
  end

  def check_game_state
    if @player.dead?
      @game_over = true
      puts "\n--- GAME OVER ---"
      puts "You have been defeated. Better luck next time!"
    end
  end

  def check_win_condition
    boss_room = @rooms[:throne_room]
    if boss_room && !boss_room.has_enemies?
      @win_condition_met = true
      @game_over = true
    end
  end

  def restore_game_state(game_state)
    items_lookup = create_items_lookup
    puzzles_lookup = create_puzzles_lookup
    enemies_lookup = create_enemies_lookup

    # First pass: Create all rooms
    rooms_lookup_by_name = {}
    @rooms = game_state[:rooms].transform_values do |room_data|
      room = Room.from_h(room_data, items_lookup, puzzles_lookup, enemies_lookup, {})
      rooms_lookup_by_name[room.name] = room
      room
    end

    # Second pass: Restore connections between rooms
    game_state[:rooms].each do |room_key, room_data|
      room = @rooms[room_key.to_sym]
      room.restore_connections(room_data, rooms_lookup_by_name)
    end

    @player = Player.from_h(game_state[:player], items_lookup)
    @current_room = rooms_lookup_by_name[game_state[:current_room]]
    @player.move_to_room(@current_room)
  end

  private

  def create_rooms
    @rooms[:entrance] = Room.new("Entrance Hall", "A grand hall with high ceilings and dusty chandeliers. The air is cold and musty.")
    @rooms[:armory] = Room.new("Armory", "Walls lined with weapon racks, most of them empty. A few rusty swords remain.")
    @rooms[:library] = Room.new("Library", "Towering bookshelves filled with ancient tomes. A puzzle inscription glows on the wall.")
    @rooms[:dungeon] = Room.new("Dungeon", "Dark cells line the walls. The smell of decay fills the air.")
    @rooms[:treasure_room] = Room.new("Treasure Room", "Gold and jewels are scattered everywhere. But something guards this place...")
    @rooms[:throne_room] = Room.new("Throne Room", "A massive chamber with a dark throne. The final boss awaits!")
  end

  def create_items
    @sword = Weapon.new("Iron Sword", "A well-balanced sword with a sharp edge", 5)
    @shield = Armor.new("Wooden Shield", "A sturdy shield made of oak", 3)
    @potion = Potion.new("Health Potion", "Restores 30 HP", 30)
    @master_key = Key.new("Master Key", "An ornate key that opens many doors")
    @magic_potion = Potion.new("Magic Elixir", "Restores 50 HP", 50)
    @legendary_sword = Weapon.new("Legendary Blade", "A sword infused with ancient power", 15)
  end

  def create_enemies
    @goblin = Enemy.new("Goblin Warrior", "A small but fierce goblin", 30, 8, 2)
    @goblin.add_loot(@potion)

    @troll = Enemy.new("Cave Troll", "A massive troll with thick skin", 50, 12, 5)
    @troll.add_loot(@master_key)

    @dark_knight = Enemy.new("Dark Knight", "An armored warrior wielding a dark blade", 60, 15, 8)
    @dark_knight.add_loot(@legendary_sword)

    @boss = Boss.new("Dark Lord", "The master of the tower, radiating dark energy", 100, 20, 10, "Shadow Strike")
    @boss.add_loot(@magic_potion)
  end

  def create_puzzles
    @riddle = RiddlePuzzle.new(
      "Ancient Riddle",
      "I speak without a mouth and hear without ears. I have no body, but I come alive with wind. What am I?",
      "echo"
    )
    @riddle.set_reward(@shield)

    @code_puzzle = CodePuzzle.new(
      "Door Code",
      "A numeric keypad shows: 'The answer is the sum of prime numbers less than 10'",
      "17"
    )
  end

  def connect_rooms
    @rooms[:entrance].connect(:north, @rooms[:armory], bidirectional: true)
    @rooms[:entrance].connect(:east, @rooms[:library], bidirectional: true)
    @rooms[:armory].connect(:west, @rooms[:dungeon], bidirectional: true)
    @rooms[:library].connect(:north, @rooms[:treasure_room], bidirectional: true)
    @rooms[:treasure_room].connect(:west, @rooms[:throne_room], bidirectional: true)
    @rooms[:dungeon].connect(:north, @rooms[:throne_room], bidirectional: true)

    # Lock the Treasure Room - requires Master Key
    @rooms[:treasure_room].lock("Master Key")
  end

  def place_items_in_rooms
    @rooms[:entrance].add_item(@potion)
    @rooms[:armory].add_item(@sword)
  end

  def place_enemies_in_rooms
    @rooms[:armory].add_enemy(@goblin)
    @rooms[:dungeon].add_enemy(@troll)
    @rooms[:treasure_room].add_enemy(@dark_knight)
    @rooms[:throne_room].add_enemy(@boss)
  end

  def place_puzzles_in_rooms
    @rooms[:library].add_puzzle(@riddle)
    @riddle.set_reward(@shield)
  end

  def lock_rooms
    # Lock the treasure room - requires Master Key (dropped by troll)
    @rooms[:treasure_room].lock("Master Key")
  end

  def create_items_lookup
    {
      "Iron Sword" => @sword,
      "Wooden Shield" => @shield,
      "Health Potion" => @potion,
      "Master Key" => @master_key,
      "Magic Elixir" => @magic_potion,
      "Legendary Blade" => @legendary_sword
    }
  end

  def create_puzzles_lookup
    {
      "Ancient Riddle" => @riddle,
      "Door Code" => @code_puzzle
    }
  end

  def create_enemies_lookup
    {
      "Goblin Warrior" => @goblin,
      "Cave Troll" => @troll,
      "Dark Knight" => @dark_knight,
      "Dark Lord" => @boss
    }
  end
end
