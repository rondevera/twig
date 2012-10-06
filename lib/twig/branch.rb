class Twig
  class Branch

    RESERVED_BRANCH_PROPERTIES    = %w[merge remote]
    PROPERTY_NAME_FROM_GIT_CONFIG = /^branch\.[^.]+\.([^=]+)/

    attr_accessor :twig, :name

    def self.all_properties
      @_all_properties ||= begin
        properties = Twig.run('git config --list').split("\n").
                        map do |var|
                          match_data = PROPERTY_NAME_FROM_GIT_CONFIG.match(var)
                          match_data[1] if match_data
                        end.compact
        properties.uniq.sort - RESERVED_BRANCH_PROPERTIES
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

    def get_property(property_name)
      Twig.run("git config branch.#{name}.#{property_name}")
    end

    def set_property(property_name, value)
      value = value.to_s

      if RESERVED_BRANCH_PROPERTIES.include?(property_name)
        %{Can't modify the reserved property "#{property_name}".}
      elsif value.empty?
        Twig.run(%{git config --unset branch.#{name}.#{property_name}})
        %{Removed property "#{property_name}" for branch "#{name}".}
      else
        Twig.run(%{git config branch.#{name}.#{property_name} "#{value}"})
        %{Saved property "#{property_name}" as "#{value}" for branch "#{name}".}
      end
    end

  end
end
