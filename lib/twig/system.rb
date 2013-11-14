class Twig
  module System

    def self.windows?
      RUBY_PLATFORM =~ /win32/
    end

  end
end
