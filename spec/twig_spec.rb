require 'spec_helper'

describe Twig do
  describe '#initialize' do
    it 'creates a Twig instance' do
      twig = Twig.new
      twig.options.should == {
        :header_color => Twig::DEFAULT_HEADER_COLOR
      }
    end
  end

  describe '#current_branch_name' do
    it 'returns the current branch name' do
      twig        = Twig.new
      branch_name = 'fix_all_the_things'
      Twig.should_receive(:run).
        with('git symbolic-ref -q HEAD').
        once. # Should memoize
        and_return(Twig::REF_PREFIX + branch_name)

      2.times { twig.current_branch_name.should == branch_name }
    end
  end

  describe '#all_branches' do
    before :each do
      @branch_names = %w[
        fix_some_of_the_things
        fix_some_other_of_the_things
        fix_nothing
      ]
      @commit_time_strings = ['2001-01-01',   '2002-02-02',   '2003-03-03'  ]
      @commit_time_agos    = ['111 days ago', '222 days ago', '333 days ago']
      @command =
        %{git for-each-ref #{Twig::REF_PREFIX} --format="#{Twig::REF_FORMAT}"}

      @branch_tuples = (0..2).map do |i|
        "#{@branch_names[i]},#{@commit_time_strings[i]},#{@commit_time_agos[i]}"
      end.join("\n")
    end

    it 'returns an array of branches' do
      Twig.should_receive(:run).with(@command).and_return(@branch_tuples)
      twig = Twig.new

      branches = twig.all_branches

      branches[0].name.should == @branch_names[0]
      branches[0].last_commit_time.to_s.
        should =~ %r{#{@commit_time_strings[0]} .* \(111d ago\)}
      branches[1].name.should == @branch_names[1]
      branches[1].last_commit_time.to_s.
        should =~ %r{#{@commit_time_strings[1]} .* \(222d ago\)}
      branches[2].name.should == @branch_names[2]
      branches[2].last_commit_time.to_s.
        should =~ %r{#{@commit_time_strings[2]} .* \(333d ago\)}
    end

    it 'memoizes the result' do
      Twig.should_receive(:run).with(@command).once.and_return(@branch_tuples)
      twig = Twig.new

      2.times { twig.all_branches }
    end
  end

  describe '#branches' do
    before :each do
      @twig = Twig.new
      branch_names = %w[
        fix_some_of_the_things
        fix_some_other_of_the_things
        fix_nothing
      ]
      commit_times = [
        Twig::CommitTime.new(Time.now - 86400 * 10, '10 days ago'),
        Twig::CommitTime.new(Time.now - 86400 * 20, '20 days ago'),
        Twig::CommitTime.new(Time.now - 86400 * 30, '30 days ago')
      ]
      @branches = [
        Twig::Branch.new(branch_names[0], :last_commit_time => commit_times[0]),
        Twig::Branch.new(branch_names[1], :last_commit_time => commit_times[1]),
        Twig::Branch.new(branch_names[2], :last_commit_time => commit_times[2])
      ]
      @twig.stub(:all_branches => @branches)
    end

    it 'returns all branches' do
      @twig.branches.should == @branches
    end

    it 'returns only branches matching a name pattern' do
      @twig.set_option(:branch_only, /fix_some/)
      @twig.branches.map { |branch| branch.name }.
        should == [@branches[0].name, @branches[1].name]
    end

    it 'returns all branches except those matching a name pattern' do
      @twig.set_option(:branch_except, /fix_some/)
      @twig.branches.map { |branch| branch.name }.should == [@branches[2].name]
    end

    it 'returns only branches below a certain age' do
      @twig.set_option(:max_days_old, 25)
      @twig.branches.map { |branch| branch.name }.
        should == [@branches[0].name, @branches[1].name]
    end
  end

  describe '#branch_names' do
    it 'returns an array of branch names' do
      twig = Twig.new
      branch_names = %w[foo bar baz]
      branches = branch_names.map { |name| Twig::Branch.new(name) }
      twig.should_receive(:branches).and_return(branches)

      twig.branch_names.should == branch_names
    end
  end

  describe '#list_branches' do
    before :each do
      @twig = Twig.new
      @list_headers = '[branch list headers]'
      commit_times = [
        Twig::CommitTime.new(Time.now, '111 days ago'),
        Twig::CommitTime.new(Time.now, '222 days ago')
      ]
      commit_times[0].stub(:to_i => 2000_01_01 )
      commit_times[0].stub(:to_s =>'2000-01-01')
      commit_times[1].stub(:to_i => 2000_01_02 )
      commit_times[1].stub(:to_s =>'2000-01-02')
      @branches = [
        Twig::Branch.new('foo', :last_commit_time => commit_times[0]),
        Twig::Branch.new('foo', :last_commit_time => commit_times[1])
      ]
      @branch_lines = ['[foo line]', '[bar line]']
    end

    it 'returns a list of branches, most recently modified first' do
      @twig.should_receive(:branches).at_least(:once).and_return(@branches)
      @twig.should_receive(:branch_list_headers).and_return(@list_headers)
      @twig.should_receive(:branch_list_line).with(@branches[0]).
        and_return(@branch_lines[0])
      @twig.should_receive(:branch_list_line).with(@branches[1]).
        and_return(@branch_lines[1])
      result = @twig.list_branches

      result.should == "\n" + @list_headers +
        @branch_lines[1] + "\n" + @branch_lines[0]
    end

    it 'returns a message if all branches were filtered out by options' do
      @twig.stub(:all_branches => %w[foo bar])
      @twig.stub(:branches => [])

      @twig.list_branches.should include(
        'There are no branches matching your selected options'
      )
    end

    it 'returns a message if the repo has no branches' do
      @twig.stub(:all_branches => [])
      @twig.stub(:branches => [])

      @twig.list_branches.should include('This repository has no branches')
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
      Twig::Branch.should_receive(:new).with(@branch.name).and_return(@branch)
      @branch.should_receive(:get_property).with(property_name).
        and_return(property_value)

      result = @twig.get_branch_property(@branch.name, property_name)
      result.should == property_value
    end
  end

  describe '#set_branch_property' do
    it 'calls `Twig::Branch#set_property`' do
      twig   = Twig.new
      branch = Twig::Branch.new('test')
      property_name  = 'foo'
      property_value = 'bar'
      Twig::Branch.should_receive(:new).with(branch.name).and_return(branch)
      branch.should_receive(:set_property).with(property_name, property_value)

      twig.set_branch_property(branch.name, property_name, property_value)
    end
  end

  describe '#unset_branch_property' do
    it 'calls `Twig::Branch#unset_property`' do
      twig   = Twig.new
      branch = Twig::Branch.new('test')
      property_name = 'foo'
      Twig::Branch.should_receive(:new).with(branch.name).and_return(branch)
      branch.should_receive(:unset_property).with(property_name)

      twig.unset_branch_property(branch.name, property_name)
    end
  end

end
