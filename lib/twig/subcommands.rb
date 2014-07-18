class Twig
  module Subcommands
    BIN_PREFIX = 'twig-'

    def self.all_names
      bin_paths = []

      bin_dir_paths.each do |bin_dir_path|
        path_pattern = File.join(bin_dir_path, BIN_PREFIX + '*')
        Dir.glob(path_pattern) do |bin_path|
          bin_paths << File.basename(bin_path)
        end
      end

      bin_paths.uniq.sort.map do |bin_path|
        bin_path.sub(Regexp.new('^' << BIN_PREFIX), '')
      end
    end

    def self.bin_dir_paths
      ENV['PATH'].split(':')
    end

    def self.exec_subcommand_if_any(cli_args)
      # Run subcommand binary, if any, and exit here

      subcommand_name = cli_args[0]
      bin_name = Twig::Subcommands::BIN_PREFIX + subcommand_name
      subcommand_path = Twig.run("which #{bin_name} 2>/dev/null")
      return if subcommand_path.empty?

      subcommand_args = cli_args[1..-1]
      command = ([subcommand_path] + subcommand_args).join(' ')

      exec(command)
    end
  end
end
