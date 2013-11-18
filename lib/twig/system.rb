class Twig
  module System

    def self.windows?
      RbConfig::CONFIG['host_os'] =~ /win32/
    end

  end
end
