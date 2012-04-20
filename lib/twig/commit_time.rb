module Twig
  class CommitTime

    def initialize(git_time_string)
      time_string, time_ago = git_time_string.split(',')
      @time = Time.at(time_string.to_i)

      # Shorten relative time
      @time_ago = time_ago.
        sub(' years',   'y').
        sub(' months',  'mo').
        sub(' weeks',   'w').
        sub(' days',    'd').
        sub(' hours',   'h').
        sub(' minutes', 'm').
        sub(' seconds', 's')
    end

    def to_i
      @time.to_i
    end

    def to_s
      time_string = @time.strftime('%F %R %z')
      "#{time_string} (#{@time_ago})"
    end

  end
end
