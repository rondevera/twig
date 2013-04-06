class Twig
  module Display
    COLORS = {
      :black  => 30,
      :red    => 31,
      :green  => 32,
      :yellow => 33,
      :blue   => 34,
      :purple => 35,
      :cyan   => 36,
      :white  => 37
    }
    WEIGHTS = {
      :normal => 0,
      :bold   => 1
    }
    CURRENT_BRANCH_INDICATOR        = '* '
    EMPTY_BRANCH_PROPERTY_INDICATOR = '-'

    def column(string, options = {})
      # Returns `string` with an exact fixed width. If `string` is too wide, it
      # is truncated with an ellipsis and a trailing space to separate columns.
      #
      # `options`:
      # - `:color`:  `nil` by default. Accepts a key from `COLORS`.
      # - `:weight`: `nil` by default. Accepts a key from `WEIGHTS`.
      # - `:width`:  8 (characters) by default.

      string ||= ' '
      width      = options[:width] || 8
      new_string = string[0, width]
      omission   = '... '

      if string.size >= width
        new_string[-omission.size, omission.size] = omission
      else
        new_string = ' ' * width
        new_string[0, string.size] = string
      end

      new_string = format_string(
        new_string,
        options.reject { |k, v| ![:color, :weight].include?(k) }
      )

      new_string
    end

    def branch_list_headers(header_options = {})
      date_time_column_width = 40
      property_column_width  = 16
      branch_indicator_padding = ' ' * CURRENT_BRANCH_INDICATOR.size

      header_options.merge!(
        header_options.inject({}) do |opts, (key, value)|
          if key == :header_color
            opts[:color] = value
          elsif key == :header_weight
            opts[:weight] = value
          end
          opts
        end
      ).merge!(:width => property_column_width)

      out =
        column(' ', :width => date_time_column_width) <<
        Twig::Branch.all_properties.map do |property|
          column(property, header_options)
        end.join <<
        column(branch_indicator_padding + 'branch', header_options) <<
        "\n"
      out <<
        column(' ', :width => date_time_column_width) <<
        Twig::Branch.all_properties.map do |property|
          column('-' * property.size, header_options)
        end.join <<
        column(branch_indicator_padding + '------', header_options) <<
        "\n"

      out
    end

    def branch_list_line(branch)
      is_current_branch = branch.name == current_branch_name
      date_time_column_width = 40
      property_column_width  = 16

      properties = Twig::Branch.all_properties.inject({}) do |result, property_name|
        property = (get_branch_property(branch.name, property_name) || '').strip
        property = column(EMPTY_BRANCH_PROPERTY_INDICATOR) if property.empty?
        property.gsub!(/[\n\r]+/, ' ')
        result.merge(property_name => property)
      end

      line = column(branch.last_commit_time.to_s, :width => date_time_column_width)

      line <<
        Twig::Branch.all_properties.map do |property_name|
          property = properties[property_name] || ''
          column(property, :width => property_column_width)
        end.join

      line <<
        if is_current_branch
          CURRENT_BRANCH_INDICATOR + branch.to_s
        else
          (' ' * CURRENT_BRANCH_INDICATOR.size) + branch.to_s
        end

      line = format_string(line, :weight => :bold) if is_current_branch

      line
    end

    def format_string(string, options)
      # Options:
      # - `:color`:  `nil` by default. Accepts a key from `COLORS`.
      # - `:weight`: `nil` by default. Accepts a key from `WEIGHTS`.

      string_options = []
      string_options << COLORS[options[:color]] if options[:color]
      string_options << WEIGHTS[options[:weight]] if options[:weight]
      return string if string_options.empty?

      "\e[#{string_options.join(';')}m#{string}\e[0m"
    end

    def unformat_string(string)
      string.gsub(/\e\[[0-9]+(;[0-9]+)?m/, '')
    end
  end # module Display
end
