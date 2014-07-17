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

    def self.exec_subcommand_if_any(args)
      # Run subcommand binary, if any, and exit here
      possible_subcommand_name = Twig::Subcommands::BIN_PREFIX + args[0]
      command_path = Twig.run("which #{possible_subcommand_name} 2>/dev/null")
      unless command_path.empty?
        command = ([command_path] + args[1..-1]).join(' ')
        exec(command)
      end
    end
  end
end
