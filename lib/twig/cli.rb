require 'optparse'

class Twig
  module Cli

    def read_cli_options(args)
      option_parser = OptionParser.new do |opts|
        desc = 'Use specific branch'
        opts.on('-b BRANCH', '--branch BRANCH', desc) do |branch|
          set_option(:branch, branch)
        end

        desc = 'Only list branches whose name matches a given pattern'
        opts.on('--only-branch PATTERN', desc) do |pattern|
          set_option(:branch_only, pattern)
        end

        desc = 'Do not list branches whose name matches a given pattern'
        opts.on('--except-branch PATTERN', desc) do |pattern|
          set_option(:branch_except, pattern)
        end

        desc = 'Only list branches below a given age'
        opts.on('--max-days-old AGE', desc) do |age|
          set_option(:max_days_old, age)
        end

        desc = 'Lists all branches regardless of age or name options; ' +
          'useful for overriding ' + File.basename(Twig::Options::CONFIG_FILE)
        opts.on('--all', desc) do |pattern|
          unset_option(:max_days_old)
          unset_option(:branch_except)
          unset_option(:branch_only)
        end

        desc = 'Show version'
        opts.on_tail('--version', desc) do
          puts Twig::VERSION
          exit
        end

        # Deprecated:

        desc = 'Deprecated. Use `--only-branch` instead.'
        opts.on('--only-name PATTERN', desc) do |pattern|
          puts "\n`--only-name` is deprecated. Please use `--only-branch` instead.\n"
          set_option(:branch_only, pattern)
        end

        desc = 'Deprecated. Use `--except-branch` instead.'
        opts.on('--except-name PATTERN', desc) do |pattern|
          puts "\n`--except-name` is deprecated. Please use `--except-branch` instead.\n"
          set_option(:branch_except, pattern)
        end
      end

      option_parser.parse!(args)
    end

    def read_cli_args(args)
      if args[0]
        # Run command binary, if any, and exit here
        command_path = Twig.run("which twig-#{args[0]}")
        exec(command_path) unless command_path.empty?

        # Get/set branch property
        branch_name = options[:branch] || current_branch_name
        if args[1]
          # `$ twig <key> <value>`
          puts set_branch_property(branch_name, args[0], args[1])
        else
          # `$ twig <key>`
          puts get_branch_property(branch_name, args[0])
        end
      else
        # `$ twig`
        puts list_branches
      end
    end

  end
end
