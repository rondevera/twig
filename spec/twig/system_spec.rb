require 'spec_helper'

describe Twig::System do
  describe '.windows?' do
    it 'returns true if `host_os` is `win32`' do
      expect(RbConfig::CONFIG).to receive(:[]).with('host_os').
        and_return('win32')
      expect(Twig::System.windows?).to be_true
    end

    it 'returns false if `host_os` is `darwin` (OS X)' do
      expect(RbConfig::CONFIG).to receive(:[]).with('host_os').
        and_return('darwin')
      expect(Twig::System.windows?).to be_false
    end

  end
end
