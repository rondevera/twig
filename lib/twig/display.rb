class Twig

  # Handles displaying matching branches as a command-line table or as
  # serialized data.
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
    DEFAULT_PROPERTY_COLUMN_WIDTH = 16
    DEFAULT_BRANCH_COLUMN_WIDTH   = 48
    CURRENT_BRANCH_INDICATOR        = '* '
    EMPTY_BRANCH_PROPERTY_INDICATOR = '-'

    def self.unformat_string(string)
      # Returns a copy of the given string without color/weight markers.
      string.gsub(/\e\[[0-9]+(;[0-9]+)?m/, '')
    end

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
      omission   = '...'

      if string.size > width
        new_string[-omission.size, omission.size] = omission
      else
        new_string = ' ' * width
        new_string[0, string.size] = string
      end

      new_string = format_string(
        new_string,
        options.reject { |key, value| ![:color, :weight].include?(key) }
      )

      new_string
    end

    def date_time_column_width; 35; end
    def column_gutter; '  '; end

    def property_column_width(property_name = nil)
      if property_name && options[:property_width]
        width = options[:property_width][property_name.to_sym]
      end

      if width
        width
      elsif property_name == :branch
        Twig::Display::DEFAULT_BRANCH_COLUMN_WIDTH
      else
        Twig::Display::DEFAULT_PROPERTY_COLUMN_WIDTH
      end
    end

    def branch_list_headers(header_options = {})
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
      )

      out = column(' ', :width => date_time_column_width) << column_gutter
      out << property_names.map do |property|
        width = property_column_width(property)
        column(property, header_options.merge(:width => width)) << column_gutter
      end.join
      out << column(branch_indicator_padding + 'branch', header_options)
      out << "\n"

      out << column(' ', :width => date_time_column_width) << column_gutter
      out << property_names.map do |property|
        width = property_column_width(property)
        underline = '-' * property.size
        column(underline, header_options.merge(:width => width)) << column_gutter
      end.join
      out << column(branch_indicator_padding + '------', header_options)
      out << "\n"

      out
    end

    def branch_list_line(branch)
      is_current_branch = branch.name == current_branch_name

      properties = branch.get_properties(property_names)
      properties = property_names.inject({}) do |result, property_name|
        property_value = (properties[property_name] || '').strip
        property_value = EMPTY_BRANCH_PROPERTY_INDICATOR if property_value.empty?
        property_value.gsub!(/[\n\r]+/, ' ')
        result.merge(property_name => property_value)
      end

      line = column(branch.last_commit_time.to_s, :width => date_time_column_width)
      line << column_gutter

      line <<
        property_names.map do |property_name|
          property_value = properties[property_name] || ''
          width = property_column_width(property_name)
          column(property_value, :width => width) << column_gutter
        end.join

      branch_column_width = property_column_width(:branch)
      branch_column = column(branch.to_s, :width => branch_column_width)
      branch_column.strip! # Strip final column
      line <<
        if is_current_branch
          CURRENT_BRANCH_INDICATOR + branch_column
        else
          (' ' * CURRENT_BRANCH_INDICATOR.size) + branch_column
        end

      line = format_string(line, :weight => :bold) if is_current_branch

      line
    end

    def branches_json
      require 'json'

      data = {
        'branches' => branches.map { |branch| branch.to_hash(property_names) }
      }
      data.to_json
    end

    def format_strings?
      !Twig::System.windows?
    end

    def format_string(string, options)
      # Options:
      # - `:color`:  `nil` by default. Accepts a key from `COLORS`.
      # - `:weight`: `nil` by default. Accepts a key from `WEIGHTS`.

      # Unlike `::unformat_string`, this is an instance method so that it can
      # handle config options, e.g., globally disabling color.

      return string unless format_strings?

      string_options = []
      string_options << COLORS[options[:color]] if options[:color]
      string_options << WEIGHTS[options[:weight]] if options[:weight]
      return string if string_options.empty?

      open_format  = "\e[#{string_options.join(';')}m"
      close_format = "\e[0m"

      open_format + string.to_s + close_format
    end
  end
end
