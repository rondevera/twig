class Twig
  module Options

    CONFIG_FILE = '~/.twigrc'

    def read_config_file!
      config_file_path = File.expand_path(Twig::CONFIG_FILE)
      return unless File.readable?(config_file_path)

      File.open(config_file_path) do |f|
        opts = f.read.split("\n").inject({}) do |hsh, opt|
          key, value = opt.split(':', 2)
          hsh[key.strip] = value.strip if key && value
          hsh
        end

        opts.each do |key, value|
          case key
          when 'branch'        then set_option(:branch,        value)
          when 'except-branch' then set_option(:branch_except, value)
          when 'only-branch'   then set_option(:branch_only,   value)
          when 'max-days-old'  then set_option(:max_days_old,  value)
          when 'header-style'  then set_option(:header_style,  value)
          end
        end
      end
    end

    def set_option(key, value)
      case key
      when :branch
        if branch_names.include?(value)
          options[:branch] = value
        else
          abort %{The branch "#{value}" could not be found.}
        end
      when :branch_except
        options[:branch_except] = Regexp.new(value)
      when :branch_only
        options[:branch_only] = Regexp.new(value)
      when :header_style
        style_values = value.split(/\s/).map(&:to_sym)
        colors  = Twig::Display::COLORS.keys
        weights = Twig::Display::WEIGHTS.keys
        color   = nil
        weight  = nil

        style_values.each do |style_value|
          if !color && colors.include?(style_value)
            color = style_value
          elsif !weight && weights.include?(style_value)
            weight = style_value
          else
            abort %{The value `--header-style=#{value}` is invalid.}
          end
        end

        options[:header_color]  = color  if color
        options[:header_weight] = weight if weight
      when :max_days_old
        if Twig::Util.numeric?(value)
          options[:max_days_old] = value.to_f
        else
          abort %{The value `--max-days-old=#{value}` is invalid.}
        end
      when :unset_property
        options[:unset_property] = value
      end
    end

    def unset_option(key)
      options.delete(key)
    end

  end # module Options
end
