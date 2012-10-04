class Twig
  module Util

    def self.numeric?(value)
      !!Float(value) rescue false
    end

  end
end
