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

    def column(string = ' ', num_columns = 1, column_options = {})
      # Returns `string` with an exact fixed width. If `string` is too wide, it
      # is truncated with an ellipsis and a trailing space to separate columns.
      #
      # `column_options`:
      # - `:color`:  `nil` by default. Accepts a key from `COLORS`.
      # - `:weight`: `nil` by default. Accepts a key from `WEIGHTS`.
      # - `:width`:  8 (characters) by default.

      width_per_column = column_options[:width] || 8
      total_width = num_columns * width_per_column
      new_string = string[0, total_width]
      omission = '... '

      if string.size > total_width
        # Replace final characters with omission
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

    def branch_list_headers
      header_options = {:color => :blue}

      out =
        column(' ', 5) <<
        branch_properties.map { |prop| column(prop, 2, header_options) }.join <<
        column('  branch', 1, header_options) <<
        "\n"
      out <<
        column(' ', 5) <<
        branch_properties.
          map { |prop| column('-' * prop.size, 2, header_options) }.join <<
        column('  ------', 1, header_options) <<
        "\n"

      out
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
