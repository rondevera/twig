class Twig
  module Subcommands

    def self.all_names
      bin_paths = []

      bin_dir_paths.each do |bin_dir_path|
        path_pattern = File.join(bin_dir_path, 'twig-*')
        Dir.glob(path_pattern) do |bin_path|
          bin_paths << File.basename(bin_path)
        end
      end

      bin_paths.uniq.sort.map do |bin_path|
        bin_path.sub(/^twig-/, '')
      end
    end

    def self.bin_dir_paths
      ENV['PATH'].split(':')
    end

  end
end
