require 'spec_helper'

describe Twig::Subcommands do
  describe '.all_names' do
    it 'returns a unique, sorted list of known subcommands' do
      stub_const('ENV', ENV.to_hash.merge('PATH' => 'foo/bin:bar/bin'))
      expect(Dir).to receive(:glob).with('foo/bin/twig-*').
        and_yield('foo/bin/twig-subcommand-2').
        and_yield('foo/bin/twig-subcommand-1')
      expect(Dir).to receive(:glob).with('bar/bin/twig-*').
        and_yield('bar/bin/twig-subcommand-1')

      names = Twig::Subcommands.all_names

      expect(names).to eq(%w[subcommand-1 subcommand-2])
    end

    it 'returns an empty array if no subcommands are found' do
      stub_const('ENV', ENV.to_hash.merge('PATH' => 'foo/bin:bar/bin'))
      expect(Dir).to receive(:glob).with('foo/bin/twig-*')
      expect(Dir).to receive(:glob).with('bar/bin/twig-*')

      names = Twig::Subcommands.all_names

      expect(names).to eq([])
    end
  end

  describe '.exec_subcommand_if_any' do
    before :each do
      @branch_name = 'test'
      allow(Twig).to receive(:run)
    end

    it 'recognizes a subcommand' do
      command_path = '/path/to/bin/twig-subcommand'
      expect(Twig).to receive(:run).with('which twig-subcommand 2>/dev/null').
        and_return(command_path)
      expect(Twig::Subcommands).to receive(:exec).with(command_path) { exit }

      # Since we're stubbing `exec` (with an expectation), we still need it
      # to exit early like the real implementation. The following handles the
      # exit somewhat gracefully.
      expect {
        Twig::Subcommands.exec_subcommand_if_any(['subcommand'])
      }.to raise_exception { |exception|
        expect(exception).to be_a(SystemExit)
        expect(exception.status).to eq(0)
      }
    end

    it 'does not recognize a subcommand' do
      expect(Twig).to receive(:run).
        with('which twig-subcommand 2>/dev/null').and_return('')
      expect(Twig::Subcommands).not_to receive(:exec)

      Twig::Subcommands.exec_subcommand_if_any(['subcommand'])
    end
  end
end
