class Twig
  module System

    def self.windows?
      RbConfig::CONFIG['host_os'] =~ /(windows|win32)/
    end

  end
end
