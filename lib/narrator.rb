# frozen_string_literal: true

# Narrator provides atmospheric commentary on player actions
# Inspired by narrative-driven games, adds flavor text to enhance immersion
class Narrator
  def initialize
    @enabled = true
    @commentary = build_commentary
  end

  def enabled?
    @enabled
  end

  def enable
    @enabled = true
  end

  def disable
    @enabled = false
  end

  # Returns narrative commentary for a given action
  # @param action [Symbol] the action being performed
  # @param context [Hash] optional context (enemy, item, direction, etc.)
  # @return [String, nil] commentary string or nil if disabled/unknown
  def narrate(action, context = {})
    return nil unless @enabled
    return nil unless @commentary.key?(action)

    # Select a random variation from the available commentary
    variations = @commentary[action]
    template = variations.sample

    # Replace placeholders with context values
    interpolate(template, context)
  end

  def to_h
    {
      enabled: @enabled
    }
  end

  def self.from_h(data)
    narrator = new
    narrator.instance_variable_set(:@enabled, data[:enabled])
    narrator
  end

  private

  def interpolate(template, context)
    result = template.dup
    context.each do |key, value|
      result.gsub!("{#{key}}", value.to_s)
    end
    result
  end

  def build_commentary
    {
      move: [
        "The hero ventured {direction}, deeper into the unknown.",
        "With courage in their heart, they moved {direction}.",
        "{direction} they went, step by careful step.",
        "The brave adventurer pressed {direction}ward.",
        "And so, the journey continued {direction}."
      ],
      attack: [
        "With determination in their eyes, they charged at the {enemy}!",
        "Steel rang out as the hero attacked the {enemy}!",
        "The battle raged on as they struck at the {enemy}!",
        "Fury guided their blade toward the {enemy}!",
        "The hero's weapon found its mark against the {enemy}!"
      ],
      take: [
        "The hero claimed the {item}, adding it to their growing arsenal.",
        "With a swift motion, they picked up the {item}.",
        "{item} acquired. Every item might prove useful on this quest.",
        "The {item} was swiftly added to their inventory.",
        "They reached out and took the {item}."
      ],
      use: [
        "The hero made use of the {item}.",
        "Wisely, they decided to use the {item}.",
        "The {item} served its purpose well.",
        "In a moment of need, they used the {item}.",
        "The {item} was put to good use."
      ],
      equip: [
        "The {item} fit perfectly in the hero's hands.",
        "Armed with the {item}, they felt more prepared for battle.",
        "The hero equipped the {item}, ready for what lay ahead.",
        "The {item} gleamed as it was readied for combat.",
        "Now wielding the {item}, the hero stood ready."
      ],
      flee: [
        "The hero made a tactical retreat, living to fight another day.",
        "Discretion being the better part of valor, they fled the battle.",
        "Sometimes retreat is the wisest choice. The hero ran for safety.",
        "The hero turned and fled, seeking a better advantage.",
        "Not all battles must be fought head-on. They escaped."
      ],
      solve: [
        "The hero pondered the {puzzle}, seeking the answer within.",
        "With a keen mind, they approached the {puzzle}.",
        "The {puzzle} stood before them, waiting to be solved.",
        "Intelligence would be their weapon against this {puzzle}.",
        "They examined the {puzzle} carefully."
      ],
      death: [
        "And so, the hero's tale came to a tragic end...",
        "Darkness claimed the brave adventurer. Their quest was over.",
        "The hero fell, their mission unfulfilled.",
        "This was not the ending anyone had hoped for.",
        "The tower had claimed another victim."
      ],
      victory: [
        "Against all odds, the hero emerged victorious!",
        "The Dark Lord fell, and peace was restored to the kingdom!",
        "The princess was saved, and the hero's legend was born!",
        "Thus ends the tale of bravery, sacrifice, and triumph!",
        "And they lived happily ever after... or did they?"
      ],
      dodge: [
        "With lightning reflexes, the hero evaded the {enemy}'s attack!",
        "The {enemy} struck at nothing but air as the hero dodged!",
        "Swift as the wind, they avoided the {enemy}'s blow!",
        "The hero's agility saved them from the {enemy}'s strike!",
        "A graceful sidestep, and the {enemy}'s attack missed entirely!"
      ],
      block: [
        "The hero's defense held firm against the {enemy}'s assault!",
        "Steel met steel as the hero blocked the {enemy}'s attack!",
        "Their armor absorbed the brunt of the {enemy}'s strike!",
        "The hero weathered the {enemy}'s blow, standing strong!",
        "With practiced skill, they blocked the {enemy}'s attack!"
      ],
      critical_hit: [
        "A devastating blow! The {enemy} reeled from the critical strike!",
        "The hero found a weak point and struck with all their might!",
        "CRITICAL! The {enemy} never saw that coming!",
        "A perfect strike! The {enemy} took massive damage!",
        "The hero's weapon found its mark with deadly precision against the {enemy}!"
      ],
      unlock: [
        "The key turned in the lock, granting passage {direction}.",
        "With a satisfying click, the door to the {direction} unlocked.",
        "The way {direction} was now open to the hero.",
        "The locked door yielded to the hero's key, opening {direction}ward.",
        "Access granted. The path {direction} lay before them."
      ],
      look: [
        "The hero surveyed their surroundings carefully.",
        "They took a moment to examine the area.",
        "Keen eyes scanned the room for details.",
        "The hero paused to take in their environment.",
        "Observation is the key to survival. They looked around."
      ],
      drop: [
        "The {item} was left behind, no longer needed.",
        "The hero decided to lighten their load, dropping the {item}.",
        "The {item} clattered to the ground as it was released.",
        "They discarded the {item}, making room for other treasures.",
        "The {item} was deemed unnecessary and dropped."
      ],
      unequip: [
        "The {item} was carefully set aside.",
        "The hero removed the {item}, storing it safely.",
        "No longer needed, the {item} was unequipped.",
        "The {item} was stowed away for later use.",
        "They removed the {item} from their equipment."
      ]
    }
  end
end
