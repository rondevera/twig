class Twig

  # Stores a branch's last commit time and its relative time representation.
  class CommitTime
    SECONDS_PER_YEAR   = 60 * 60 * 24 * 365
    SECONDS_PER_WEEK   = 60 * 60 * 24 * 7
    SECONDS_PER_DAY    = 60 * 60 * 24
    SECONDS_PER_HOUR   = 60 * 60
    SECONDS_PER_MINUTE = 60

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
        elsif months_ago > 0 && weeks_ago > 4
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
      seconds = CommitTime.now - @time
      seconds < SECONDS_PER_YEAR ? 0 : (seconds / SECONDS_PER_YEAR).round
    end

    def count_months_ago
      now = CommitTime.now
      (now.year * 12 + now.month) - (@time.year * 12 + @time.month)
    end

    def count_weeks_ago
      seconds = CommitTime.now - @time
      seconds < SECONDS_PER_WEEK ? 0 : (seconds / SECONDS_PER_WEEK).round
    end

    def count_days_ago
      seconds = CommitTime.now - @time
      seconds < SECONDS_PER_DAY ? 0 : (seconds / SECONDS_PER_DAY).round
    end

    def count_hours_ago
      seconds = CommitTime.now - @time
      seconds < SECONDS_PER_HOUR ? 0 : (seconds / SECONDS_PER_HOUR).round
    end

    def count_minutes_ago
      seconds = CommitTime.now - @time
      seconds < SECONDS_PER_MINUTE ? 0 : (seconds / SECONDS_PER_MINUTE).round
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
