require 'twig'
require 'json'
require 'rspec/radar'

RSpec.configure do |rspec|
  rspec.expect_with :rspec do |config|
    config.syntax = :expect
  end

  rspec.mock_with :rspec do |mocks|
    mocks.yield_receiver_to_any_instance_implementation_blocks = true
  end
end
