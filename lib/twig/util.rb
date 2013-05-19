class Twig
  module Util

    def self.numeric?(value)
      !!Float(value) rescue false
    end

    def self.truthy?(value)
      %w[true yes y on 1].include?(value.to_s.downcase)
    end

  end
end
