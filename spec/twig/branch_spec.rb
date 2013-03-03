require 'spec_helper'

describe Twig::Branch do
  before :each do
    @twig = Twig.new
  end

  describe '.all_properties' do
    before :each do
      Twig::Branch.instance_variable_set(:@_all_properties, nil)
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

      result = Twig::Branch.all_properties
      result.should == %w[test0 test1 test2]
    end

    it 'handles branch names that contain dots' do
      @config << 'branch.dot1.dot2.dot3.dotproperty=dotvalue'
      Twig.should_receive(:run).with('git config --list').and_return(@config)

      result = Twig::Branch.all_properties
      result.should == %w[dotproperty test0 test1 test2]
    end

    it 'handles branch names that contain equal signs' do
      @config << 'branch.eq1=eq2=eq3.eqproperty=eqvalue'
      Twig.should_receive(:run).with('git config --list').and_return(@config)

      result = Twig::Branch.all_properties
      result.should == %w[eqproperty test0 test1 test2]
    end

    it 'skips path values with an equal sign but no value' do
      @config << 'foo_path='
      Twig.should_receive(:run).with('git config --list').and_return(@config)
      result = Twig::Branch.all_properties
      result.should_not include 'foo_path'
    end

    it 'memoizes the result' do
      Twig.should_receive(:run).once.and_return(@config)
      2.times { Twig::Branch.all_properties }
    end
  end

  describe '#initialize' do
    it 'requires a name' do
      branch = Twig::Branch.new('test')
      branch.name.should == 'test'

      lambda { Twig::Branch.new      }.should raise_exception
      lambda { Twig::Branch.new(nil) }.should raise_exception
      lambda { Twig::Branch.new('')  }.should raise_exception
    end

    it 'accepts a last commit time' do
      commit_time = Twig::CommitTime.new(Time.now, '99 days ago')
      branch = Twig::Branch.new('test', :last_commit_time => commit_time)
      branch.last_commit_time.should == commit_time
    end
  end

  describe '#to_s' do
    it 'returns the branch name' do
      branch = Twig::Branch.new('test')
      branch.to_s.should == 'test'
    end
  end

  describe '#sanitize_property' do
    before :each do
      @branch = Twig::Branch.new('test')
    end

    it 'removes whitespace from branch property names' do
      @branch.sanitize_property('  foo bar  ').should == 'foobar'
    end

    it 'removes underscores from branch property names' do
      @branch.sanitize_property('__foo_bar__').should == 'foobar'
    end
  end

  describe '#get_property' do
    before :each do
      @branch = Twig::Branch.new('test')
    end

    it 'returns a property value' do
      property = 'test'
      value    = 'value'
      Twig.should_receive(:run).
        with(%{git config branch.#{@branch}.#{property}}).
        and_return(value)

      result = @branch.get_property(property)
      result.should == value
    end

    it 'removes whitespace from branch property names' do
      bad_property = '  foo foo  '
      property     = 'foofoo'
      value        = 'bar'
      Twig.should_receive(:run).
        with(%{git config branch.#{@branch}.#{property}}).
        and_return(value)

      result = @branch.get_property(bad_property)
      result.should == value
    end

    it 'returns nil if the property value is an empty string' do
      property = 'test'
      Twig.should_receive(:run).
        with(%{git config branch.#{@branch}.#{property}}).
        and_return('')

      result = @branch.get_property(property)
      result.should == nil
    end
  end

  describe '#set_property' do
    before :each do
      @branch = Twig::Branch.new('test')
    end

    it 'sets a property value' do
      property = 'test'
      value    = 'value'
      Twig.should_receive(:run).
        with(%{git config branch.#{@branch}.#{property} "#{value}"}) do
          `(exit 0)`; value # Set `$?` to `0`
        end

      result = @branch.set_property(property, value)
      result.should include(
        %{Saved property "#{property}" as "#{value}" for branch "#{@branch}"}
      )
    end

    it 'raises an error if Git cannot set the property value' do
      property = 'test'
      value    = 'value'
      Twig.stub(:run) { `(exit 1)`; value } # Set `$?` to `1`

      begin
        @branch.set_property(property, value)
      rescue RuntimeError => exception
        expected_exception = exception
      end

      expected_exception.message.should include(
        %{Could not save property "#{property}" as "#{value}" for branch "#{@branch}"}
      )
    end

    it 'raises an error if trying to set a reserved branch property' do
      property = 'merge'
      value    = 'NOOO'
      Twig.should_not_receive(:run)

      begin
        @branch.set_property(property, value)
      rescue ArgumentError => exception
        expected_exception = exception
      end

      expected_exception.message.should include(
        %{Can't modify the reserved property "#{property}"}
      )
    end

    it 'raises an error if trying to set a branch property to an empty string' do
      property = 'test'
      value    = ''
      Twig.should_not_receive(:run)

      begin
        @branch.set_property(property, value)
      rescue ArgumentError => exception
        expected_exception = exception
      end

      expected_exception.message.should include(
        %{Can't set a branch property to an empty string}
      )
    end

    it 'removes whitespace from branch property names' do
      bad_property = '  foo foo  '
      property     = 'foofoo'
      value        = 'bar'
      Twig.should_receive(:run).
        with(%{git config branch.#{@branch}.#{property} "#{value}"}) do
          `(exit 0)`; value # Set `$?` to `0`
        end

      result = @branch.set_property(bad_property, value)
      result.should include(
        %{Saved property "#{property}" as "#{value}" for branch "#{@branch}"}
      )
    end

    it 'removes underscores from branch property names' do
      bad_property = 'foo_foo'
      property     = 'foofoo'
      value        = 'bar'
      Twig.should_receive(:run).
        with(%{git config branch.#{@branch}.#{property} "#{value}"}) do
          `(exit 0)`; value # Set `$?` to `0`
        end

      result = @branch.set_property(bad_property, value)
      result.should include(
        %{Saved property "#{property}" as "#{value}" for branch "#{@branch}"}
      )
    end

    it 'strips whitespace from a value before setting it as a property' do
      property  = 'test'
      bad_value = '  foo  '
      value     = 'foo'
      Twig.should_receive(:run).
        with(%{git config branch.#{@branch}.#{property} "#{value}"}) do
          `(exit 0)`; value # Set `$?` to `0`
        end

      result = @branch.set_property(property, bad_value)
      result.should include(
        %{Saved property "#{property}" as "#{value}" for branch "#{@branch}"}
      )
    end
  end

  describe '#unset_property' do
    before :each do
      @branch = Twig::Branch.new('test')
    end

    it 'unsets a branch property' do
      property = 'test'
      @branch.should_receive(:get_property).with(property).and_return('value')
      Twig.should_receive(:run).
        with(%{git config --unset branch.#{@branch}.#{property}})

      result = @branch.unset_property(property)
      result.should include(
        %{Removed property "#{property}" for branch "#{@branch}"}
      )
    end

    it 'raises an error if the branch does not have the given property' do
      property = 'test'
      @branch.should_receive(:get_property).with(property).and_return(nil)

      begin
        @branch.unset_property(property)
      rescue Twig::Branch::MissingPropertyError => exception
        expected_exception = exception
      end

      expected_exception.message.should include(
        %{The branch "#{@branch}" does not have the property "#{property}"}
      )
    end
  end

end
