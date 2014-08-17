require 'twig'
require 'json'

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
    mocks.verify_partial_doubles = true
    mocks.yield_receiver_to_any_instance_implementation_blocks = true
  end
end

def silence_stream(stream)
  # Usage:  `silence_stream($stderr) { error_prone_code }`
  # Source: activesupport v4.1.4
  old_stream = stream.dup
  stream.reopen(RbConfig::CONFIG['host_os'] =~ /mswin|mingw/ ? 'NUL:' : '/dev/null')
  stream.sync = true
  yield
ensure
  stream.reopen(old_stream)
  old_stream.close
end
