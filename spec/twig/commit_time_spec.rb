require 'spec_helper'

describe Twig::CommitTime do
  before :each do
    @time = Time.utc(2000, 12, 1, 12, 00, 00)
  end

  describe '#initialize' do
    it 'stores a Time object' do
      commit_time = Twig::CommitTime.new(@time)
      expect(commit_time.instance_variable_get(:@time)).to eq(@time)
    end

    it 'stores a "time ago" string as its shortened version' do
      seconds_in_a_year = 60 * 60 * 24 * 365
      seconds_in_a_month = 60 * 60 * 24 * 31
      seconds_in_a_week = 60 * 60 * 24 * 7
      seconds_in_a_day = 60 * 60 * 24
      expect(Twig::CommitTime.new(@time).
        instance_variable_get(:@time_ago)).to eq('13y ago')
      expect(Twig::CommitTime.new(@time + ( seconds_in_a_year * 11 )).
        instance_variable_get(:@time_ago)).to eq('2y ago')
      expect(Twig::CommitTime.new(@time + ( seconds_in_a_year * 12 )).
        instance_variable_get(:@time_ago)).to eq('1y ago')

      two_months_ago = Time.new - ( 2 * seconds_in_a_month )
      expect(Twig::CommitTime.new(two_months_ago).
        instance_variable_get(:@time_ago)).to eq('2mo ago')

      two_weeks_ago = Time.new - ( 2 * seconds_in_a_week )
      expect(Twig::CommitTime.new(two_weeks_ago).
        instance_variable_get(:@time_ago)).to eq('2w ago')

      two_days_ago = Time.new - ( 2 * seconds_in_a_day )
      expect(Twig::CommitTime.new(two_days_ago).
        instance_variable_get(:@time_ago)).to eq('2d ago')

      two_hours_ago = Time.new - ( 60 * 120 )
      expect(Twig::CommitTime.new(two_hours_ago).
        instance_variable_get(:@time_ago)).to eq('2h ago')

      expect(Twig::CommitTime.new(Time.new - 120).
        instance_variable_get(:@time_ago)).to eq('2m ago')

      expect(Twig::CommitTime.new(Time.new - 2).
        instance_variable_get(:@time_ago)).to eq('2s ago')
    end
  end

  describe '#count_years' do
    it 'returns 0 for the actual date' do
      ref_time = Time.new
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_years).to eq(0)
    end

    it 'returns the years count for past dates' do
      ref_time = Time.new - (60 * 60 * 24 * 365)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_years).to eq(1)
    end
  end

  describe '#count_months' do
    it 'returns 0 for the actual date' do
      ref_time = Time.new
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_months).to eq(0)
    end

    it 'returns 1 for one month ago' do
      now = Time.new
      ref_time = Time.new - (60 * 60 * 24 * 31)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_months).to eq(1)
    end
  end

  describe '#count_weeks' do
    it 'returns 0 for the actual date' do
      ref_time = Time.new
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_weeks).to eq(0)
    end

    it 'returns 1 for 12 days ago' do
      now = Time.new
      ref_time = now - ( 12 * 60 * 60 * 24 )
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_weeks).to eq(1)
    end

    it 'returns 2 for 14 days ago' do
      now = Time.new
      ref_time = now - ( 14 * 60 * 60 * 24 )
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_weeks).to eq(2)
    end
  end

  describe '#count_days' do
    it 'returns 0 for the actual date' do
      ref_time = Time.new
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_days).to eq(0)
    end

    it 'returns 1 for one day ago' do
      now = Time.new
      ref_time = now - ( 60 * 60 * 24 )
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_days).to eq(1)
    end
  end

  describe '#count_hours' do
    it 'returns 0 for the actual date' do
      ref_time = Time.new
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_days).to eq(0)
    end

    it 'returns 1 for one hour ago' do
      now = Time.new
      ref_time = now - ( 60 * 60 )
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_hours).to eq(1)
    end
  end

  describe '#count_minutes' do
    it 'returns 0 for the actual date' do
      ref_time = Time.new
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_minutes).to eq(0)
    end

    it 'returns 1 for one minute ago' do
      now = Time.new
      ref_time = now - 60
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_minutes).to eq(1)
    end

    it 'returns 20 for 20 minute ago' do
      now = Time.new
      ref_time = now - ( 20 * 60 )
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_minutes).to eq(20)
    end
  end

  describe '#count_seconds' do
    it 'returns 0 for the actual date' do
      ref_time = Time.new
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_seconds).to eq(0)
    end

    it 'returns 1 for one second ago' do
      now = Time.new
      ref_time = now - 1
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_seconds).to eq(1)
    end

    it 'returns 70 for one minute and 10 second ago' do
      now = Time.new
      ref_time = now - 70
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
      commit_time = Twig::CommitTime.new(@time)
      result = commit_time.to_s
      expect(result).to include('2000-12-01')
      expect(result).to include('(13y ago)')
    end
  end
end
