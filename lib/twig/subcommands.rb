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
  end
end
