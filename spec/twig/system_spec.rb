require 'spec_helper'

describe Twig::System do
  describe '.windows?' do
    it 'returns true if `RUBY_PLATFORM` is `win32`' do
      stub_const('RUBY_PLATFORM', 'win32')
      expect(Twig::System.windows?).to be_true
    end
  end
end
