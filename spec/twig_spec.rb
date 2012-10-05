require 'spec_helper'

describe Twig do
  describe '#initialize' do
    it 'creates a Twig instance' do
      twig = Twig.new
      twig.options.should == {}
    end

    it 'creates a Twig instance with arbitrary options' do
      options = {:foo => 'bar'}
      twig = Twig.new(options)

      twig.options.should == options
    end
  end

  describe '#current_branch' do
    it 'returns the current branch name' do
      twig   = Twig.new
      branch = 'fix_all_the_things'
      Twig.should_receive(:run).
        with('git symbolic-ref -q HEAD').
        once. # Should memoize
        and_return("refs/heads/#{branch}")

      2.times { twig.current_branch.should == branch }
    end
  end

  describe '#branches' do
    before :each do
      @branches = %w[
        fix_some_of_the_things
        fix_some_other_of_the_things
        fix_nothing
      ]
      @branch_refs = %w[
        refs/heads/fix_some_of_the_things
        refs/heads/fix_some_other_of_the_things
        refs/heads/fix_nothing
      ]
    end

    it 'returns all branches' do
      twig = Twig.new
      Twig.should_receive(:run).
        with('git for-each-ref --format="%(refname)" refs/heads/').
        and_return(@branch_refs.join("\n"))

      twig.branches.should == @branches.sort
    end

    it 'returns only branches matching a name pattern' do
      twig = Twig.new(:name_only => /fix_some/)
      Twig.should_receive(:run).and_return(@branch_refs.join("\n"))

      branches = twig.branches
      branches.should == @branches.first(2)
    end

    it 'returns all branches except those matching a name pattern' do
      twig = Twig.new(:name_except => /fix_some/)
      Twig.should_receive(:run).and_return(@branch_refs.join("\n"))

      branches = twig.branches
      branches.should == [@branches.last]
    end

    it 'memoizes the result' do
      twig = Twig.new
      Twig.should_receive(:run).once.and_return(@branch_refs.join("\n"))

      2.times { twig.branches }
    end
  end

  describe '#all_branch_properties' do
    before :each do
      @twig = Twig.new
      @config = %{
        user.name=Ron DeVera
        branch.autosetupmerge=always
        remote.origin.url=git@github.com:rondevera/twig.git
        remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*
        branch.master.remote=origin
        branch.master.merge=refs/heads/master
        branch.master.test0=value0
        branch.test_branch_1.remote=origin
        branch.test_branch_1.merge=refs/heads/test_branch_1
        branch.test_branch_1.test0=value1
        branch.test_branch_1.test1=value1
        branch.test_branch_2.remote=origin
        branch.test_branch_2.merge=refs/heads/test_branch_2
        branch.test_branch_2.test2=value2
      }.gsub(/^\s+/, '')
    end

    it 'returns the union of properties for all branches' do
      Twig.should_receive(:run).with('git config --list').and_return(@config)

      result = @twig.all_branch_properties
      result.should == %w[test0 test1 test2]
    end

    it 'memoizes the result' do
      Twig.should_receive(:run).once.and_return(@config)
      2.times { @twig.all_branch_properties }
    end
  end

  describe '#last_commit_times_for_branches' do
    before :each do
      @twig = Twig.new
      @branch_times = [1348859410, 1348609394]
      @branch_relative_times = ['4 days ago', '7 days ago']
      @branch_time_strings_result = %{
        #{@branch_times[0]},#{@branch_relative_times[0]}

        #{@branch_times[1]},#{@branch_relative_times[1]}

      }.gsub(/^s+/, '')
      @twig.should_receive(:branches).
        any_number_of_times.and_return(%w[branch1 branch2])
    end

    it 'returns the last commit times for all branches' do
      Twig.should_receive(:run).
        with(%{git show branch1 branch2 --format="%ct,%cr" -s}).
        and_return(@branch_time_strings_result)

      commit_times = @twig.last_commit_times_for_branches
      commit_times.keys.should =~ %w[branch1 branch2]
      commit_times['branch1'].instance_variable_get(:@time).
        should == Time.at(@branch_times[0])
      commit_times['branch1'].instance_variable_get(:@time_ago).
        should == '4d ago'
      commit_times['branch2'].instance_variable_get(:@time).
        should == Time.at(@branch_times[1])
      commit_times['branch2'].instance_variable_get(:@time_ago).
        should == '7d ago'
    end

    it 'memoizes the result' do
      Twig.should_receive(:run).once.and_return(@branch_time_strings_result)
      2.times { @twig.last_commit_times_for_branches }
    end
  end

  describe '#list_branches' do
    xit 'lists branches' do
      # FIXME: Refactor into smaller methods and write tests
    end
  end

  describe '#get_branch_property' do
    it 'returns a branch property' do
      @twig    = Twig.new
      branch   = 'fix_all_the_things'
      property = 'test'
      value    = 'value'
      Twig.should_receive(:run).
        with(%{git config branch.#{branch}.#{property}}).
        and_return(value)

      result = @twig.get_branch_property(branch, property)
      result.should == value
    end
  end

  describe '#set_branch_property' do
    before :each do
      @twig = Twig.new
    end

    it 'sets a branch property' do
      branch   = 'fix_all_the_things'
      property = 'test'
      value    = 'value'
      Twig.should_receive(:run).
        with(%{git config branch.#{branch}.#{property} "#{value}"}).
        and_return(value)

      result = @twig.set_branch_property(branch, property, value)
      result.should =~ /Saved property "#{property}" as "#{value}" for branch "#{branch}"/
    end

    it 'refuses to set a reserved branch property' do
      branch   = 'fix_all_the_things'
      property = 'merge'
      value    = 'NOOO'
      Twig.should_not_receive(:run)

      result = @twig.set_branch_property(branch, property, value)
      result.should =~ /Can't modify the reserved property "#{property}"/
    end

    it 'unsets a branch property' do
      branch   = 'fix_all_the_things'
      property = 'test'
      Twig.should_receive(:run).
        with(%{git config --unset branch.#{branch}.#{property}})

      result = @twig.set_branch_property(branch, property, '')
      result.should =~ /Removed property "#{property}" for branch "#{branch}"/
    end
  end
end
