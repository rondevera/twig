Dir[File.join(File.dirname(__FILE__), 'twig', '*')].each { |file| require file }
require 'time'

class Twig
  include Cli
  include Display
  include Options

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

  def current_branch_name
    @_current_branch_name ||=
      Twig.run('git symbolic-ref -q HEAD').sub(%r{^refs/heads/}, '')
  end

  def branch_names
    @_branch_names ||= begin
      refs = Twig.
        run('git for-each-ref refs/heads/ --format="%(refname)"').
        split("\n")
      refs.map! { |ref| ref.sub!('refs/heads/', '') }.sort!
    end

    # Filter branches with latest options
    names = @_branch_names.dup
    if options[:max_days_old]
      now = Time.now
      max_seconds_old = options[:max_days_old] * 86400
      names = names.select do |name|
        branch      = Branch.new(self, name)
        seconds_old = now.to_i - branch.last_commit_time.to_i
        seconds_old <= max_seconds_old
      end
    end
    if options[:name_only]
      names = names.select { |name| name =~ options[:name_only] }
    end
    if options[:name_except]
      names = names.reject { |name| name =~ options[:name_except] }
    end

    names
  end

  def last_commit_times_for_branches
    @_last_commit_times ||= begin
      time_strings = Twig.
        run('git for-each-ref refs/heads/ ' <<
            '--format="%(refname),%(committerdate),%(committerdate:relative)"').
        split("\n")

      time_strings.
        map! { |time_string| time_string.strip }.
        reject! { |time_string| time_string.empty? }

      time_strings.inject({}) do |result, time_string|
        branch_name, time_string, time_ago = time_string.split(',')
        branch_name.sub!('refs/heads/', '')
        time = Time.parse(time_string)
        result.merge(branch_name => Twig::CommitTime.new(time, time_ago))
      end
    end
  end



  ### Actions ###

  def list_branches
    out = "\n" << branch_list_headers

    branches = branch_names.map { |branch_name| Branch.new(self, branch_name) }

    # List most recently modified branches first
    branches = branches.sort_by { |branch| branch.last_commit_time }.reverse

    branch_lines = branches.inject([]) do |result, branch|
      result << branch_list_line(branch)
    end

    out << branch_lines.join("\n")
  end

  def get_branch_property(branch_name, property_name)
    branch = Branch.new(self, branch_name)
    branch.get_property(property_name)
  end

  def set_branch_property(branch_name, property_name, value)
    branch = Branch.new(self, branch_name)
    branch.set_property(property_name, value)
  end

end
