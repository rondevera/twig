class Twig
  module Options
    def set_option(key, value)
      case key
      when :branch
        if branches.include?(value)
          options[:branch] = value
        else
          abort %{The branch "#{value}" could not be found.}
        end
      when :max_days_old
        if Twig::Util.numeric?(value)
          options[:max_days_old] = value.to_f
        else
          abort %{The value `--max-days-old=#{value}` is invalid.}
        end
      when :name_only
        options[:name_only] = Regexp.new(value)
      when :name_except
        options[:name_except] = Regexp.new(value)
      end
    end

    def unset_option(key)
      options.delete(key)
    end
  end # module Options
end
