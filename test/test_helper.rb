require 'minitest/autorun'
require 'json'

# Require all lib files
Dir[File.join(__dir__, '..', 'lib', '*.rb')].each { |file| require file }
