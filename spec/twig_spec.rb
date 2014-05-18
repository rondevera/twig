require 'spec_helper'
require 'tmpdir'

describe Twig do
  describe '.repo?' do
    it 'is true when the working directory is a git repository' do
      Dir.chdir(File.dirname(__FILE__)) do
        expect(Twig).to be_repo
      end
    end

    it 'is false when the working directory is not a git repository' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          expect(Twig).not_to be_repo
        end
      end
    end

    it 'captures stderr' do
      expect(Twig).to receive(:run).with(/2>&1/)
      Twig.repo?
    end
  end

  describe '#initialize' do
    it 'creates a Twig instance' do
      twig = Twig.new
      expect(twig.options).to eq(
        :github_api_uri_prefix => Twig::DEFAULT_GITHUB_API_URI_PREFIX,
        :github_uri_prefix => Twig::DEFAULT_GITHUB_URI_PREFIX,
        :header_color => Twig::DEFAULT_HEADER_COLOR
      )
    end

    it 'reads config files and command-line options when `:read_options` is true' do
      expect_any_instance_of(Twig).to receive(:read_config_file!)
      expect_any_instance_of(Twig).to receive(:read_cli_options!)

      Twig.new(:read_options => true)
    end

    it 'does not read config files or command-line options when `:read_options` is falsy' do
      expect_any_instance_of(Twig).not_to receive(:read_config_file!)
      expect_any_instance_of(Twig).not_to receive(:read_cli_options!)

      Twig.new(:read_options => false)
      Twig.new(:read_options => nil)
      Twig.new
    end
  end

  describe '#current_branch_name' do
    it 'returns the current branch name' do
      twig        = Twig.new
      branch_name = 'fix_all_the_things'
      expect(Twig).to receive(:run).
        with('git rev-parse --abbrev-ref HEAD').
        once. # Should memoize
        and_return(branch_name)

      2.times { expect(twig.current_branch_name).to eq(branch_name) }
    end
  end

  describe '#target_branch_name' do
    before :each do
      @current_branch_name = 'current-branch'
      @twig = Twig.new
      allow(@twig).to receive(:current_branch_name).and_return(@current_branch_name)
    end

    it 'returns the branch specified in options' do
      feature_branch_name = 'feature-branch'
      expect(Twig::Branch).to receive(:all_branch_names).and_return([feature_branch_name])
      @twig.set_option(:branch, feature_branch_name)

      expect(@twig.target_branch_name).to eq(feature_branch_name)
    end

    it 'returns the current branch by default' do
      expect(@twig.target_branch_name).to eq(@current_branch_name)
    end
  end

  describe '#target_branch' do
    before :each do
      @twig = Twig.new
    end

    it 'returns a Branch object for the target branch name' do
      branch_name = 'feature-branch'
      allow(@twig).to receive(:target_branch_name).and_return(branch_name)

      branch = @twig.target_branch

      expect(branch.name).to eq(branch_name)
    end
  end

  describe '#branches' do
    before :each do
      @twig = Twig.new
      branch_names = %w[
        fix_some_of_the_things
        fix_some_other_of_the_things
        fix_nothing
        fix_everything
      ]
      commit_times = [
        Twig::CommitTime.new(Time.now - 86400 * 10),
        Twig::CommitTime.new(Time.now - 86400 * 20),
        Twig::CommitTime.new(Time.now - 86400 * 30),
        Twig::CommitTime.new(Time.now - 86400 * 40)
      ]
      @branches = [
        Twig::Branch.new(branch_names[0], :last_commit_time => commit_times[0]),
        Twig::Branch.new(branch_names[1], :last_commit_time => commit_times[1]),
        Twig::Branch.new(branch_names[2], :last_commit_time => commit_times[2]),
        Twig::Branch.new(branch_names[3], :last_commit_time => commit_times[3])
      ]
      allow(Twig::Branch).to receive(:all_branches) { @branches }
    end

    it 'returns all branches' do
      expect(@twig.branches).to eq(@branches)
    end

    it 'returns only branches below a certain age' do
      @twig.set_option(:max_days_old, 25)

      branch_names = @twig.branches.map { |branch| branch.name }
      expect(branch_names).to eq([@branches[0].name, @branches[1].name])
    end

    it 'returns all branches except those matching a name pattern' do
      @twig.set_option(:property_except, :branch => /fix_some/)

      branch_names = @twig.branches.map { |branch| branch.name }
      expect(branch_names).to eq([@branches[2].name, @branches[3].name])
    end

    it 'returns only branches matching a name pattern' do
      @twig.set_option(:property_only, :branch => /fix_some/)

      branch_names = @twig.branches.map { |branch| branch.name }
      expect(branch_names).to eq([@branches[0].name, @branches[1].name])
    end

    it 'returns a list of branches, most recently modified first' do
      branch_names = @twig.branches.map { |branch| branch.name }

      expect(branch_names).to eq([
        @branches[0].name,
        @branches[1].name,
        @branches[2].name,
        @branches[3].name
      ])
    end

    it 'returns a list of branches, least recently modified first' do
      @twig.set_option(:reverse, true)

      branch_names = @twig.branches.map { |branch| branch.name }

      expect(branch_names).to eq([
        @branches[3].name,
        @branches[2].name,
        @branches[1].name,
        @branches[0].name
      ])
    end

    context 'with property filtering' do
      before :each do
        allow(@branches[0]).to receive(:get_property).with('foo') { 'bar1' }
        allow(@branches[1]).to receive(:get_property).with('foo') { 'bar2' }
        allow(@branches[2]).to receive(:get_property).with('foo') { 'baz' }
        allow(@branches[3]).to receive(:get_property).with('foo') { nil }
      end

      it 'returns all branches except those matching a property pattern' do
        @twig.set_option(:property_except, :foo => /bar/)

        branch_names = @twig.branches.map { |branch| branch.name }
        expect(branch_names).to eq([@branches[2].name, @branches[3].name])
      end

      it 'returns only branches matching a property pattern' do
        @twig.set_option(:property_only, :foo => /bar/)

        branch_names = @twig.branches.map { |branch| branch.name }
        expect(branch_names).to eq([@branches[0].name, @branches[1].name])
      end
    end
  end

  describe '#property_names' do
    before :each do
      @twig = Twig.new
      property_names = %w[foo bar baz]
      expect(Twig::Branch).to receive(:all_property_names).and_return(property_names)
    end

    it 'returns an array of all property names' do
      property_names = @twig.property_names
      expect(property_names).to eq(%w[foo bar baz])
    end

    it 'returns an array with only certain property names' do
      @twig.set_option(:property_only_name, /ba/)
      property_names = @twig.property_names

      expect(property_names).to eq(%w[bar baz])
    end

    it 'returns an array without certain property names' do
      @twig.set_option(:property_except_name, /ba/)
      property_names = @twig.property_names

      expect(property_names).to eq(%w[foo])
    end
  end

  describe '#list_branches' do
    before :each do
      @twig = Twig.new
      @list_headers = '[branch list headers]'
      commit_times = [
        Twig::CommitTime.new(Time.now),
        Twig::CommitTime.new(Time.now)
      ]
      allow(commit_times[0]).to receive(:to_i) {  2000_01_01  }
      allow(commit_times[0]).to receive(:to_s) { '2000-01-01' }
      allow(commit_times[1]).to receive(:to_i) {  2000_01_02  }
      allow(commit_times[1]).to receive(:to_s) { '2000-01-02' }
      @branches = [
        Twig::Branch.new('foo', :last_commit_time => commit_times[0]),
        Twig::Branch.new('foo', :last_commit_time => commit_times[1])
      ]
      @branch_lines = ['[foo line]', '[bar line]']
    end

    it 'returns a formatted list of branches' do
      expect(@twig).to receive(:branches).at_least(:once).and_return(@branches)
      expect(@twig).to receive(:branch_list_headers).and_return(@list_headers)
      expect(@twig).to receive(:branch_list_line).with(@branches[0]).
        and_return(@branch_lines[0])
      expect(@twig).to receive(:branch_list_line).with(@branches[1]).
        and_return(@branch_lines[1])

      result = @twig.list_branches

      expect(result).to eq(
        "\n" + @list_headers + @branch_lines[0] +
        "\n" + @branch_lines[1]
      )
    end

    it 'returns a message if all branches were filtered out by options' do
      allow(Twig::Branch).to receive(:all_branches) { %w[foo bar] }
      allow(@twig).to receive(:branches) { [] }

      expect(@twig.list_branches).to include(
        'There are no branches matching your selected options'
      )
    end

    it 'returns a message if the repo has no branches' do
      allow(Twig::Branch).to receive(:all_branches) { [] }
      allow(@twig).to receive(:branches) { [] }

      expect(@twig.list_branches).to include('This repository has no branches')
    end
  end

  describe '#get_branch_property' do
    before :each do
      @twig   = Twig.new
      @branch = Twig::Branch.new('test')
    end

    it 'calls `Twig::Branch#get_property`' do
      property_name  = 'foo'
      property_value = 'bar'
      expect(Twig::Branch).to receive(:new).with(@branch.name).and_return(@branch)
      expect(@branch).to receive(:get_property).with(property_name).
        and_return(property_value)

      result = @twig.get_branch_property(@branch.name, property_name)
      expect(result).to eq(property_value)
    end
  end

  describe '#set_branch_property' do
    it 'calls `Twig::Branch#set_property`' do
      twig   = Twig.new
      branch = Twig::Branch.new('test')
      property_name  = 'foo'
      property_value = 'bar'
      expect(Twig::Branch).to receive(:new).with(branch.name).and_return(branch)
      expect(branch).to receive(:set_property).with(property_name, property_value)

      twig.set_branch_property(branch.name, property_name, property_value)
    end
  end

  describe '#unset_branch_property' do
    it 'calls `Twig::Branch#unset_property`' do
      twig   = Twig.new
      branch = Twig::Branch.new('test')
      property_name = 'foo'
      expect(Twig::Branch).to receive(:new).with(branch.name).and_return(branch)
      expect(branch).to receive(:unset_property).with(property_name)

      twig.unset_branch_property(branch.name, property_name)
    end
  end

end
