require 'optparse'
require File.expand_path(File.join(File.dirname(__FILE__), 'display'))

class Twig
  module Cli
    include Display

    def help_intro
      version_string = "Twig v#{Twig::VERSION}"

      <<-BANNER.gsub(/^[ ]+/, '')

        #{version_string}
        #{'-' * version_string.size}

        Twig is your personal Git branch assistant. It shows you your most
        recent branches, and tracks issue tracker ids, tasks, and other metadata
        for your Git branches.

        https://rondevera.github.com/twig

      BANNER
    end

    def help_separator(option_parser, text)
      option_parser.separator "\n#{text}\n\n"
    end

    def help_description(text, options={})
      width = options[:width] || 40
      text  = text.gsub(/\n?\s+/, ' ').strip.split(' ')

      # Split into lines
      lines = []

      # returns a text's lenght without shell color codes
      printable_size = lambda {|t| t.gsub(/\033\[[0-9]+(;[0-9]+)?m/, '').size }

      until text.empty?
        current = text.shift
        if lines.last &&
          (printable_size[lines.last] + printable_size[current] + 1) < width

          lines.last << ' ' << current
        else
          lines << current
        end
      end

      lines << ' ' if options[:add_separator]
      lines
    end

    def read_cli_options!(args)
      option_parser = OptionParser.new do |opts|
        opts.banner         = help_intro
        opts.summary_indent = ' ' * 2
        opts.summary_width  = 32



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
          puts opts; exit
        end

        desc = 'Show Twig version.'
        opts.on('--version', *help_description(desc)) do
          puts Twig::VERSION; exit
        end



        help_separator(opts, 'Filtering branches:')

        desc = 'Only list branches whose name matches a given pattern.'
        opts.on(
          '--only-branch PATTERN',
          *help_description(desc, :add_separator => true)
        ) do |pattern|
          set_option(:branch_only, pattern)
        end

        desc = 'Do not list branches whose name matches a given pattern.'
        opts.on(
          '--except-branch PATTERN',
          *help_description(desc, :add_separator => true)
        ) do |pattern|
          set_option(:branch_except, pattern)
        end

        desc = 'Only list branches below a given age.'
        opts.on(
          '--max-days-old AGE', *help_description(desc, :add_separator => true)
        ) do |age|
          set_option(:max_days_old, age)
        end

        desc =
          'Lists all branches regardless of age or name options. ' +
          'Useful for overriding options in ' +
          File.basename(Twig::Options::CONFIG_FILE) + '.'
        opts.on('--all', *help_description(desc)) do |pattern|
          unset_option(:max_days_old)
          unset_option(:branch_except)
          unset_option(:branch_only)
        end

        colors = COLORS.keys.map do |value|
          format_string(value, { :color => value })
        end.join(', ')
        weights = WEIGHTS.keys.map do |value|
          format_string(value, { :weight => value })
        end.join(' and ')
        desc = <<-TXT
          STYLE has to be at least one color or weight or one of each, separated
          by a space. Valid colors are #{colors}. Valid weights are #{weights}.
          The default is "#{format_string('blue normal', { :color => :blue })}".
        TXT
        opts.on('--header-style "STYLE"', *help_description(desc)) do |style|
          set_option(:header_style, style)
        end

        help_separator(opts, [
          'You can put your most frequently used branch filtering options in',
          "#{Twig::Options::CONFIG_FILE}. For example:",
          '',
          '      except-branch: staging',
          '      max-days-old:  30'
        ].join("\n"))
      end

      option_parser.parse!(args)
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument => exception
      puts exception.to_s
      puts 'For a list of options, run `twig --help`.'
      exit
    end

    def read_cli_args!(args)
      if args.any?
        # Run subcommand binary, if any, and exit here
        possible_subcommand_name = args[0]
        command_path = Twig.run("which twig-#{possible_subcommand_name}")
        unless command_path.empty?
          command = ([command_path] + args[1..-1]).join(' ')
          exec(command)
        end
      end

      read_cli_options!(args)
      branch_name = options[:branch] || current_branch_name
      property_to_unset = options.delete(:unset_property)

      # Handle remaining arguments, if any
      if args.any?
        property_name, property_value = args[0], args[1]

        read_cli_options!(args)

        # Get/set branch property
        if property_value
          # `$ twig <key> <value>`
          puts set_branch_property(branch_name, property_name, property_value)
        else
          # `$ twig <key>`
          value = get_branch_property(branch_name, property_name)
          if value && !value.empty?
            puts value
          else
            puts %{The branch "#{branch_name}" does not have the property "#{property_name}".}
          end
        end
      elsif property_to_unset
        # `$ twig --unset <key>`
        puts unset_branch_property(branch_name, property_to_unset)
      else
        # `$ twig`
        puts list_branches
      end
    end

  end
end
