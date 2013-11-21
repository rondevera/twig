class Twig
  module System

    def self.windows?
      RbConfig::CONFIG['host_os'] =~ /(cygwin|mingw|windows|win32)/
    end

  end
end
