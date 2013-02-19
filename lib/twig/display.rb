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

    def column(string = ' ', num_columns = 1, column_options = {})
      # Returns `string` with an exact fixed width. If `string` is too wide, it
      # is truncated with an ellipsis and a trailing space to separate columns.
      #
      # `column_options`:
      # - `:color`:  `nil` by default. Accepts a key from `COLORS`.
      # - `:weight`: `nil` by default. Accepts a key from `WEIGHTS`.
      # - `:width`:  8 (characters) by default.

      width_per_column = column_options[:width] || 8
      total_width      = num_columns * width_per_column
      new_string       = string[0, total_width]
      omission         = '... '

      if string.size >= total_width
        new_string[-omission.size, omission.size] = omission
      else
        new_string = ' ' * total_width
        new_string[0, string.size] = string
      end

      new_string = format_string(
        new_string,
        column_options.reject { |k, v| ![:color, :weight].include?(k) }
      )

      new_string
    end

    def branch_list_headers(header_options = { :color => :blue })
      columns_for_date_time    = 5
      columns_per_property     = 2
      branch_indicator_padding = ' ' * CURRENT_BRANCH_INDICATOR.size
      header_options = header_options.merge(
        header_options.reduce({}) do |m,(k,v)|
          if k == :header_color
            m[:color] = v
          elsif k == :header_weight
            m[:weight] = v
          else
            m[k] = v
          end
          m
        end)

      out =
        column(' ', columns_for_date_time) <<
        Twig::Branch.all_properties.map do |property|
          column(property, columns_per_property, header_options)
        end.join <<
        column(branch_indicator_padding + 'branch',
          columns_per_property, header_options) <<
        "\n"
      out <<
        column(' ', columns_for_date_time) <<
        Twig::Branch.all_properties.map do |property|
          column('-' * property.size, columns_per_property, header_options)
        end.join <<
        column(branch_indicator_padding + '------',
          columns_per_property, header_options) <<
        "\n"

      out
    end

    def branch_list_line(branch)
      is_current_branch = branch.name == current_branch_name

      properties = Twig::Branch.all_properties.inject({}) do |result, property_name|
        property = get_branch_property(branch.name, property_name).strip
        property = column(EMPTY_BRANCH_PROPERTY_INDICATOR) if property.empty?
        property.gsub!(/[\n\r]+/, ' ')
        result.merge(property_name => property)
      end

      line = column(branch.last_commit_time.to_s, 5)

      line <<
        Twig::Branch.all_properties.map do |property_name|
          property = properties[property_name] || ''
          column(property, 2)
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

      "\033[#{string_options.join(';')}m#{string}\033[0m"
    end
  end # module Display
end
