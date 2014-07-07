class Twig

  # Stores a branch's last commit time and its relative time representation.
  class CommitTime
    def self.now
      Time.now
    end

    def initialize(time)
      @time = time
      suffix = 'ago'

      # Cache calculations against current time
      years_ago   = count_years_ago
      months_ago  = count_months_ago
      weeks_ago   = count_weeks_ago
      days_ago    = count_days_ago
      hours_ago   = count_hours_ago
      minutes_ago = count_minutes_ago
      seconds_ago = count_seconds_ago

      @time_ago =
        if years_ago > 0
          "#{years_ago}y"
        elsif months_ago > 0 and weeks_ago > 4
          "#{months_ago}mo"
        elsif weeks_ago > 0
          "#{weeks_ago}w"
        elsif days_ago > 0
          "#{days_ago}d"
        elsif hours_ago > 0
          "#{hours_ago}h"
        elsif minutes_ago > 0
          "#{minutes_ago}m"
        else
          "#{seconds_ago}s"
        end
      @time_ago << ' ' << suffix
    end

    def count_years_ago
      seconds_in_a_year = 60 * 60 * 24 * 365
      seconds = CommitTime.now - @time
      seconds < seconds_in_a_year ? 0 : (seconds / seconds_in_a_year).round
    end

    def count_months_ago
      now = CommitTime.now
      (now.year * 12 + now.month) - (@time.year * 12 + @time.month)
    end

    def count_weeks_ago
      seconds_in_a_week = 60 * 60 * 24 * 7
      seconds = CommitTime.now - @time
      seconds < seconds_in_a_week ? 0 : (seconds / seconds_in_a_week).round
    end

    def count_days_ago
      seconds_in_a_day = 60 * 60 * 24
      seconds = CommitTime.now - @time
      seconds < seconds_in_a_day ? 0 : (seconds / seconds_in_a_day).round
    end

    def count_hours_ago
      seconds_in_an_hour = 60 * 60
      seconds = CommitTime.now - @time
      seconds < seconds_in_an_hour ? 0 : (seconds / seconds_in_an_hour).round
    end

    def count_minutes_ago
      seconds_in_a_minute = 60
      seconds = CommitTime.now - @time
      seconds < seconds_in_a_minute ? 0 : (seconds / seconds_in_a_minute).round
    end

    def count_seconds_ago
      (CommitTime.now - @time).to_i
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
