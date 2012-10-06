class Twig
  class Branch

    attr_accessor :name, :last_commit_time

    def initialize(name, attrs = {})
      self.name = name
      raise ArgumentError, '`name` is required' if name.empty?

      if attrs.has_key?(:last_commit_time)
        if attrs[:last_commit_time].is_a?(CommitTime)
          self.last_commit_time = attrs[:last_commit_time]
        else
          raise ArgumentError,
            '`:last_commit_time` should be a `Twig::CommitTime`'
        end
      end
    end

  end
end
