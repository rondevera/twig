# encoding: UTF-8
require 'spec_helper'

describe Twig::Branch do
  before :each do
    @twig = Twig.new
  end

  describe '.all_branches' do
    before :each do
      @branch_names = %w[
        fix_some_of_the_things
        fix_some_other_of_the_things
        fix_nothing
      ]
      @commit_time_strings = %w[
        2001-01-01
        2002-02-02
        2003-03-03
      ]
      @commit_time_agos = [
        '111 days ago',
        '2 months ago',
        '3 years, 3 months ago'
      ]
      @command =
        %{git for-each-ref #{Twig::REF_PREFIX} --format="#{Twig::REF_FORMAT}"}

      @branch_tuples = (0..2).map do |i|
        [
          @branch_names[i],
          @commit_time_strings[i],
          @commit_time_agos[i]
        ].join(Twig::REF_FORMAT_SEPARATOR)
      end.join("\n")
    end

    it 'returns an array of branches' do
      expect(Twig).to receive(:run).with(@command).and_return(@branch_tuples)

      branches = Twig::Branch.all_branches

      expect(branches[0].name).to eq(@branch_names[0])
      expect(branches[0].last_commit_time.to_s).to match(
        /#{@commit_time_strings[0]} .* \(111d ago\)/
      )
      expect(branches[1].name).to eq(@branch_names[1])
      expect(branches[1].last_commit_time.to_s).to match(
        /#{@commit_time_strings[1]} .* \(2mo ago\)/
      )
      expect(branches[2].name).to eq(@branch_names[2])
      expect(branches[2].last_commit_time.to_s).to match(
        /#{@commit_time_strings[2]} .* \(3y ago\)/
      )
    end

    it 'memoizes the result' do
      Twig::Branch.instance_variable_set(:@_all_branches, nil)
      expect(Twig).to receive(:run).with(@command).once.and_return(@branch_tuples)

      2.times { Twig::Branch.all_branches }
    end
  end

  describe '.all_branch_names' do
    before :each do
      @branch_names = %w[foo bar baz]
      @branches = @branch_names.map { |name| Twig::Branch.new(name) }
    end

    it 'returns an array of all branch names' do
      expect(Twig::Branch).to receive(:all_branches).and_return(@branches)
      expect(Twig::Branch.all_branch_names).to eq(@branch_names)
    end

    it 'memoizes the result' do
      Twig::Branch.instance_variable_set(:@_all_branch_names, nil)
      expect(Twig::Branch).to receive(:all_branches).once.and_return(@branches)

      2.times { Twig::Branch.all_branch_names }
    end
  end

  describe '.all_property_names' do
    before :each do
      Twig::Branch.instance_variable_set(:@_all_property_names, nil)
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
      expect(Twig).to receive(:run).with('git config --list').and_return(@config)

      result = Twig::Branch.all_property_names
      expect(result).to eq(%w[test0 test1 test2])
    end

    it 'handles branch names that contain dots' do
      @config << 'branch.dot1.dot2.dot3.dotproperty=dotvalue'
      expect(Twig).to receive(:run).with('git config --list').and_return(@config)

      result = Twig::Branch.all_property_names
      expect(result).to eq(%w[dotproperty test0 test1 test2])
    end

    it 'handles branch names that contain equal signs' do
      @config << 'branch.eq1=eq2=eq3.eqproperty=eqvalue'
      expect(Twig).to receive(:run).with('git config --list').and_return(@config)

      result = Twig::Branch.all_property_names
      expect(result).to eq(%w[eqproperty test0 test1 test2])
    end

    it 'skips path values with an equal sign but no value' do
      @config << 'foo_path='
      expect(Twig).to receive(:run).with('git config --list').and_return(@config)
      result = Twig::Branch.all_property_names
      expect(result).not_to include('foo_path')
    end

    it 'memoizes the result' do
      expect(Twig).to receive(:run).once.and_return(@config)
      2.times { Twig::Branch.all_property_names }
    end
  end

  describe '.validate_property_name' do
    it 'raises an exception if the property name is empty' do
      expect {
        Twig::Branch.validate_property_name('')
      }.to raise_exception(Twig::Branch::EmptyPropertyNameError)
    end

    it 'does nothing if the property name is not empty' do
      expect {
        Twig::Branch.validate_property_name('test')
      }.not_to raise_exception
    end
  end

  describe '#initialize' do
    it 'requires a name' do
      branch = Twig::Branch.new('test')
      expect(branch.name).to eq('test')

      expect { Twig::Branch.new      }.to raise_exception
      expect { Twig::Branch.new(nil) }.to raise_exception
      expect { Twig::Branch.new('')  }.to raise_exception
    end

    it 'accepts a last commit time' do
      commit_time = Twig::CommitTime.new(Time.now, '99 days ago')
      branch = Twig::Branch.new('test', :last_commit_time => commit_time)
      expect(branch.last_commit_time).to eq(commit_time)
    end
  end

  describe '#to_s' do
    it 'returns the branch name' do
      branch = Twig::Branch.new('test')
      expect(branch.to_s).to eq('test')
    end
  end

  describe '#to_hash' do
    before :each do
      @branch = Twig::Branch.new('test')
      time = Time.parse('2000-01-01 18:30 UTC')
      commit_time = Twig::CommitTime.new(time, '')
      @time_string = time.iso8601
      allow(@branch).to receive(:last_commit_time) { commit_time }
    end

    it 'returns the hash for a branch with properties' do
      expect(@branch).to receive(:get_properties).with(%w[foo bar]) do
        { 'foo' => 'foo!', 'bar' => 'bar!' }
      end

      result = @branch.to_hash(%w[foo bar])

      expect(result).to eq(
        'name' => 'test',
        'last-commit-time' => @time_string,
        'properties' => {
          'foo' => 'foo!',
          'bar' => 'bar!'
        }
      )
    end

    it 'returns the hash for a branch with no properties' do
      expect(@branch).to receive(:get_properties).with(%w[foo bar]).and_return({})

      result = @branch.to_hash(%w[foo bar])

      expect(result).to eq(
        'name' => 'test',
        'last-commit-time' => @time_string,
        'properties' => {}
      )
    end
  end

  describe '#parent_name' do
    before :each do
      @branch = Twig::Branch.new('test')
    end

    it 'returns the parent branch name' do
      parent_name = 'parent'
      allow(@branch).to receive(:get_property).with('diff-branch').and_return(parent_name)

      expect(@branch.parent_name).to eq(parent_name)
    end

    it 'returns nil if the parent branch is unknown' do
      allow(@branch).to receive(:get_property).with('diff-branch')
      expect(@branch.parent_name).to be_nil
    end
  end

  describe '#sanitize_property' do
    before :each do
      @branch = Twig::Branch.new('test')
    end

    it 'removes whitespace from branch property names' do
      expect(@branch.sanitize_property('  foo bar  ')).to eq('foobar')
    end

    it 'removes underscores from branch property names' do
      expect(@branch.sanitize_property('__foo_bar__')).to eq('foobar')
    end
  end

  describe '#escaped_property_names' do
    before :each do
      @branch = Twig::Branch.new('test')
    end

    it 'converts an array of property names into an array of regexps' do
      property_names = %w[test.1 test.2]
      result = @branch.escaped_property_names(property_names)
      expect(result).to eq(%w[test\\.1 test\\.2])
    end
  end

  describe '#get_properties' do
    before :each do
      @branch = Twig::Branch.new('test')
    end

    it 'returns a hash of property names and values' do
      properties = {
        'test1' => 'value1',
        'test2' => 'value2'
      }
      git_result = [
        "branch.#{@branch}.test1 value1",
        "branch.#{@branch}.test2 value2"
      ].join("\n")
      expect(Twig).to receive(:run).
        with(%{git config --get-regexp "branch.#{@branch}.(test1|test2)$"}).
        and_return(git_result)

      result = @branch.get_properties(%w[test1 test2])
      expect(result).to eq(properties)
    end

    it 'returns properties for a branch with UTF-8 characters in its name' do
      branch     = Twig::Branch.new('utf8_{･ิω･ิ}')
      properties = { 'test1' => 'value1' }
      git_result = "branch.#{branch}.test1 value1"
      expect(Twig).to receive(:run).
        with(%{git config --get-regexp "branch.#{branch}.(test1)$"}).
        and_return(git_result)

      result = branch.get_properties(%w[test1])
      expect(result).to eq(properties)
    end

    it 'returns an empty hash if no property names are given' do
      expect(Twig).not_to receive(:run)

      result = @branch.get_properties([])
      expect(result).to eq({})
    end

    it 'returns an empty hash if no matching property names are found' do
      git_result = ''
      expect(Twig).to receive(:run).
        with(%{git config --get-regexp "branch.#{@branch}.(test1|test2)$"}).
        and_return(git_result)

      result = @branch.get_properties(%w[test1 test2])
      expect(result).to eq({})
    end

    it 'removes whitespace from property names' do
      bad_property_name = '  foo foo  '
      property_name     = 'foofoo'
      property_value    = 'bar'
      properties        = { property_name => property_value }
      git_result = "branch.#{@branch}.#{property_name} #{property_value}"
      expect(Twig).to receive(:run).
        with(%{git config --get-regexp "branch.#{@branch}.(#{property_name})$"}).
        and_return(git_result)

      result = @branch.get_properties([bad_property_name])
      expect(result).to eq(properties)
    end

    it 'excludes properties whose values are empty strings' do
      git_result = [
        "branch.#{@branch}.test1 value1",
        "branch.#{@branch}.test2"
      ].join("\n")
      expect(Twig).to receive(:run).
        with(%{git config --get-regexp "branch.#{@branch}.(test1|test2)$"}).
        and_return(git_result)

      result = @branch.get_properties(%w[test1 test2])
      expect(result).to eq('test1' => 'value1')
    end

    it 'raises an error if any property name is an empty string' do
      property_name = '  '
      expect(Twig).not_to receive(:run)

      begin
        @branch.get_properties(['test1', property_name])
      rescue Twig::Branch::EmptyPropertyNameError => exception
        expected_exception = exception
      end

      expect(expected_exception.message).to eq(
        Twig::Branch::EmptyPropertyNameError::DEFAULT_MESSAGE
      )
    end
  end

  describe '#get_property' do
    before :each do
      @branch = Twig::Branch.new('test')
    end

    it 'returns a property value' do
      property = 'test'
      value    = 'value'
      expect(@branch).to receive(:get_properties).
        with([property]).
        and_return(property => value)

      result = @branch.get_property(property)
      expect(result).to eq(value)
    end

    it 'removes whitespace from branch property names' do
      bad_property = '  foo foo  '
      property     = 'foofoo'
      value        = 'bar'
      expect(@branch).to receive(:get_properties).
        with([property]).
        and_return(property => value)

      result = @branch.get_property(bad_property)
      expect(result).to eq(value)
    end
  end

  describe '#set_property' do
    before :each do
      @branch = Twig::Branch.new('test')
    end

    it 'sets a property value' do
      property = 'test'
      value    = 'value'
      expect(Twig).to receive(:run).
        with(%{git config branch.#{@branch}.#{property} "#{value}"}) do
          `(exit 0)`; value # Set `$?` to `0`
        end

      result = @branch.set_property(property, value)
      expect(result).to include(
        %{Saved property "#{property}" as "#{value}" for branch "#{@branch}"}
      )
    end

    it 'raises an error if Git cannot set the property value' do
      property = 'test'
      value    = 'value'
      allow(Twig).to receive(:run) { `(exit 1)`; value } # Set `$?` to `1`

      begin
        @branch.set_property(property, value)
      rescue RuntimeError => exception
        expected_exception = exception
      end

      expect(expected_exception.message).to include(
        %{Could not save property "#{property}" as "#{value}" for branch "#{@branch}"}
      )
    end

    it 'raises an error if the property name is an empty string' do
      property = ' '
      value    = 'value'
      expect(Twig).not_to receive(:run)

      begin
        @branch.set_property(property, value)
      rescue Twig::Branch::EmptyPropertyNameError => exception
        expected_exception = exception
      end

      expect(expected_exception.message).to eq(
        Twig::Branch::EmptyPropertyNameError::DEFAULT_MESSAGE
      )
    end

    it 'raises an error if trying to set a reserved branch property' do
      property = 'merge'
      value    = 'NOOO'
      expect(Twig).not_to receive(:run)

      begin
        @branch.set_property(property, value)
      rescue ArgumentError => exception
        expected_exception = exception
      end

      expect(expected_exception.message).to include(
        %{Can't modify the reserved property "#{property}"}
      )
    end

    it 'raises an error if trying to set a branch property to an empty string' do
      property = 'test'
      value    = ''
      expect(Twig).not_to receive(:run)

      begin
        @branch.set_property(property, value)
      rescue ArgumentError => exception
        expected_exception = exception
      end

      expect(expected_exception.message).to include(
        %{Can't set a branch property to an empty string}
      )
    end

    it 'removes whitespace from branch property names' do
      bad_property = '  foo foo  '
      property     = 'foofoo'
      value        = 'bar'
      expect(Twig).to receive(:run).
        with(%{git config branch.#{@branch}.#{property} "#{value}"}) do
          `(exit 0)`; value # Set `$?` to `0`
        end

      result = @branch.set_property(bad_property, value)
      expect(result).to include(
        %{Saved property "#{property}" as "#{value}" for branch "#{@branch}"}
      )
    end

    it 'removes underscores from branch property names' do
      bad_property = 'foo_foo'
      property     = 'foofoo'
      value        = 'bar'
      expect(Twig).to receive(:run).
        with(%{git config branch.#{@branch}.#{property} "#{value}"}) do
          `(exit 0)`; value # Set `$?` to `0`
        end

      result = @branch.set_property(bad_property, value)
      expect(result).to include(
        %{Saved property "#{property}" as "#{value}" for branch "#{@branch}"}
      )
    end

    it 'strips whitespace from a value before setting it as a property' do
      property  = 'test'
      bad_value = '  foo  '
      value     = 'foo'
      expect(Twig).to receive(:run).
        with(%{git config branch.#{@branch}.#{property} "#{value}"}) do
          `(exit 0)`; value # Set `$?` to `0`
        end

      result = @branch.set_property(property, bad_value)
      expect(result).to include(
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
      expect(@branch).to receive(:get_property).
        with(property).and_return('value')
      expect(Twig).to receive(:run).
        with(%{git config --unset branch.#{@branch}.#{property}})

      result = @branch.unset_property(property)
      expect(result).to include(
        %{Removed property "#{property}" for branch "#{@branch}"}
      )
    end

    it 'removes whitespace from branch property names' do
      bad_property = '  foo foo  '
      property     = 'foofoo'
      expect(@branch).to receive(:get_property).
        with(property).and_return('value')
      expect(Twig).to receive(:run).
        with(%{git config --unset branch.#{@branch}.#{property}})

      result = @branch.unset_property(bad_property)
      expect(result).to include(
        %{Removed property "#{property}" for branch "#{@branch}"}
      )
    end

    it 'raises an error if the property name is an empty string' do
      bad_property = ' '
      expect(@branch).not_to receive(:get_property)
      expect(Twig).not_to receive(:run)

      begin
        @branch.unset_property(bad_property)
      rescue Twig::Branch::EmptyPropertyNameError => exception
        expected_exception = exception
      end

      expect(expected_exception.message).to eq(
        Twig::Branch::EmptyPropertyNameError::DEFAULT_MESSAGE
      )
    end

    it 'raises an error if the branch does not have the given property' do
      property = 'test'
      expect(@branch).to receive(:get_property).with(property).and_return(nil)

      begin
        @branch.unset_property(property)
      rescue Twig::Branch::MissingPropertyError => exception
        expected_exception = exception
      end

      expect(expected_exception.message).to include(
        %{The branch "#{@branch}" does not have the property "#{property}"}
      )
    end
  end

end
