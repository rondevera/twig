$LOAD_PATH.unshift(File.dirname(__FILE__)) # For gem development
require 'twig/branch'
require 'twig/cli'
require 'twig/commit_time'
require 'twig/display'
require 'twig/github'
require 'twig/homepage'
require 'twig/options'
require 'twig/subcommands'
require 'twig/system'
require 'twig/util'
require 'twig/version'
require 'time'

# The main class.
class Twig
  include Cli
  include Display
  include Options

  attr_accessor :options

  DEFAULT_GITHUB_API_URI_PREFIX = 'https://api.github.com'
  DEFAULT_GITHUB_URI_PREFIX = 'https://github.com'
  DEFAULT_HEADER_COLOR = :blue
  REF_FORMAT_SEPARATOR = '|'
  REF_FORMAT = %w[refname:short committerdate].
                map { |field| '%(' + field + ')' }.
                join(REF_FORMAT_SEPARATOR)
  REF_PREFIX = 'refs/heads/'

  def self.run(command)
    `#{command}`.strip
  end

  def self.repo?
    Twig.run('git rev-parse 2>&1')
    $?.success?
  end

  def initialize(options = {})
    self.options = {}

    # Set defaults
    set_option(:github_api_uri_prefix, DEFAULT_GITHUB_API_URI_PREFIX)
    set_option(:github_uri_prefix, DEFAULT_GITHUB_URI_PREFIX)
    set_option(:header_style, DEFAULT_HEADER_COLOR.to_s)

    if options[:read_options]
      read_config_file!
      read_cli_options!(ARGV)
    end
  end

  def current_branch_name
    # Returns the name of the branch that is currently checked out in Git.
    @_current_branch_name ||= Twig.run('git rev-parse --abbrev-ref HEAD')
  end

  def target_branch_name
    # Returns the name of the branch to work on, e.g., for setting a property.
    options[:branch] || current_branch_name
  end

  def target_branch
    Twig::Branch.new(target_branch_name)
  end

  def branches
    branches = Twig::Branch.all_branches
    now = Time.now
    max_days_old = options[:max_days_old]
    max_seconds_old = max_days_old * 86400 if max_days_old

    branches = branches.select do |branch|
      catch :skip_branch do
        if max_seconds_old
          seconds_old = now.to_i - branch.last_commit_time.to_i
          next if seconds_old > max_seconds_old
        end

        branch_name = branch.name

        (options[:property_except] || {}).each do |property_name, property_value|
          if property_name == :branch
            throw :skip_branch if branch_name =~ property_value
          elsif branch.get_property(property_name.to_s) =~ property_value
            throw :skip_branch
          end
        end

        (options[:property_only] || {}).each do |property_name, property_value|
          if property_name == :branch
            throw :skip_branch if branch_name !~ property_value
          elsif branch.get_property(property_name.to_s) !~ property_value
            throw :skip_branch
          end
        end

        true
      end
    end

    # List least recently modified branches first
    branches = branches.sort_by { |branch| branch.last_commit_time }
    if options[:reverse] != true
      branches.reverse! # List most recently modified branches first
    end

    branches
  end

  def property_names
    @_property_names ||= begin
      property_names = Twig::Branch.all_property_names
      only_name      = options[:property_only_name]
      except_name    = options[:property_except_name]

      if only_name
        property_names = property_names.select { |name| name =~ only_name }
      end

      if except_name
        property_names = property_names.select { |name| name !~ except_name }
      end

      property_names
    end
  end

  ### Actions ###

  def list_branches
    if branches.empty?
      if Twig::Branch.all_branches.any?
        return 'There are no branches matching your selected options.'
      else
        return 'This repository has no branches.'
      end
    end

    out = "\n" << branch_list_headers(options)

    branch_lines = branches.inject([]) do |result, branch|
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
