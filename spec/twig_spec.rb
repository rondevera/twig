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

  describe '#current_branch_name' do
    it 'returns the current branch name' do
      twig        = Twig.new
      branch_name = 'fix_all_the_things'
      Twig.should_receive(:run).
        with('git symbolic-ref -q HEAD').
        once. # Should memoize
        and_return("refs/heads/#{branch_name}")

      2.times { twig.current_branch_name.should == branch_name }
    end
  end

  describe '#branch_names' do
    before :each do
      @branch_names = %w[
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
        with('git for-each-ref refs/heads/ --format="%(refname)"').
        and_return(@branch_refs.join("\n"))

      twig.branch_names.should == @branch_names.sort
    end

    it 'returns only branches below a certain age' do
      twig = Twig.new(:max_days_old => 4)
      branch_commit_times = {
        @branch_names[0] => Time.now - (1 * 86400),
        @branch_names[1] => Time.now - (3 * 86400),
        @branch_names[2] => Time.now - (5 * 86400)
      }
      Twig.should_receive(:run).and_return(@branch_refs.join("\n"))
      twig.stub(:last_commit_times_for_branches => branch_commit_times)

      branch_names = twig.branch_names
      branch_names.should == @branch_names.first(2)
    end

    it 'returns only branches matching a name pattern' do
      twig = Twig.new(:name_only => /fix_some/)
      Twig.should_receive(:run).and_return(@branch_refs.join("\n"))

      branch_names = twig.branch_names
      branch_names.should == @branch_names.first(2)
    end

    it 'returns all branches except those matching a name pattern' do
      twig = Twig.new(:name_except => /fix_some/)
      Twig.should_receive(:run).and_return(@branch_refs.join("\n"))

      branch_names = twig.branch_names
      branch_names.should == [@branch_names.last]
    end

    it 'memoizes the result' do
      twig = Twig.new
      Twig.should_receive(:run).once.and_return(@branch_refs.join("\n"))

      2.times { twig.branch_names }
    end
  end

  describe '#last_commit_times_for_branches' do
    before :each do
      @twig = Twig.new
      @branch_times = [
        '2001-01-01 11:11 -0100',
        '2002-02-02 22:22 -0200'
      ]
      @branch_relative_times = ['4 days ago', '7 days ago']
      branch_names = %w[branch1 branch2]
      @branch_time_strings_result = %{
        #{branch_names[0]},#{@branch_times[0]},#{@branch_relative_times[0]}

        #{branch_names[1]},#{@branch_times[1]},#{@branch_relative_times[1]}

      }.gsub(/^s+/, '')
      @twig.should_receive(:branch_names).
        any_number_of_times.and_return(branch_names)
    end

    it 'returns the last commit times for all branches' do
      Twig.should_receive(:run).
        with('git for-each-ref refs/heads/ ' <<
             '--format="%(refname),%(committerdate),%(committerdate:relative)"').
        and_return(@branch_time_strings_result)

      commit_times = @twig.last_commit_times_for_branches
      commit_times.keys.should =~ %w[branch1 branch2]
      commit_times['branch1'].instance_variable_get(:@time).
        should == Time.parse(@branch_times[0])
      commit_times['branch1'].instance_variable_get(:@time_ago).
        should == '4d ago'
      commit_times['branch2'].instance_variable_get(:@time).
        should == Time.parse(@branch_times[1])
      commit_times['branch2'].instance_variable_get(:@time_ago).
        should == '7d ago'
    end

    it 'memoizes the result' do
      Twig.should_receive(:run).once.and_return(@branch_time_strings_result)
      2.times { @twig.last_commit_times_for_branches }
    end
  end

  describe '#list_branches' do
    before :each do
      @twig = Twig.new
      @list_headers = '[branch list headers]'
      @branches = [
        Twig::Branch.new(@twig, 'foo'),
        Twig::Branch.new(@twig, 'bar')
      ]
      @branch_lines = [ '[foo line]', '[bar line]' ]
      @commit_times = [
        Twig::CommitTime.new(Time.now, ''),
        Twig::CommitTime.new(Time.now, '')
      ]
      @commit_times[0].stub(:to_i => 2000_01_01 )
      @commit_times[0].stub(:to_s =>'2000-01-01')
      @commit_times[1].stub(:to_i => 2000_01_02 )
      @commit_times[1].stub(:to_s =>'2000-01-02')
      @branches[0].stub(:last_commit_time => @commit_times[0])
      @branches[1].stub(:last_commit_time => @commit_times[1])
      Twig::Branch.should_receive(:new).with(anything, @branches[0].name).
        and_return(@branches[0])
      Twig::Branch.should_receive(:new).with(anything, @branches[1].name).
        and_return(@branches[1])
      @twig.should_receive(:branch_list_headers).and_return(@list_headers)
      @twig.should_receive(:branch_names).
        and_return(@branches.map { |branch| branch.name })
    end

    it 'lists branches, most recently modified first' do
      @twig.should_receive(:branch_list_line).with(@branches[0]).
        and_return(@branch_lines[0])
      @twig.should_receive(:branch_list_line).with(@branches[1]).
        and_return(@branch_lines[1])

      result = @twig.list_branches
      result.should == "\n" + @list_headers +
        @branch_lines[1] + "\n" + @branch_lines[0]
    end
  end

  describe '#get_branch_property' do
    it 'calls `Twig::Branch#get_property`' do
      twig           = Twig.new
      branch         = Twig::Branch.new(twig, 'test')
      property_name  = 'foo'
      property_value = 'bar'
      Twig::Branch.should_receive(:new).with(twig, branch.name).
        and_return(branch)
      branch.should_receive(:get_property).with(property_name).
        and_return(property_value)

      result = twig.get_branch_property(branch.name, property_name)
      result.should == property_value
    end
  end

  describe '#set_branch_property' do
    it 'calls `Twig::Branch#set_property`' do
      twig = Twig.new
      branch = Twig::Branch.new(twig, 'test')
      property_name = 'foo'
      property_value = 'bar'
      Twig::Branch.should_receive(:new).with(twig, branch.name).
        and_return(branch)
      branch.should_receive(:set_property).with(property_name, property_value)

      twig.set_branch_property(branch.name, property_name, property_value)
    end
  end

end
