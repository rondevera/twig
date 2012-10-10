class Twig
  module Cli

    def read_cli_options(args)
      option_parser = OptionParser.new do |opts|
        desc = 'Use specific branch'
        opts.on('-b BRANCH', '--branch BRANCH', desc) do |branch|
          set_option(:branch, branch)
        end

        desc = 'Only list branches below a given age'
        opts.on('--max-days-old AGE', desc) do |age|
          set_option(:max_days_old, age)
        end

        desc = 'Only list branches whose name matches a given pattern'
        opts.on('--only-name PATTERN', desc) do |pattern|
          set_option(:name_only, pattern)
        end

        desc = 'Do not list branches whose name matches a given pattern'
        opts.on('--except-name PATTERN', desc) do |pattern|
          set_option(:name_except, pattern)
        end

        desc = 'Lists all branches regardless of age or name options; ' +
          'useful for overriding ' + File.basename(Twig::Options::CONFIG_FILE)
        opts.on('--all', desc) do |pattern|
          unset_option(:max_days_old)
          unset_option(:name_except)
          unset_option(:name_only)
        end

        desc = 'Show version'
        opts.on_tail('--version', desc) do
          puts Twig::VERSION
          exit
        end
      end

      option_parser.parse!(args)
    end

  end
end
