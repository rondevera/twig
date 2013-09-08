require 'spec_helper'

describe Twig::Subcommands do
  describe '.all_names' do
    it 'returns a unique, sorted list of known subcommands' do
      Twig::Subcommands.stub(:bin_dir_paths) { %w[foo/bin bar/bin] }
      expect(Dir).to receive(:glob).with('foo/bin/twig-*').
        and_yield('foo/bin/twig-subcommand-2').
        and_yield('foo/bin/twig-subcommand-1')
      expect(Dir).to receive(:glob).with('bar/bin/twig-*').
        and_yield('bar/bin/twig-subcommand-1')

      names = Twig::Subcommands.all_names

      expect(names).to eq(%w[subcommand-1 subcommand-2])
    end

    it 'returns an empty array if no subcommands are found' do
      Twig::Subcommands.stub(:bin_dir_paths) { %w[foo/bin bar/bin] }
      expect(Dir).to receive(:glob).with('foo/bin/twig-*')
      expect(Dir).to receive(:glob).with('bar/bin/twig-*')

      names = Twig::Subcommands.all_names

      expect(names).to eq([])
    end
  end

end
