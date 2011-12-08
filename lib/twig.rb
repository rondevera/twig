module Twig
  RESERVED_BRANCH_PROPERTIES = %w[merge remote]
  COLORS = {
    :black  => 30,
    :red    => 31,
    :green  => 32,
    :yellow => 33,
    :blue   => 34,
    :purple => 35,
    :cyan   => 36,
    :white  => 37
  }
  WEIGHTS = {
    :normal => 0,
    :bold   => 1
  }


  ### Helpers ###

  def self.current_branch
    @_current_branch ||= `git name-rev --name-only head`.strip
  end

  def self.branches
    @_branches ||= begin
      refs = `git for-each-ref --format='%(refname)' refs/heads/`.split("\n")
      refs.map! { |ref| ref.sub!('refs/heads/', '') }
    end
  end

  def self.branch_properties
    @_branch_properties ||= begin
      properties = `git config --list`.strip.split("\n").
                      select { |var| var =~ /^branch\./ }.
                      map do |var|
                        match_data = /^branch\.[^.]+\.([^=]+)/.match(var)
                        match_data[1] if match_data
                      end
      properties.uniq.compact.sort - RESERVED_BRANCH_PROPERTIES
    end
  end

  def self.last_commit_time_for_branch(branch)
    @_last_commit_times ||= {}
    @_last_commit_times[branch] ||= begin
      # time = `git log -1 --pretty=format:"%Cgreen%ci %Cblue%cr%Creset" "#{branch}"`
      time = `git log -1 --pretty=format:"%ci (%cr)" "#{branch}"`

      # Shorten relative time
      time.sub!(' years',   'y')
      time.sub!(' months',  'mo')
      time.sub!(' weeks',   'w')
      time.sub!(' days',    'd')
      time.sub!(' hours',   'h')
      time.sub!(' minutes', 'm')
      time.sub!(' seconds', 's')

      time
    end
  end

  def self.column(string = ' ', num_columns = 1, options = {})
    # Returns `string` with an exact fixed width. If `string` is too wide,
    # it's truncated with an ellipsis.
    #
    # Options:
    # - `:color`: `nil` by default. Accepts a key from `COLORS`.
    # - `:bold`:  `nil` by default. Set `true` for bold text.

    width_per_column = 8
    total_width = num_columns * width_per_column
    new_string = string[0, total_width]
    omission = '...'

    if string.size > total_width
      # Replace final characters with omission
      new_string[-omission.size, omission.size] = omission
    else
      new_string = ' ' * total_width
      new_string[0, string.size] = string
    end

    if options[:color] || options[:bold]
      color_options = [COLORS[options[:color]]]
      color_options << WEIGHTS[:bold] if options[:bold]
      new_string = "\033[#{color_options.join(';')}m#{new_string}\033[0m"
    end

    new_string
  end

  def self.version; '1.0.0'; end



  ### Actions ###

  def self.list_branches
    out = "\n"

    # Prepare column headers
    header_options = {:color => :blue}
    out << column(' ', 5) <<
      branch_properties.map { |prop|
        column(prop, 2, header_options)
      }.join <<
      column('  branch', 1, header_options) << "\n"
    out << column(' ', 5) <<
      branch_properties.map { |prop|
        column('-' * prop.size, 2, header_options)
      }.join <<
      column('  ------', 1, header_options) << "\n"

    # Process branches
    branch_lines = branches.map do |branch|
      line = ''
      is_current_branch = (branch == current_branch)

      # Gather branch properties
      last_commit_time = last_commit_time_for_branch(branch)
      properties = branch_properties.inject({}) do |hsh, property_name|
        property = get_branch_property(branch, property_name)
        hsh.merge(property_name => property)
      end

      # Add placeholders for empty branch properties
      properties.each do |key, value|
        properties[key] = column('-') if value.strip.empty?
      end

      # Format branch properties
      line << column(last_commit_time, 5) <<
             branch_properties.map { |prop| column(properties[prop] || '', 2) }.join
      if is_current_branch
        line << "* #{branch}"
      else
        line << "  #{branch}"
      end
    end

    # List most recently modified branches first
    branch_lines.sort!.reverse!

    # Render current branch as bold
    current_branch_index =
      branch_lines.index { |line| line =~ /\* #{current_branch}$/ }
    if current_branch_index
      line = branch_lines[current_branch_index]
      branch_lines[current_branch_index] = "\033[1m#{line}\033[0m"
    end

    out << branch_lines.join("\n")
  end

  def self.get_branch_property(branch, key, options = {})
    `git config branch.#{branch}.#{key}`.strip
  end

  def self.set_branch_property(branch, key, value, options = {})
    # Sets the given value for the given property key under the current
    # branch. Returns a confirmation string for printing.

    value = value.to_s

    if value.empty?
      `git config --unset branch.#{branch}.#{key}`
      %{Removed #{key} for #{branch}}
    else
      `git config branch.#{branch}.#{key} "#{value}"`
      %{Saved #{key}=#{value} for #{branch}}
    end
  end

end
