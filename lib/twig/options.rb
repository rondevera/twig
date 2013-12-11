class Twig
  module Options

    CONFIG_PATH = '~/.twigconfig'
    DEPRECATED_CONFIG_PATH = '~/.twigrc'
    MIN_PROPERTY_WIDTH = 3

    def readable_config_file_path
      config_path = File.expand_path(CONFIG_PATH)

      if File.exists?(config_path)
        unless File.readable?(config_path)
          $stderr.puts "Warning: #{CONFIG_PATH} is not readable."
          return # Stop if file exists but is not readable
        end
      else
        config_path = File.expand_path(DEPRECATED_CONFIG_PATH)

        if File.exists?(config_path)
          if File.readable?(config_path)
            $stderr.puts "DEPRECATED: #{DEPRECATED_CONFIG_PATH} is deprecated. " <<
              "Please rename it to #{CONFIG_PATH}."
          else
            $stderr.puts "DEPRECATED: #{DEPRECATED_CONFIG_PATH} is deprecated. " <<
              "Please rename it to #{CONFIG_PATH} and make it readable."
            return # Stop if file exists but is not readable
          end
        else
          return # Stop if neither file exists
        end
      end

      config_path
    end

    def parse_config_file(config_path)
      lines = []

      File.open(config_path) do |file|
        lines = file.read.split("\n")
      end

      lines.inject({}) do |opts, line|
        line = line.strip
        next opts if line =~ /^#/

        key, value = line.split(':', 2)
        key = key ? key.strip : ''

        if !key.empty? && value
          opts[key] = value.strip
        elsif !line.empty?
          $stderr.puts %{Warning: Invalid line "#{line}" in #{config_path}. } <<
            %{Expected format: `key: value`}
        end

        opts
      end
    end

    def read_config_file!
      config_path = readable_config_file_path
      return unless config_path

      options = parse_config_file(config_path)
      options.each do |key, value|
        case key

        # Displaying branches:
        when 'format'
          set_option(:format, value)
        when 'except-property'
          set_option(:property_except_name, value)
        when 'header-style'
          set_option(:header_style, value)
        when 'reverse'
          set_option(:reverse, value)
        when /-width$/
          property_name = key.sub(/-width$/, '').to_sym
          set_option(:property_width, property_name => value)

        # Filtering branches:
        when 'branch'
          set_option(:branch, value)
        when 'max-days-old'
          set_option(:max_days_old, value)
        when /^except-/
          property_name = key.sub(/^except-/, '').to_sym
          set_option(:property_except, property_name => value)
        when /^only-/
          property_name = key.sub(/^only-/, '').to_sym
          set_option(:property_only, property_name => value)

        # GitHub integration:
        when 'github-api-uri-prefix'
          set_option(:github_api_uri_prefix, value)
        when 'github-uri-prefix'
          set_option(:github_uri_prefix, value)

        end
      end
    end

    def set_option(key, value)
      case key
      when :branch
        if all_branch_names.include?(value)
          options[:branch] = value
        else
          abort %{The branch `#{value}` could not be found.}
        end

      when :format
        if value == 'json'
          options[:format] = value.to_sym
        else
          abort %{The format `#{value}` is not supported; only `json` is supported.}
        end

      when :github_api_uri_prefix, :github_uri_prefix
        options[key] = value

      when :header_style
        set_header_style_option(value)

      when :max_days_old
        if Twig::Util.numeric?(value)
          options[:max_days_old] = value.to_f
        else
          abort %{The value `--max-days-old=#{value}` is invalid.}
        end

      when :property_except, :property_only
        property_hash = value.inject({}) do |hsh, (property, val)|
          hsh.merge(property => Regexp.new(val))
        end
        options[key] ||= {}
        options[key].merge!(property_hash)

      when :property_except_name, :property_only_name
        options[key] = Regexp.new(value)

      when :property_width
        set_property_width_option(value)

      when :reverse
        options[:reverse] = Twig::Util.truthy?(value)

      when :unset_property
        options[key] = value
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
      options[:property_width] ||= {}

      value.each do |property_name, property_value|
        unless Twig::Util.numeric?(property_value)
          abort %{The value `--#{property_name}-width=#{property_value}` is invalid.}
        end

        property_name_width = property_name.to_s.size
        property_value = property_value.to_i
        min_property_value = [property_name_width, MIN_PROPERTY_WIDTH].max

        if property_value < min_property_value
          min_desc = if property_value < property_name_width
            %{#{property_name_width} (width of "#{property_name}")}
          else
            %{#{MIN_PROPERTY_WIDTH}}
          end

          error = %{The value `--#{property_name}-width=#{property_value}` } +
            %{is too low. The minimum is #{min_desc}.}

          abort error
        end

        options[:property_width][property_name] = property_value
      end
    end

    def unset_option(key)
      options.delete(key)
    end

  end # module Options
end
