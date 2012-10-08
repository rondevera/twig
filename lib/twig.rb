Dir[File.join(File.dirname(__FILE__), 'twig', '*')].each { |file| require file }
require 'time'

class Twig
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

  def last_commit_times_for_branches
    @_last_commit_times ||= begin
      time_strings = Twig.
        run('git for-each-ref refs/heads/ ' <<
            '--format="%(committerdate),%(committerdate:relative)"').
        split("\n")
      time_strings.
        map! { |time_string| time_string.strip }.
        reject! { |time_string| time_string.empty? }

      commit_times = time_strings.map do |time_string|
        time, time_ago = time_string.split(',')
        time = Time.parse(time)
        Twig::CommitTime.new(time, time_ago)
      end

      Hash[*branch_names.zip(commit_times).flatten]
    end
  end



  ### Actions ###

  def list_branches
    now = Time.now
    max_seconds_old =
      options[:max_days_old] ? options[:max_days_old] * 86400 : nil

    out = "\n" << branch_list_headers

    branches_to_list = branch_names.map do |branch_name|
      branch      = Branch.new(self, branch_name)
      seconds_old = now.to_i - branch.last_commit_time.to_i

      branch if !max_seconds_old || seconds_old <= max_seconds_old
    end.compact

    # List most recently modified branches first
    branches_to_list = branches_to_list.
      sort_by { |branch| branch.last_commit_time }.reverse

    branch_lines = branches_to_list.inject([]) do |result, branch|
      result + [branch_list_line(branch)]
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
