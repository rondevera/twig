class Twig

  # Stores a branch's last commit time and its relative time representation.
  class CommitTime
    def initialize(time, time_ago)
      @time = time

      # Shorten relative time
      @time_ago = time_ago.
        sub(/ years?/,  'y').
        sub(' months',  'mo').
        sub(' weeks',   'w').
        sub(' days',    'd').
        sub(' hours',   'h').
        sub(' minutes', 'm').
        sub(' seconds', 's')

      # Keep only the most significant units in the relative time
      time_ago_parts = @time_ago.split(/\s+/)
      @time_ago = "#{time_ago_parts[0]} #{time_ago_parts[-1]}".gsub(/,/, '')
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
