require 'json'
require 'fileutils'

class SaveManager
  SAVE_DIR = 'saves'

  def initialize
    ensure_save_directory_exists
  end

  def save_game(game_state, filename)
    raise ArgumentError, "Game state cannot be nil" if game_state.nil?
    raise ArgumentError, "Filename cannot be empty" if filename.nil? || filename.empty?

    sanitized_filename = sanitize_filename(filename)
    filepath = File.join(SAVE_DIR, "#{sanitized_filename}.json")

    begin
      File.open(filepath, 'w') do |file|
        file.write(JSON.pretty_generate(game_state))
      end
      true
    rescue StandardError => e
      raise "Failed to save game: #{e.message}"
    end
  end

  def load_game(filename)
    raise ArgumentError, "Filename cannot be empty" if filename.nil? || filename.empty?

    sanitized_filename = sanitize_filename(filename)
    filepath = File.join(SAVE_DIR, "#{sanitized_filename}.json")

    raise "Save file does not exist: #{sanitized_filename}" unless File.exist?(filepath)

    begin
      json_data = File.read(filepath)
      JSON.parse(json_data, symbolize_names: true)
    rescue JSON::ParserError => e
      raise "Failed to load game: Invalid JSON format - #{e.message}"
    rescue StandardError => e
      raise "Failed to load game: #{e.message}"
    end
  end

  def delete_save(filename)
    raise ArgumentError, "Filename cannot be empty" if filename.nil? || filename.empty?

    sanitized_filename = sanitize_filename(filename)
    filepath = File.join(SAVE_DIR, "#{sanitized_filename}.json")

    return false unless File.exist?(filepath)

    begin
      File.delete(filepath)
      true
    rescue StandardError => e
      raise "Failed to delete save: #{e.message}"
    end
  end

  def list_saves
    return [] unless Dir.exist?(SAVE_DIR)

    Dir.glob(File.join(SAVE_DIR, '*.json')).map do |filepath|
      filename = File.basename(filepath, '.json')
      modified_time = File.mtime(filepath)
      {
        name: filename,
        modified: modified_time,
        size: File.size(filepath)
      }
    end.sort_by { |save| -save[:modified].to_i }
  end

  def save_exists?(filename)
    sanitized_filename = sanitize_filename(filename)
    filepath = File.join(SAVE_DIR, "#{sanitized_filename}.json")
    File.exist?(filepath)
  end

  def get_save_info(filename)
    raise ArgumentError, "Filename cannot be empty" if filename.nil? || filename.empty?

    sanitized_filename = sanitize_filename(filename)
    filepath = File.join(SAVE_DIR, "#{sanitized_filename}.json")

    return nil unless File.exist?(filepath)

    {
      name: sanitized_filename,
      path: filepath,
      modified: File.mtime(filepath),
      size: File.size(filepath),
      created: File.ctime(filepath)
    }
  end

  private

  def ensure_save_directory_exists
    FileUtils.mkdir_p(SAVE_DIR) unless Dir.exist?(SAVE_DIR)
  end

  def sanitize_filename(filename)
    filename.gsub(/[^0-9A-Za-z_\-]/, '_')
  end
end
