class Twig

  # Represents a Git branch.
  class Branch
    PARENT_PROPERTY = 'diff-branch'
    PROPERTY_NAME_FROM_GIT_CONFIG  = /^branch\.[^.]+\.([^=]+)=.*$/
    RESERVED_BRANCH_PROPERTY_NAMES = %w[branch merge property rebase remote]

    class EmptyPropertyNameError < ArgumentError
      DEFAULT_MESSAGE = 'Branch property names cannot be empty strings.'
      def initialize(message = nil)
        message ||= DEFAULT_MESSAGE
        super
      end
    end
    class MissingPropertyError < StandardError; end

    attr_accessor :name, :last_commit_time

    def self.all_branches
      @_all_branches ||= begin
        branch_tuples = Twig.
          run(%{git for-each-ref #{ REF_PREFIX } --format="#{ REF_FORMAT }"}).
          split("\n")

        branch_tuples.inject([]) do |result, branch_tuple|
          name, time_string = branch_tuple.split(REF_FORMAT_SEPARATOR)
          time        = Time.parse(time_string)
          commit_time = Twig::CommitTime.new(time)
          branch      = Branch.new(name, :last_commit_time => commit_time)
          result << branch
        end
      end
    end

    def self.all_branch_names
      @_all_branch_names ||= all_branches.map { |branch| branch.name }
    end

    def self.all_property_names
      @_all_property_names ||= begin
        config_lines = Twig.run('git config --list').split("\n")

        properties = config_lines.map do |line|
          # Split by rightmost `=`, allowing branch names to contain `=`
          match_data = line.match(/(.+)=(.+)/)
          key, value = match_data[1..2] if match_data
          next unless key

          key_parts = key.split('.')
          key_parts.last if key_parts[0] == 'branch' && key_parts.size > 2
        end.compact

        properties.uniq.sort - RESERVED_BRANCH_PROPERTY_NAMES
      end
    end

    def self.validate_property_name(property_name)
      raise EmptyPropertyNameError if property_name.empty?
    end

    def initialize(name, attrs = {})
      self.name = name
      raise ArgumentError, '`name` is required' if name.empty?

      self.last_commit_time = attrs[:last_commit_time]
    end

    def to_s ; name ; end

    def to_hash(property_names)
      {
        'name' => name,
        'last-commit-time' => last_commit_time.iso8601,
        'properties' => get_properties(property_names)
      }
    end

    def parent_name
      get_property(PARENT_PROPERTY)
    end

    def sanitize_property(property_name)
      property_name.gsub(/[ _]+/, '')
    end

    def escaped_property_names(property_names)
      property_names.map do |property_name|
        property_name = sanitize_property(property_name)
        Branch.validate_property_name(property_name)
        Regexp.escape(property_name)
      end
    end

    def get_properties(property_names)
      return {} if property_names.empty?

      property_names_regexp = escaped_property_names(property_names).join('|')
      git_config_regexp     = "branch\.#{name}\.(#{ property_names_regexp })$"
      cmd = %{git config --get-regexp "#{git_config_regexp}"}

      git_result = Twig.run(cmd) || ''
      git_result_lines = git_result.split("\n")

      git_result_lines.inject({}) do |properties, line|
        match_data = line.match(/^branch\.#{Regexp.escape(name)}\.([^\s]+)\s+(.*)$/)

        if match_data
          property_name = match_data[1]
          property_value = match_data[2]
        else
          property_value = ''
        end

        if property_value.empty?
          properties
        else
          properties.merge(property_name => property_value)
        end
      end
    end

    def get_property(property_name)
      property_name = sanitize_property(property_name)
      get_properties([property_name])[property_name]
    end

    def set_property(property_name, value)
      property_name = sanitize_property(property_name)
      value = value.to_s.strip
      Branch.validate_property_name(property_name)

      if RESERVED_BRANCH_PROPERTY_NAMES.include?(property_name)
        raise ArgumentError,
          %{Can't modify the reserved property "#{property_name}".}
      elsif value.empty?
        raise ArgumentError,
          %{Can't set a branch property to an empty string.}
      else
        git_config = "branch.#{name}.#{property_name}"
        Twig.run(%{git config #{git_config} "#{value}"})
        result_body = %{property "#{property_name}" as "#{value}" for branch "#{name}".}
        if $?.success?
          "Saved #{result_body}"
        else
          raise RuntimeError, "Could not save #{result_body}"
        end
      end
    end

    def unset_property(property_name)
      property_name = sanitize_property(property_name)
      Branch.validate_property_name(property_name)

      value = get_property(property_name)

      if value
        git_config = "branch.#{name}.#{property_name}"
        Twig.run(%{git config --unset #{git_config}})
        %{Removed property "#{property_name}" for branch "#{name}".}
      else
        raise MissingPropertyError,
          %{The branch "#{name}" does not have the property "#{property_name}".}
      end
    end
  end
end
