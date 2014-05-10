class Twig

  # Stores a branch's last commit time and its relative time representation.
  class CommitTime
    def initialize(time)
      @time = time
      suffix = 'ago'

      if count_years > 0
        @time_ago = "#{count_years}y #{suffix}"
        return
      end

      if count_months > 0 and count_weeks > 4
        @time_ago = "#{count_months}mo #{suffix}"
        return
      end

      if count_weeks > 0
        @time_ago = "#{count_weeks}w #{suffix}"
        return
      end

      if count_days > 0
        @time_ago = "#{count_days}d #{suffix}"
        return
      end

      if count_hours > 0
        @time_ago = "#{count_hours}h #{suffix}"
        return
      end

      if count_minutes > 0
        @time_ago = "#{count_minutes}m #{suffix}"
        return
      end

      @time_ago = "#{count_seconds}s #{suffix}"
    end

    def count_years
      seconds_in_a_year = 60 * 60 * 24 * 365
      seconds = (Time.now - @time).to_i
      seconds < seconds_in_a_year ? 0 : (seconds / seconds_in_a_year).floor
    end

    def count_months
      now = Time.new
      (now.year * 12 + now.month) - (@time.year * 12 + @time.month)
    end

    def count_weeks
      seconds_in_a_week = 60 * 60 * 24 * 7
      seconds = (Time.now - @time).to_i
      seconds < seconds_in_a_week ? 0 : (seconds / seconds_in_a_week).floor
    end

    def count_days
      seconds_in_a_day = 60 * 60 * 24
      seconds = (Time.now - @time).to_i
      seconds < seconds_in_a_day ? 0 : (seconds / seconds_in_a_day).floor
    end

    def count_hours
      seconds_in_an_hour = 60 * 60
      seconds = (Time.now - @time).to_i
      seconds < seconds_in_an_hour ? 0 : (seconds / seconds_in_an_hour).floor
    end

    def count_minutes
      seconds_in_a_minute = 60
      seconds = (Time.now - @time).to_i
      seconds < seconds_in_a_minute ? 0 : (seconds / seconds_in_a_minute).floor
    end

    def count_seconds
      (Time.now - @time).to_i
    end

    def to_i
      @time.to_i
    end

    def to_s
      time_string = @time.strftime('%F %R %z')
      "#{time_string} (#{@time_ago})"
    end

    def iso8601
      @time.iso8601
    end

    def <=>(other)
      to_i <=> other.to_i
    end
  end
end
