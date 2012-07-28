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
      # Returns `string` with an exact fixed width. If `string` is too wide,
      # it's truncated with an ellipsis.
      #
      # Options:
      # - `:color`: `nil` by default. Accepts a key from `COLORS`.
      # - `:bold`:  `nil` by default. Set `true` for bold text.

      width_per_column = 8
      total_width = num_columns * width_per_column
      new_string = string[0, total_width]
      omission = '...'

      if string.size > total_width
        # Replace final characters with omission
        new_string[-omission.size, omission.size] = omission
      else
        new_string = ' ' * total_width
        new_string[0, string.size] = string
      end

      if column_options[:color] || column_options[:bold]
        color_options = [COLORS[column_options[:color]]]
        color_options << WEIGHTS[:bold] if column_options[:bold]
        new_string = "\033[#{color_options.join(';')}m#{new_string}\033[0m"
      end

      new_string
    end
  end # module Display
end
