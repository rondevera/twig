Dir[File.join(File.dirname(__FILE__), 'twig', '*.rb')].each { |file| require file }
require 'time'

class Twig
  include Cli
  include Display
  include Options

  attr_accessor :options

  REF_FORMAT_SEPARATOR = ','
  REF_FORMAT = %w[refname:short committerdate committerdate:relative].
                map { |field| '%(' + field + ')' }.join(REF_FORMAT_SEPARATOR)
  REF_PREFIX = 'refs/heads/'
  DEFAULT_HEADER_COLOR = :blue

  def self.run(command)
    `#{command}`.strip
  end

  def initialize
    self.options = {}

    # Set defaults
    set_option(:header_style, DEFAULT_HEADER_COLOR.to_s)
  end

  def repo?
    Twig.run('git rev-parse 2>&1')
    $?.success?
  end

  def current_branch_name
    @_current_branch_name ||=
      Twig.run('git symbolic-ref -q HEAD').sub(%r{^#{ REF_PREFIX }}, '')
  end

  def all_branches
    @_all_branches ||= begin
      branch_tuples = Twig.
        run(%{git for-each-ref #{ REF_PREFIX } --format="#{ REF_FORMAT }"}).
        split("\n")

      branch_tuples.inject([]) do |result, branch_tuple|
        ref, time_string, time_ago = branch_tuple.split(REF_FORMAT_SEPARATOR)
        time        = Time.parse(time_string)
        commit_time = Twig::CommitTime.new(time, time_ago)
        branch      = Branch.new(ref, :last_commit_time => commit_time)
        result << branch
      end
    end
  end

  def branches
    branches = all_branches
    now = Time.now
    max_seconds_old = options[:max_days_old] * 86400 if options[:max_days_old]

    branches.select do |branch|
      if max_seconds_old
        seconds_old = now.to_i - branch.last_commit_time.to_i
        next if seconds_old > max_seconds_old
      end

      next if options[:branch_except] && branch.name =~ options[:branch_except]
      next if options[:branch_only]   && branch.name !~ options[:branch_only]

      true
    end
  end

  def branch_names
    branches.map { |branch| branch.name }
  end



  ### Actions ###

  def list_branches
    if branches.empty?
      if all_branches.any?
        return 'There are no branches matching your selected options.'
      else
        return 'This repository has no branches.'
      end
    end

    out = "\n" << branch_list_headers(options)

    # List most recently modified branches first
    listable_branches =
      branches.sort_by { |branch| branch.last_commit_time }.reverse

    branch_lines = listable_branches.inject([]) do |result, branch|
      result << branch_list_line(branch)
    end

    out << branch_lines.join("\n")
  end

  def get_branch_property(branch_name, property_name)
    branch = Branch.new(branch_name)
    branch.get_property(property_name)
  end

  def set_branch_property(branch_name, property_name, value)
    branch = Branch.new(branch_name)
    branch.set_property(property_name, value)
  end

  def unset_branch_property(branch_name, property_name)
    branch = Branch.new(branch_name)
    branch.unset_property(property_name)
  end

end
