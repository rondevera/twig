class Twig
  class Branch

    PROPERTY_NAME_FROM_GIT_CONFIG = /^branch\.[^.]+\.([^=]+)/

    attr_accessor :twig, :name

    def self.all_properties
      @_all_properties ||= begin
        properties = Twig.run('git config --list').split("\n").
                        map do |var|
                          match_data = PROPERTY_NAME_FROM_GIT_CONFIG.match(var)
                          match_data[1] if match_data
                        end.compact
        properties.uniq.sort - Twig::RESERVED_BRANCH_PROPERTIES
      end
    end

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
