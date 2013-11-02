require 'spec_helper'

describe Twig::CommitTime do
  before :each do
    @time = Time.utc(2000, 12, 1, 12, 00, 00)
  end

  describe '#initialize' do
    it 'stores a Time object' do
      commit_time = Twig::CommitTime.new(@time, '99 days ago')
      expect(commit_time.instance_variable_get(:@time)).to eq(@time)
    end

    it 'stores a "time ago" string as its shortened version' do
      expect(Twig::CommitTime.new(@time, '2 years, 2 months ago').
        instance_variable_get(:@time_ago)).to eq('2y ago')
      expect(Twig::CommitTime.new(@time, '2 years ago').
        instance_variable_get(:@time_ago)).to eq('2y ago')
      expect(Twig::CommitTime.new(@time, '2 months ago').
        instance_variable_get(:@time_ago)).to eq('2mo ago')
      expect(Twig::CommitTime.new(@time, '2 weeks ago').
        instance_variable_get(:@time_ago)).to eq('2w ago')
      expect(Twig::CommitTime.new(@time, '2 days ago').
        instance_variable_get(:@time_ago)).to eq('2d ago')
      expect(Twig::CommitTime.new(@time, '2 hours ago').
        instance_variable_get(:@time_ago)).to eq('2h ago')
      expect(Twig::CommitTime.new(@time, '2 minutes ago').
        instance_variable_get(:@time_ago)).to eq('2m ago')
      expect(Twig::CommitTime.new(@time, '2 seconds ago').
        instance_variable_get(:@time_ago)).to eq('2s ago')
    end
  end

  describe '#to_i' do
    it 'returns the time as an integer' do
      commit_time = Twig::CommitTime.new(@time, '99 days ago')
      expect(commit_time.to_i).to eq(@time.to_i)
    end
  end

  describe '#to_s' do
    it 'returns a formatted string, including time ago' do
      commit_time = Twig::CommitTime.new(@time, '99 days ago')
      result = commit_time.to_s
      expect(result).to include('2000-12-01')
      expect(result).to include('(99d ago)')
    end
  end
end
