require 'optparse'
require 'rbconfig'

class Twig
  module Cli
    def self.prompt_with_choices(prompt, choices)
      # Prints the given string `prompt` and the array `choices` numbered, and
      # prompts the user to enter a number. Returns the matching value, or nil
      # if the user input is invalid.

      raise ArgumentError, 'At least two choices required' if choices.size < 2

      puts prompt
      choices.each_with_index do |choice, index|
        puts "#{sprintf('%3s', index + 1)}. #{choice}"
      end
      print '> '

      input = $stdin.gets.to_i
      choices[input - 1]
    end

    def help_intro
      version_string = "Twig v#{Twig::VERSION}"

      intro = help_paragraph(%{
        Twig is your personal Git branch assistant. It's a command-line tool for
        listing your most recent branches, and for remembering branch details
        for you, like issue tracker ids and todos. It also supports subcommands,
        like automatically fetching statuses from your issue tracking system.
      })

      intro = <<-BANNER.gsub(/^[ ]+/, '')

        #{version_string}
        #{'-' * version_string.size}

        #{intro}

        #{Twig::HOMEPAGE}
      BANNER

      intro + ' ' # Force extra blank line
    end

    def help_separator(option_parser, text, options = {})
      options[:trailing] ||= "\n\n"
      option_parser.separator "\n#{text}#{options[:trailing]}"
    end

    def help_description(text, options = {})
      width = options[:width] || 40
      words = text.gsub(/\n?\s+/, ' ').strip.split(' ')
      lines = []

      # Split words into lines
      while words.any?
        current_word      = words.shift
        current_word_size = unformat_string(current_word).size
        last_line         = lines.last
        last_line_size    = last_line && unformat_string(last_line).size

        if last_line_size && (last_line_size + current_word_size + 1 <= width)
          last_line << ' ' << current_word
        elsif current_word_size >= width
          lines << current_word[0...width]
          words.unshift(current_word[width..-1])
        else
          lines << current_word
        end
      end

      lines << ' ' if options[:add_separator]
      lines
    end

    def help_description_for_custom_property(option_parser, desc_lines, options = {})
      options[:trailing] ||= "\n"
      indent = '      '
      left_column_width = 29

      help_desc = desc_lines.inject('') do |desc, (left_column, right_column)|
        desc + indent +
        sprintf("%-#{left_column_width}s", left_column) + right_column + "\n"
      end

      help_separator(option_parser, help_desc, :trailing => options[:trailing])
    end

    def help_paragraph(text)
      help_description(text, :width => 80).join("\n")
    end

    def help_line_for_custom_property?(line)
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

    def run_pager
      # Starts a pager so that all following STDOUT output is paginated.
      # Based on: http://nex-3.com/posts/73-git-style-automatic-paging-in-ruby

      return if Twig::System.windows? || !$stdout.tty?

      read_io, write_io = IO.pipe

      # Create child process
      unless Kernel.fork
        # The following runs only in the child process:
        $stdout.reopen(write_io)
        $stderr.reopen(write_io) if $stderr.tty?
        read_io.close
        write_io.close
        return
      end

      $stdin.reopen(read_io)
      read_io.close
      write_io.close

      ENV['LESS'] = 'FSRX'      # Don't page if the input fits on screen
      Kernel.select([$stdin])   # Wait for input before starting pager

      # Turn parent process into pager
      pager = ENV['PAGER'] || 'less'
      exec pager rescue exec '/bin/sh', '-c', pager
    end

    def read_cli_options!(args)
      custom_properties = Twig::Branch.all_property_names

      option_parser = OptionParser.new do |opts|
        opts.banner         = help_intro
        opts.summary_indent = ' ' * 2
        opts.summary_width  = 32

        ###

        help_separator(opts, 'Common options:')

        desc = 'Use a specific branch.'
        opts.on(
          '-b BRANCH', '--branch BRANCH', *help_description(desc)
        ) do |branch|
          set_option(:branch, branch)
        end

        desc = 'Unset a branch property.'
        opts.on('--unset PROPERTY', *help_description(desc)) do |property_name|
          set_option(:unset_property, property_name)
        end

        desc = 'Show this help content.'
        opts.on('--help', *help_description(desc)) do
          summary_lines = opts.to_s.split("\n")
          run_pager

          # Filter out custom property lines
          prev_line = nil
          summary_lines.each do |line|
            # Squash successive blank lines
            next if line == "\n" && prev_line == "\n"

            unless help_line_for_custom_property?(line)
              puts line
              prev_line = line
            end
          end

          exit
        end

        desc = 'Show Twig version.'
        opts.on('--version', *help_description(desc)) do
          puts Twig::VERSION
          exit
        end

        ###

        help_separator(opts, 'Filtering branches:')

        desc = 'Only list branches below a given age.'
        opts.on(
          '--max-days-old AGE', *help_description(desc, :add_separator => true)
        ) do |age|
          set_option(:max_days_old, age)
        end

        desc = 'Only list branches whose name matches a given pattern.'
        opts.on(
          '--only-branch PATTERN',
          *help_description(desc, :add_separator => true)
        ) do |pattern|
          set_option(:property_only, :branch => pattern)
        end

        desc = 'Do not list branches whose name matches a given pattern.'
        opts.on('--except-branch PATTERN', *help_description(desc)) do |pattern|
          set_option(:property_except, :branch => pattern)
        end

        custom_properties.each do |property_name|
          property_name_sym = property_name.to_sym

          opts.on("--only-#{property_name} PATTERN") do |pattern|
            set_option(:property_only, property_name_sym => pattern)
          end

          opts.on("--except-#{property_name} PATTERN") do |pattern|
            set_option(:property_except, property_name_sym => pattern)
          end
        end
        help_description_for_custom_property(opts, [
          ['--only-PROPERTY PATTERN',   'Only list branches with a given property'],
          ['',                          'that matches a given pattern.']
        ], :trailing => '')
        help_description_for_custom_property(opts, [
          ['--except-PROPERTY PATTERN', 'Do not list branches with a given property'],
          ['',                          'that matches a given pattern.']
        ])

        desc =
          'Print branch properties in a format that can be used by other ' +
          'tools. Currently, the only supported value is `json`.'
        opts.on(
          '--format FORMAT', *help_description(desc, :add_separator => true)
        ) do |format|
          set_option(:format, format)
        end

        desc =
          'Lists all branches regardless of other filtering options. ' +
          'Useful for overriding options in ' +
          File.basename(Twig::Options::CONFIG_PATH) + '.'
        opts.on('--all', *help_description(desc)) do |pattern|
          unset_option(:max_days_old)
          unset_option(:property_except)
          unset_option(:property_only)
        end

        ###

        help_separator(opts, 'Listing branches:')

        desc = <<-DESC
          Set the width for the `branch` column.
          (Default: #{Twig::DEFAULT_BRANCH_COLUMN_WIDTH})
        DESC
        opts.on('--branch-width NUMBER', *help_description(desc)) do |width|
          set_option(:property_width, :branch => width)
        end

        custom_properties.each do |property_name|
          opts.on("--#{property_name}-width NUMBER") do |width|
            set_option(:property_width, property_name.to_sym => width)
          end
        end
        help_description_for_custom_property(opts, [
          ['--PROPERTY-width NUMBER', "Set the width for a given property's column."],
          ['',                        "(Default: #{Twig::DEFAULT_PROPERTY_COLUMN_WIDTH})"]
        ])

        desc = <<-DESC
          Only include properties where the property name matches the given
          regular expression.
        DESC
        opts.on(
          '--only-property PATTERN',
          *help_description(desc, :add_separator => true)
        ) do |pattern|
          set_option(:property_only_name, pattern)
        end

        desc = <<-DESC
          Exclude properties where the property name matches the given regular
          expression.
        DESC
        opts.on(
          '--except-property PATTERN',
          *help_description(desc, :add_separator => true)
        ) do |pattern|
          set_option(:property_except_name, pattern)
        end

        colors = Twig::Display::COLORS.keys.
          map { |value| format_string(value, :color => value) }.
          join(',')
        weights = Twig::Display::WEIGHTS.keys.
          map { |value| format_string(value, :weight => value) }.
          join(' and ')
        default_header_style = format_string(
          Twig::DEFAULT_HEADER_COLOR.to_s,
          :color => Twig::DEFAULT_HEADER_COLOR
        )
        desc = <<-DESC
          STYLE is a color, weight, or a space-separated pair of one of each.
          Valid colors are #{colors}. Valid weights are #{weights}.
          (Default: "#{default_header_style}")
        DESC
        opts.on(
          '--header-style "STYLE"',
          *help_description(desc, :add_separator => true)
        ) do |style|
          set_option(:header_style, style)
        end

        desc = 'Show oldest branches first. (Default: false)'
        opts.on('--reverse', *help_description(desc)) do
          set_option(:reverse, true)
        end

        ###

        help_separator(opts, 'GitHub integration:')

        desc = <<-DESC
          Set a custom GitHub API URI prefix, e.g.,
          https://github-enterprise.example.com/api/v3.
          (Default: "#{Twig::DEFAULT_GITHUB_API_URI_PREFIX}")
        DESC
        opts.on(
          '--github-api-uri-prefix PREFIX',
          *help_description(desc, :add_separator => true)
        ) do |prefix|
          set_option(:github_api_uri_prefix, prefix)
        end

        desc = <<-DESC
          Set a custom GitHub URI prefix, e.g.,
          https://github-enterprise.example.com.
          (Default: "#{Twig::DEFAULT_GITHUB_URI_PREFIX}")
        DESC
        opts.on(
          '--github-uri-prefix PREFIX',
          *help_description(desc, :add_separator => true)
        ) do |prefix|
          set_option(:github_uri_prefix, prefix)
        end

        ###

        help_separator(opts, 'Config files and tab completion:', :trailing => '')

        help_separator(opts, help_paragraph(%{
          Twig can automatically set up a config file for you, where you can put
          your most frequently used options for filtering and listing branches.
          To get started, run `twig init` and follow the instructions. This does
          two things:
        }), :trailing => '')

        help_separator(opts, help_paragraph(%{
          * Creates #{Twig::Options::CONFIG_PATH}, where you can put your
            favorite options, e.g.:
        }), :trailing => '')

        help_separator(opts, [
          '      except-branch: staging',
          '      header-style:  green bold',
          '      max-days-old:  30',
          '      reverse:       true'
        ].join("\n"), :trailing => '')

        help_separator(opts, help_paragraph(%{
          * Enables tab completion for Twig subcommands and branch names, e.g.:
        }), :trailing => '')

        help_separator(opts, [
          '      `twig cre<tab>` -> `twig create-branch`',
          '      `twig status -b my-br<tab>` -> `twig status -b my-branch`'
        ].join("\n"), :trailing => '')
      end

      option_parser.parse!(args)
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument => exception
      abort_for_option_exception(exception)
    ensure
      args
    end

    def abort_for_option_exception(exception)
      puts exception.message + "\nFor a list of options, run `twig --help`."
      exit 1
    end

    def exec_subcommand_if_any(args)
      # Run subcommand binary, if any, and exit here
      possible_subcommand_name = Twig::Subcommands::BIN_PREFIX + args[0]
      command_path = Twig.run("which #{possible_subcommand_name} 2>/dev/null")
      unless command_path.empty?
        command = ([command_path] + args[1..-1]).join(' ')
        exec(command)
      end
    end

    def read_cli_args!(args)
      exec_subcommand_if_any(args) if args.any?

      args = read_cli_options!(args)
      branch_name = target_branch_name
      format = options.delete(:format)
      property_to_unset = options.delete(:unset_property)

      # Handle remaining arguments, if any
      if args.any?
        property_name, property_value = args[0], args[1]

        read_cli_options!(args)

        # Get/set branch property
        if property_value
          # `$ twig <key> <value>`
          set_branch_property_for_cli(branch_name, property_name, property_value)
        else
          # `$ twig <key>`
          get_branch_property_for_cli(branch_name, property_name)
        end
      elsif property_to_unset
        # `$ twig --unset <key>`
        unset_branch_property_for_cli(branch_name, property_to_unset)
      elsif format == :json
        # `$ twig --format json`
        puts branches_json
      else
        # `$ twig`
        puts list_branches
      end
    end

    def get_branch_property_for_cli(branch_name, property_name)
      value = get_branch_property(branch_name, property_name)
      if value
        puts value
      else
        raise Twig::Branch::MissingPropertyError,
          %{The branch "#{branch_name}" does not have the property "#{property_name}".}
      end
    rescue ArgumentError, Twig::Branch::MissingPropertyError => exception
      abort exception.message
    end

    def set_branch_property_for_cli(branch_name, property_name, property_value)
      puts set_branch_property(branch_name, property_name, property_value)
    rescue ArgumentError, RuntimeError => exception
      abort exception.message
    end

    def unset_branch_property_for_cli(branch_name, property_name)
      puts unset_branch_property(branch_name, property_name)
    rescue ArgumentError, Twig::Branch::MissingPropertyError => exception
      abort exception.message
    end
  end
end
