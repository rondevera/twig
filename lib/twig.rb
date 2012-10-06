Dir[File.join(File.dirname(__FILE__), 'twig', '*')].each { |file| require file }

class Twig
  include Display
  include Options

  RESERVED_BRANCH_PROPERTIES = %w[merge remote]

  attr_accessor :options

  def self.run(command)
    `#{command}`.strip
  end

  def initialize(options = {})
    # Options:
    # - :max_days_old (integer)
    # - :name_except (Regexp)
    # - :name_only (Regexp)

    self.options = options
  end

  def repo?
    Twig.run('git rev-parse')
    $?.success?
  end

  def current_branch
    @_current_branch ||=
      Twig.run('git symbolic-ref -q HEAD').sub(%r{^refs/heads/}, '')
  end

  def branch_names
    @_branch_names ||= begin
      refs = Twig.run('git for-each-ref --format="%(refname)" refs/heads/').split("\n")
      refs.map! { |ref| ref.sub!('refs/heads/', '') }.sort!

      # Filter branches by name
      if options[:name_only]
        refs = refs.select { |ref| ref =~ options[:name_only] }
      end
      if options[:name_except]
        refs = refs.reject { |ref| ref =~ options[:name_except] }
      end

      refs
    end
  end
  alias :branches :branch_names # FIXME: Migrate from `:branches` to `:branch_names`

  def all_branch_properties
    @_all_branch_properties ||= begin
      properties = Twig.run('git config --list').split("\n").
                      select { |var| var =~ /^branch\./ }.
                      map do |var|
                        match_data = /^branch\.[^.]+\.([^=]+)/.match(var)
                        match_data[1] if match_data
                      end
      properties.uniq.compact.sort - RESERVED_BRANCH_PROPERTIES
    end
  end

  def last_commit_time_for_branch(branch)
    last_commit_times_for_branches[branch]
  end

  def last_commit_times_for_branches
    @_last_commit_times ||= begin
      time_strings = Twig.
        run(%{git show #{branches.join(' ')} --format="%ct,%cr" -s}).
        split("\n").
        map { |time_string| time_string.strip }.
        reject { |time_string| time_string.empty? }

      commit_times = time_strings.map do |time_string|
        timestamp, time_ago = time_string.split(',')
        timestamp = timestamp.to_i
        Twig::CommitTime.new(timestamp, time_ago)
      end

      Hash[*branches.zip(commit_times).flatten]
    end
  end



  ### Actions ###

  def list_branches
    now = Time.now
    max_seconds_old =
      options[:max_days_old] ? options[:max_days_old] * 86400 : nil

    out = "\n" << branch_list_headers

    branches = branch_names.map do |branch_name|
      last_commit_time = last_commit_time_for_branch(branch_name)
      seconds_old      = now.to_i - last_commit_time.to_i

      if !max_seconds_old || seconds_old <= max_seconds_old
        Branch.new(branch_name, :last_commit_time => last_commit_time)
      end
    end.compact

    # List most recently modified branches first
    branches = branches.sort_by { |branch| branch.last_commit_time }.reverse

    branch_lines = branches.inject([]) do |result, branch|
      result + [branch_list_line(branch.name, branch.last_commit_time)]
    end

    out << branch_lines.join("\n")
  end

  def get_branch_property(branch, property)
    Twig.run("git config branch.#{branch}.#{property}")
  end

  def set_branch_property(branch, property, value)
    # Sets the given value for the given property under the current branch.
    # Returns a confirmation string for printing.

    value = value.to_s

    if RESERVED_BRANCH_PROPERTIES.include?(property)
      %{Can't modify the reserved property "#{property}".}
    elsif value.empty?
      Twig.run(%{git config --unset branch.#{branch}.#{property}})
      %{Removed property "#{property}" for branch "#{branch}".}
    else
      Twig.run(%{git config branch.#{branch}.#{property} "#{value}"})
      %{Saved property "#{property}" as "#{value}" for branch "#{branch}".}
    end
  end

end
