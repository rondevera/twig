require 'spec_helper'

describe Twig::CommitTime do
  before :each do
    @time = Time.utc(2000, 12, 1, 12, 00, 00)
    allow(Twig::CommitTime).to receive(:now) { @time }
  end

  describe '#initialize' do
    it 'stores a Time object' do
      commit_time = Twig::CommitTime.new(@time)
      expect(commit_time.instance_variable_get(:@time)).to eq(@time)
    end

    it 'stores a "time ago" string as its shortened version' do
      seconds_in_a_year = 60 * 60 * 24 * 365
      seconds_in_a_week = 60 * 60 * 24 * 7
      seconds_in_a_day  = 60 * 60 * 24

      expect(Twig::CommitTime.new(@time - (seconds_in_a_year * 2)).
        instance_variable_get(:@time_ago)).to eq('2y ago')
      expect(Twig::CommitTime.new(@time - (seconds_in_a_year * 1)).
        instance_variable_get(:@time_ago)).to eq('1y ago')

      two_months_ago = @time - (7 * seconds_in_a_week)
      expect(Twig::CommitTime.new(two_months_ago).
        instance_variable_get(:@time_ago)).to eq('2mo ago')

      two_weeks_ago = @time - (2 * seconds_in_a_week)
      expect(Twig::CommitTime.new(two_weeks_ago).
        instance_variable_get(:@time_ago)).to eq('2w ago')

      two_days_ago = @time - (2 * seconds_in_a_day)
      expect(Twig::CommitTime.new(two_days_ago).
        instance_variable_get(:@time_ago)).to eq('2d ago')

      two_hours_ago = @time - (60 * 120)
      expect(Twig::CommitTime.new(two_hours_ago).
        instance_variable_get(:@time_ago)).to eq('2h ago')

      expect(Twig::CommitTime.new(@time - 120).
        instance_variable_get(:@time_ago)).to eq('2m ago')

      expect(Twig::CommitTime.new(@time - 2).
        instance_variable_get(:@time_ago)).to eq('2s ago')

      expect(Twig::CommitTime.new(@time).
        instance_variable_get(:@time_ago)).to eq('0s ago')
    end
  end

  describe '#count_years_ago' do
    it 'returns 0 for the actual date' do
      ref_time = @time
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_years_ago).to eq(0)
    end

    it 'returns 1 for one year ago' do
      ref_time = @time - (60 * 60 * 24 * 365)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_years_ago).to eq(1)
    end

    it 'returns 2 for 21 months ago' do
      ref_time = @time - (60 * 60 * 24 * 30 * 21)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_years_ago).to eq(2)
    end
  end

  describe '#count_months_ago' do
    it 'returns 0 for the actual date' do
      ref_time = @time
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_months_ago).to eq(0)
    end

    it 'returns 1 for 20 days ago' do
      ref_time = @time - (60 * 60 * 24 * 20)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_months_ago).to eq(1)
    end

    it 'returns 2 for 50 days ago' do
      ref_time = @time - (60 * 60 * 24 * 50)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_months_ago).to eq(2)
    end
  end

  describe '#count_weeks_ago' do
    it 'returns 0 for the actual date' do
      ref_time = @time
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_weeks_ago).to eq(0)
    end

    it 'returns 1 for 8 days ago' do
      ref_time = @time - (60 * 60 * 24 * 8)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_weeks_ago).to eq(1)
    end

    it 'returns 2 for 14 days ago' do
      ref_time = @time - (60 * 60 * 24 * 14)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_weeks_ago).to eq(2)
    end

    it 'returns 3 for 2.5 weeks ago' do
      ref_time = @time - (60 * 60 * 24 * 7 * 2.5)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_weeks_ago).to eq(3)
    end
  end

  describe '#count_days' do
    it 'returns 0 for the actual date' do
      ref_time = @time
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_days).to eq(0)
    end

    it 'returns 1 for one day ago' do
      ref_time = @time - (60 * 60 * 24)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_days).to eq(1)
    end

    it 'returns 2 for 1.5 days ago' do
      ref_time = @time - (60 * 60 * 24 * 1.5)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_days).to eq(2)
    end
  end

  describe '#count_hours' do
    it 'returns 0 for the actual date' do
      ref_time = @time
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_days).to eq(0)
    end

    it 'returns 1 for one hour ago' do
      ref_time = @time - (60 * 60)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_hours).to eq(1)
    end

    it 'returns 2 for 1.5 hours ago' do
      ref_time = @time - (60 * 60 * 1.5)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_hours).to eq(2)
    end
  end

  describe '#count_minutes' do
    it 'returns 0 for the actual date' do
      ref_time = @time
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_minutes).to eq(0)
    end

    it 'returns 1 for one minute ago' do
      ref_time = @time - 60
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_minutes).to eq(1)
    end

    it 'returns 20 for 20 minutes ago' do
      ref_time = @time - (60 * 20)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_minutes).to eq(20)
    end

    it 'returns 21 for 20.5 minutes ago' do
      ref_time = @time - (60 * 20.5)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_minutes).to eq(21)
    end
  end

  describe '#count_seconds' do
    it 'returns 0 for the actual date' do
      ref_time = @time
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_seconds).to eq(0)
    end

    it 'returns 1 for one second ago' do
      ref_time = @time - 1
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_seconds).to eq(1)
    end

    it 'returns 70 for one minute and 10 second ago' do
      ref_time = @time - 70
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_seconds).to eq(70)
    end
  end

  describe '#to_i' do
    it 'returns the time as an integer' do
      commit_time = Twig::CommitTime.new(@time)
      expect(commit_time.to_i).to eq(@time.to_i)
    end
  end

  describe '#to_s' do
    it 'returns a formatted string, including time ago' do
      ref_time = @time - (60 * 60)
      commit_time = Twig::CommitTime.new(ref_time)

      result = commit_time.to_s

      expect(result).to include('2000-12-01')
      expect(result).to include('(1h ago)')
    end
  end
end
