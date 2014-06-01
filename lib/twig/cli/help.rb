class Twig
  module Cli
    # Handles printing help output for `twig help`.
    module Help
      def self.intro
        version_string = "Twig v#{Twig::VERSION}"

        intro = Help.paragraph(%{
          Twig is your personal Git branch assistant. It's a command-line tool
          for listing your most recent branches, and for remembering branch
          details for you, like issue tracker ids and todos. It also supports
          subcommands, like automatically fetching statuses from your issue
          tracking system.
        })

        intro = <<-BANNER.gsub(/^[ ]+/, '')

          #{version_string}
          #{'=' * version_string.size}

          #{intro}

          #{Twig::HOMEPAGE}
        BANNER

        intro + ' ' # Force extra blank line
      end

      def self.description(text, options = {})
        defaults = {
          :add_blank_line => false,
          :width => 40
        }
        options = defaults.merge(options)

        width = options[:width]
        words = text.gsub(/\n?\s+/, ' ').strip.split(' ')
        lines = []

        # Split words into lines
        while words.any?
          current_word      = words.shift
          current_word_size = Display.unformat_string(current_word).size
          last_line         = lines.last
          last_line_size    = last_line && Display.unformat_string(last_line).size

          if last_line_size && (last_line_size + current_word_size + 1 <= width)
            last_line << ' ' << current_word
          elsif current_word_size >= width
            lines << current_word[0...width]
            words.unshift(current_word[width..-1])
          else
            lines << current_word
          end
        end

        lines << ' ' if options[:add_blank_line]
        lines
      end

      def self.description_for_custom_property(option_parser, desc_lines, options = {})
        options[:trailing] ||= "\n"
        indent = '      '
        left_column_width = 29

        help_desc = desc_lines.inject('') do |desc, (left_column, right_column)|
          desc + indent +
          sprintf("%-#{left_column_width}s", left_column) + right_column + "\n"
        end

        Help.separator(option_parser, help_desc, :trailing => options[:trailing])
      end

      def self.line_for_custom_property?(line)
        is_custom_property_except = (
          line.include?('--except-') &&
          !line.include?('--except-branch') &&
          !line.include?('--except-property') &&
          !line.include?('--except-PROPERTY')
        )
        is_custom_property_only = (
          line.include?('--only-') &&
          !line.include?('--only-branch') &&
          !line.include?('--only-property') &&
          !line.include?('--only-PROPERTY')
        )
        is_custom_property_width = (
          line =~ /--.+-width/ &&
          !line.include?('--branch-width') &&
          !line.include?('--PROPERTY-width')
        )

        is_custom_property_except ||
        is_custom_property_only ||
        is_custom_property_width
      end

      def self.paragraph(text)
        Help.description(text, :width => 80).join("\n")
      end

      def self.print_paragraph(option_parser, text, separator_options = {})
        # Prints a long chunk of text with automatic word wrapping and a leading
        # line break.

        defaults = { :trailing => '' }
        separator_options = defaults.merge(separator_options)

        Help.separator(option_parser, Help.paragraph(text), separator_options)
      end

      def self.separator(option_parser, text, options = {})
        options[:trailing] ||= "\n\n"
        option_parser.separator "\n#{text}#{options[:trailing]}"
      end

      def self.subheader(option_parser, text, separator_options = {})
        Help.separator(
          option_parser,
          text + "\n" + ('-' * text.size),
          separator_options
        )
      end
    end
  end
end