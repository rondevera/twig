class Twig
  class Branch

    attr_accessor :twig, :name

    def initialize(twig, name)
      self.twig = twig
      raise ArgumentError, '`twig` is required' unless twig.respond_to?(:repo?)

      self.name = name
      raise ArgumentError, '`name` is required' if name.empty?
    end

    def to_s ; name ; end

    def last_commit_time
      twig.last_commit_times_for_branches[name]
    end

  end
end
