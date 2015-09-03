require 'spec_helper'

describe Twig::CommitTime do
  before :each do
    @time = Time.utc(2000, 12, 1, 12, 00, 00)
    allow(Twig::CommitTime).to receive(:now) { @time }
  end

  describe '#initialize' do
    before :each do
      @seconds_in_a_year  = 60 * 60 * 24 * 365
      @seconds_in_a_week  = 60 * 60 * 24 * 7
      @seconds_in_a_day   = 60 * 60 * 24
      @seconds_in_an_hour = 60 * 60
    end

    it 'stores a Time object' do
      commit_time = Twig::CommitTime.new(@time)
      expect(commit_time.instance_variable_get(:@time)).to eq(@time)
    end

    it 'stores a formatted "time ago" string' do
      two_years_ago = @time - (@seconds_in_a_year * 2)
      expect(Twig::CommitTime.new(two_years_ago).
        instance_variable_get(:@time_ago)).to eq('2y ago')

      one_year_ago = @time - @seconds_in_a_year
      expect(Twig::CommitTime.new(one_year_ago).
        instance_variable_get(:@time_ago)).to eq('1y ago')

      two_months_ago = @time - (@seconds_in_a_week * 7)
      expect(Twig::CommitTime.new(two_months_ago).
        instance_variable_get(:@time_ago)).to eq('2mo ago')

      two_weeks_ago = @time - (@seconds_in_a_week * 2)
      expect(Twig::CommitTime.new(two_weeks_ago).
        instance_variable_get(:@time_ago)).to eq('2w ago')

      two_days_ago = @time - (@seconds_in_a_day * 2)
      expect(Twig::CommitTime.new(two_days_ago).
        instance_variable_get(:@time_ago)).to eq('2d ago')

      two_hours_ago = @time - (@seconds_in_an_hour * 2)
      expect(Twig::CommitTime.new(two_hours_ago).
        instance_variable_get(:@time_ago)).to eq('2h ago')

      expect(Twig::CommitTime.new(@time - 120).
        instance_variable_get(:@time_ago)).to eq('2m ago')

      expect(Twig::CommitTime.new(@time - 2).
        instance_variable_get(:@time_ago)).to eq('2s ago')

      expect(Twig::CommitTime.new(@time).
        instance_variable_get(:@time_ago)).to eq('0s ago')
    end

    it 'stores a formatted "time from now" string' do
      two_years_from_now = @time + (@seconds_in_a_year * 2)
      expect(Twig::CommitTime.new(two_years_from_now).
        instance_variable_get(:@time_ago)).to eq('2y from now')

      one_year_from_now = @time + @seconds_in_a_year
      expect(Twig::CommitTime.new(one_year_from_now).
        instance_variable_get(:@time_ago)).to eq('1y from now')

      two_months_from_now = @time + (@seconds_in_a_week * 9)
      expect(Twig::CommitTime.new(two_months_from_now).
        instance_variable_get(:@time_ago)).to eq('2mo from now')

      two_weeks_from_now = @time + (@seconds_in_a_week * 2)
      expect(Twig::CommitTime.new(two_weeks_from_now).
        instance_variable_get(:@time_ago)).to eq('2w from now')

      two_days_from_now = @time + (@seconds_in_a_day * 2)
      expect(Twig::CommitTime.new(two_days_from_now).
        instance_variable_get(:@time_ago)).to eq('2d from now')

      two_hours_from_now = @time + (@seconds_in_an_hour * 2)
      expect(Twig::CommitTime.new(two_hours_from_now).
        instance_variable_get(:@time_ago)).to eq('2h from now')

      expect(Twig::CommitTime.new(@time + 120).
        instance_variable_get(:@time_ago)).to eq('2m from now')

      expect(Twig::CommitTime.new(@time + 2).
        instance_variable_get(:@time_ago)).to eq('2s from now')
    end
  end

  describe '#count_relative_years' do
    it 'returns 0 for the actual date' do
      ref_time = @time
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_years(@time)).to eq(0)
    end

    it 'returns -1 for one year ago' do
      ref_time = @time - (60 * 60 * 24 * 365)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_years(@time)).to eq(-1)
    end

    it 'returns -2 for 21 months ago' do
      ref_time = @time - (60 * 60 * 24 * 30 * 21)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_years(@time)).to eq(-2)
    end

    it 'returns 1 for one year from now' do
      ref_time = @time + (60 * 60 * 24 * 365)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_years(@time)).to eq(1)
    end

    it 'returns 2 for 21 months from now' do
      ref_time = @time + (60 * 60 * 24 * 30 * 21)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_years(@time)).to eq(2)
    end
  end

  describe '#count_relative_months' do
    it 'returns 0 for the actual date' do
      ref_time = @time
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_months(@time)).to eq(0)
    end

    it 'returns -1 for 20 days ago' do
      ref_time = @time - (60 * 60 * 24 * 20)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_months(@time)).to eq(-1)
    end

    it 'returns -2 for 50 days ago' do
      ref_time = @time - (60 * 60 * 24 * 50)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_months(@time)).to eq(-2)
    end

    it 'returns 1 for 31 days from now' do
      days_per_month = 31
      ref_time = @time + (60 * 60 * 24 * days_per_month)

      commit_time = Twig::CommitTime.new(ref_time)

      expect(commit_time.count_relative_months(@time)).to eq(1)
    end

    it 'returns 2 for 62 days from now' do
      days_per_month = 31
      ref_time = @time + (60 * 60 * 24 * days_per_month * 2)

      commit_time = Twig::CommitTime.new(ref_time)

      expect(commit_time.count_relative_months(@time)).to eq(2)
    end
  end

  describe '#count_relative_weeks' do
    it 'returns 0 for the actual date' do
      ref_time = @time
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_weeks(@time)).to eq(0)
    end

    it 'returns -1 for 8 days ago' do
      ref_time = @time - (60 * 60 * 24 * 8)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_weeks(@time)).to eq(-1)
    end

    it 'returns -2 for 14 days ago' do
      ref_time = @time - (60 * 60 * 24 * 14)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_weeks(@time)).to eq(-2)
    end

    it 'returns -3 for 2.5 weeks ago' do
      ref_time = @time - (60 * 60 * 24 * 7 * 2.5)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_weeks(@time)).to eq(-3)
    end

    it 'returns 1 for 8 days from now' do
      ref_time = @time + (60 * 60 * 24 * 8)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_weeks(@time)).to eq(1)
    end

    it 'returns 2 for 14 days from now' do
      ref_time = @time + (60 * 60 * 24 * 14)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_weeks(@time)).to eq(2)
    end

    it 'returns 3 for 2.5 weeks from now' do
      ref_time = @time + (60 * 60 * 24 * 7 * 2.5)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_weeks(@time)).to eq(3)
    end
  end

  describe '#count_relative_days' do
    it 'returns 0 for the actual date' do
      ref_time = @time
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_days(@time)).to eq(0)
    end

    it 'returns -1 for one day ago' do
      ref_time = @time - (60 * 60 * 24)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_days(@time)).to eq(-1)
    end

    it 'returns -2 for 1.5 days ago' do
      ref_time = @time - (60 * 60 * 24 * 1.5)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_days(@time)).to eq(-2)
    end

    it 'returns 1 for one day from now' do
      ref_time = @time + (60 * 60 * 24)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_days(@time)).to eq(1)
    end

    it 'returns 2 for 1.5 days from now' do
      ref_time = @time + (60 * 60 * 24 * 1.5)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_days(@time)).to eq(2)
    end
  end

  describe '#count_relative_hours' do
    it 'returns 0 for the actual date' do
      ref_time = @time
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_days(@time)).to eq(0)
    end

    it 'returns -1 for one hour ago' do
      ref_time = @time - (60 * 60)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_hours(@time)).to eq(-1)
    end

    it 'returns -2 for 1.5 hours ago' do
      ref_time = @time - (60 * 60 * 1.5)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_hours(@time)).to eq(-2)
    end

    it 'returns 1 for one hour from now' do
      ref_time = @time + (60 * 60)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_hours(@time)).to eq(1)
    end

    it 'returns 2 for 1.5 hours from now' do
      ref_time = @time + (60 * 60 * 1.5)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_hours(@time)).to eq(2)
    end
  end

  describe '#count_relative_minutes' do
    it 'returns 0 for the actual date' do
      ref_time = @time
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_minutes(@time)).to eq(0)
    end

    it 'returns -1 for one minute ago' do
      ref_time = @time - 60
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_minutes(@time)).to eq(-1)
    end

    it 'returns -20 for 20 minutes ago' do
      ref_time = @time - (60 * 20)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_minutes(@time)).to eq(-20)
    end

    it 'returns -21 for 20.5 minutes ago' do
      ref_time = @time - (60 * 20.5)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_minutes(@time)).to eq(-21)
    end

    it 'returns 1 for one minute from now' do
      ref_time = @time + 60
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_minutes(@time)).to eq(1)
    end

    it 'returns 20 for 20 minutes from now' do
      ref_time = @time + (60 * 20)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_minutes(@time)).to eq(20)
    end

    it 'returns 21 for 20.5 minutes from now' do
      ref_time = @time + (60 * 20.5)
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_minutes(@time)).to eq(21)
    end
  end

  describe '#count_relative_seconds' do
    it 'returns 0 for the actual date' do
      ref_time = @time
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_seconds(@time)).to eq(0)
    end

    it 'returns -1 for one second ago' do
      ref_time = @time - 1
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_seconds(@time)).to eq(-1)
    end

    it 'returns -70 for one minute and 10 second ago' do
      ref_time = @time - 70
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_seconds(@time)).to eq(-70)
    end

    it 'returns 1 for one second from now' do
      ref_time = @time + 1
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_seconds(@time)).to eq(1)
    end

    it 'returns 70 for one minute and 10 seconds from now' do
      ref_time = @time + 70
      commit_time = Twig::CommitTime.new(ref_time)
      expect(commit_time.count_relative_seconds(@time)).to eq(70)
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
