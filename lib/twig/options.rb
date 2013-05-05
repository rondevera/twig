class Twig
  module Options

    CONFIG_FILE = '~/.twigrc'
    MIN_PROPERTY_WIDTH = 3

    def read_config_file!
      config_file_path = File.expand_path(Twig::CONFIG_FILE)
      return unless File.readable?(config_file_path)

      File.open(config_file_path) do |f|
        opts = f.read.split("\n").inject({}) do |hsh, line|
          line = line.strip

          if line !~ /^#/
            key, value = line.split(':', 2)
            hsh[key.strip] = value.strip if key && value
          end

          hsh
        end

        opts.each do |key, value|
          case key

          # Filtering branches:
          when 'branch'        then set_option(:branch,       value)
          when 'max-days-old'  then set_option(:max_days_old, value)
          when /^except-/
            property_name = key.sub(/^except-/, '').to_sym
            set_option(:property_except, property_name => value)
          when /^only-/
            property_name = key.sub(/^only-/, '').to_sym
            set_option(:property_only, property_name => value)

          # Displaying branches:
          when 'header-style'  then set_option(:header_style,  value)
          when /-width$/
            property_name = key.sub(/-width$/, '').to_sym
            set_option(:property_width, property_name => value)

          end
        end
      end
    end

    def set_option(key, value)
      case key
      when :branch
        if all_branch_names.include?(value)
          options[:branch] = value
        else
          abort %{The branch "#{value}" could not be found.}
        end

      when :header_style
        set_header_style_option(value)

      when :max_days_old
        if Twig::Util.numeric?(value)
          options[:max_days_old] = value.to_f
        else
          abort %{The value `--max-days-old=#{value}` is invalid.}
        end

      when :property_except
        property_hash = value.inject({}) do |hsh, (property, val)|
          hsh.merge(property => Regexp.new(val))
        end
        options[:property_except] ||= {}
        options[:property_except].merge!(property_hash)

      when :property_only
        property_hash = value.inject({}) do |hsh, (property, val)|
          hsh.merge(property => Regexp.new(val))
        end
        options[:property_only] ||= {}
        options[:property_only].merge!(property_hash)

      when :property_width
        set_property_width_option(value)

      when :unset_property
        options[:unset_property] = value
      end
    end

    def set_header_style_option(value)
      style_values = value.split(/\s+/).map(&:to_sym)
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
    end

    def set_property_width_option(value)
      value.each do |property_name, property_value|
        unless Twig::Util.numeric?(property_value)
          abort %{The value `--#{property_name}-width=#{property_value}` is invalid.}
        end

        property_value = property_value.to_i
        min_width = [MIN_PROPERTY_WIDTH, property_name.to_s.size].max
        if property_value < min_width
          abort %{The value `--#{property_name}-width=#{property_value}` is too low.}
        end

        options[:property_width] ||= {}
        options[:property_width].merge!(property_name => property_value)
      end
    end

    def unset_option(key)
      options.delete(key)
    end

  end # module Options
end
