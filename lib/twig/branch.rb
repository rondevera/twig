class Twig
  class Branch

    RESERVED_BRANCH_PROPERTIES    = %w[merge rebase remote]
    PROPERTY_NAME_FROM_GIT_CONFIG = /^branch\.[^.]+\.([^=]+)=.*$/

    attr_accessor :name, :last_commit_time

    def self.all_properties
      @_all_properties ||= begin
        config_lines = Twig.run('git config --list').split("\n")

        properties = config_lines.map do |line|
          # Split by rightmost `=`, allowing branch names to contain `=`:
          key, value = line.match(/(.+)=(.+)/)[1..2]

          key_parts = key.split('.')
          key_parts.last if key_parts[0] == 'branch' && key_parts.size > 2
        end.compact

        properties.uniq.sort - RESERVED_BRANCH_PROPERTIES
      end
    end

    def initialize(name, attrs = {})
      self.name = name
      raise ArgumentError, '`name` is required' if name.empty?

      self.last_commit_time = attrs[:last_commit_time]
    end

    def to_s ; name ; end

    def sanitize_property(property_name)
      property_name.gsub(/[ _]+/, '')
    end

    def get_property(property_name)
      Twig.run("git config branch.#{name}.#{property_name}")
    end

    def set_property(property_name, value)
      property_name = sanitize_property(property_name)
      value = value.to_s

      if RESERVED_BRANCH_PROPERTIES.include?(property_name)
        %{Can't modify the reserved property "#{property_name}".}
      else
        Twig.run(%{git config branch.#{name}.#{property_name} "#{value}"})
        result_body = %{property "#{property_name}" as "#{value}" for branch "#{name}".}
        if $?.success?
          "Saved #{result_body}"
        else
          "Could not save #{result_body}"
        end
      end
    end

    def unset_property(property_name)
      property = get_property(property_name)
      if property && !property.empty?
        Twig.run(%{git config --unset branch.#{name}.#{property_name}})
        %{Removed property "#{property_name}" for branch "#{name}".}
      else
        %{The branch "#{name}" does not have the property "#{property_name}".}
      end
    end

  end
end
