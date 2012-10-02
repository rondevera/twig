require 'spec_helper'

describe Twig::CommitTime do
  before :each do
    @timestamp = Time.utc(2000, 12, 1, 12, 00, 00).to_i
  end

  describe '#initialize' do
    it 'stores a timestamp as a Time object' do
      commit_time = Twig::CommitTime.new(@timestamp, '99 days ago')
      commit_time.instance_variable_get(:@time).to_i.should == @timestamp
    end

    it 'stores a "time ago" string as its shortened version' do
      Twig::CommitTime.new(@timestamp, '2 years ago').
        instance_variable_get(:@time_ago).should == '2y ago'
      Twig::CommitTime.new(@timestamp, '2 months ago').
        instance_variable_get(:@time_ago).should == '2mo ago'
      Twig::CommitTime.new(@timestamp, '2 weeks ago').
        instance_variable_get(:@time_ago).should == '2w ago'
      Twig::CommitTime.new(@timestamp, '2 days ago').
        instance_variable_get(:@time_ago).should == '2d ago'
      Twig::CommitTime.new(@timestamp, '2 hours ago').
        instance_variable_get(:@time_ago).should == '2h ago'
      Twig::CommitTime.new(@timestamp, '2 minutes ago').
        instance_variable_get(:@time_ago).should == '2m ago'
      Twig::CommitTime.new(@timestamp, '2 seconds ago').
        instance_variable_get(:@time_ago).should == '2s ago'
    end
  end

  describe '#to_i' do
    it 'returns the time as an integer' do
      commit_time = Twig::CommitTime.new(@timestamp, '99 days ago')
      commit_time.to_i.should == @timestamp.to_i
    end
  end

  describe '#to_s' do
    it 'returns a formatted string, including time ago' do
      commit_time = Twig::CommitTime.new(@timestamp, '99 days ago')
      result = commit_time.to_s
      result.should include('2000-12-01')
      result.should include('(99d ago)')
    end
  end
end
