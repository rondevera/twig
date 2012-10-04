class Twig
  module Options
    CONFIG_FILE = '~/.twigrc'

    def read_config_file
      config_file_path = File.expand_path(Twig::CONFIG_FILE)
      return unless File.readable?(config_file_path)

      File.open(config_file_path) do |f|
        opts = f.read.split("\n").inject({}) do |hsh, opt|
          key, value = opt.split(':', 2)
          hsh.merge(key.strip => value.strip)
        end

        opts.each do |key, value|
          case key
          when 'b', 'branch'  then set_option(:branch,       value)
          when 'max-days-old' then set_option(:max_days_old, value)
          when 'only-name'    then set_option(:name_only,    value)
          when 'except-name'  then set_option(:name_except,  value)
          end
        end
      end
    end

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
