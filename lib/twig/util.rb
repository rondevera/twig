module Twig
  module Util

    def self.numeric?(value)
      !!Float(value) rescue false
    end

    def self.hash_slice(hsh, wanted_keys)
      hsh.inject({}) do |h, (k, v)|
        h[k] = v if wanted_keys.include?(k)
        h
      end
    end

  end
end
