require 'spec_helper'

describe Twig::Subcommands do
  describe '.all_names' do
    it 'returns a unique, sorted list of known subcommands' do
      Twig::Subcommands.stub(:bin_dir_paths) { %w[foo/bin bar/bin] }
      Dir.should_receive(:glob).with('foo/bin/twig-*').
        and_yield('foo/bin/twig-subcommand-2').
        and_yield('foo/bin/twig-subcommand-1')
      Dir.should_receive(:glob).with('bar/bin/twig-*').
        and_yield('bar/bin/twig-subcommand-1')

      names = Twig::Subcommands.all_names

      names.should == %w[subcommand-1 subcommand-2]
    end

    it 'returns an empty array if no subcommands are found' do
      Twig::Subcommands.stub(:bin_dir_paths) { %w[foo/bin bar/bin] }
      Dir.should_receive(:glob).with('foo/bin/twig-*')
      Dir.should_receive(:glob).with('bar/bin/twig-*')

      names = Twig::Subcommands.all_names

      names.should == []
    end
  end

end
