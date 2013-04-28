require 'SVG/Graph/TimeSeries'

class GraphsController < ApplicationController
    unloadable

    ############################################################################
    # Initialization
    ############################################################################
    
    menu_item :issues, :only => [:issue_growth, :old_issues, :bug_growth, :total_vs_closed, :burndown]

    before_filter :find_optional_version, :only => [:target_version_graph, :burndown_graph]
    before_filter :confirm_issues_exist, :only => [:issue_growth]
    before_filter :find_optional_project, :only => [:issue_growth_graph, :target_version_graph, :burndown_graph]
    before_filter :find_open_issues, :only => [:old_issues, :issue_age_graph, :total_vs_closed, :burndown]
    before_filter :find_all_issues, :only => [:total_vs_closed]
    before_filter :find_estimated_hours, :only => [:burndown, :burndown_graph]
    before_filter :find_spent_hours, :only => [:burndown, :burndown_graph]
    before_filter :find_bug_issues, :only => [:issue_growth, :bug_growth, :bug_growth_graph]
	
    helper IssuesHelper
    
    ############################################################################
    # My Page block graphs
    ############################################################################
    # Displays a ring of issue assignement changes around the current user
    def recent_assigned_to_changes_graph
        yesterday = (Time.now - 7.day).strftime('%Y-%m-%d %H:%M:%S')
        # Get the top visible projects by issue count
        sql = " select u1.id as old_user, u2.id as new_user, count(*) as changes_count"
        sql << " from journals as j"
        sql << " left join journal_details as jd on j.id = jd.journal_id"
        sql << " left join users as u1 on cast(jd.old_value AS decimal) = u1.id"
        sql << " left join users as u2 on cast(jd.value AS decimal) = u2.id"
        sql << " where journalized_type = 'issue' and prop_key = 'assigned_to_id' and timestamp '#{yesterday}' <= j.created_on"
        sql << " and (u1.id = #{User.current.id} or u2.id = #{User.current.id})"
        sql << " and u1.id <> 0 and u2.id <> 0"
        sql << " group by old_user, new_user"
        @assigned_to_changes = ActiveRecord::Base.connection.select_all(sql)
        user_ids = @assigned_to_changes.collect { |change| [change["old_user"].to_i, change["new_user"].to_i] }.flatten.uniq
        user_ids.delete(User.current.id)
        @users = User.find(:all, :conditions => "id IN ("+user_ids.join(',')+")").index_by { |user| user.id } unless user_ids.empty?
        headers["Content-Type"] = "image/svg+xml"
        render :layout => false
    end
    
    # Displays a ring of issue status changes
    def recent_status_changes_graph
        yesterday = (Time.now - 7.day).strftime('%Y-%m-%d %H:%M:%S')
        # Get the top visible projects by issue count
        sql = " select is1.id as old_status, is2.id as new_status, count(*) as changes_count"
        sql << " from journals as j"
        sql << " left join journal_details as jd on j.id = jd.journal_id"
        sql << " left join issue_statuses as is1 on cast(jd.old_value AS decimal) = is1.id"
        sql << " left join issue_statuses as is2 on cast(jd.value AS decimal) = is2.id"
        sql << " where journalized_type = 'issue' and prop_key = 'status_id' and  timestamp '#{yesterday}' <= created_on"
        sql << " group by old_status, new_status"
        sql << " order by is1.position, is2.position"
        @status_changes = ActiveRecord::Base.connection.select_all(sql)
        @issue_statuses = IssueStatus.find(:all).sort { |a,b| a.position<=>b.position }
        headers["Content-Type"] = "image/svg+xml"
        render :layout => false
    end
    
    
    ############################################################################
    # Graph pages
    ############################################################################
    # Displays total number of issues over time
    def issue_growth
    end
    
    # Displays created vs update date on open issues over time    
    def old_issues
        @issues_by_created_on = @issues.sort {|a,b| a.created_on<=>b.created_on} 
        @issues_by_updated_on = @issues.sort {|a,b| a.updated_on<=>b.updated_on}
    end
    # Displays created vs update date on bugs over time    
    def bug_growth
        @bug_by_created = @bugs.group_by {|issue| issue.created_on.to_date }.sort
    end
        
    ############################################################################
    # Embedded graphs for graph pages
    ############################################################################
    # Displays projects by total issues over time
    def issue_growth_graph
      top_projects = nil; issue_counts = nil;
      
      # Initialize the graph
      graph = SVG::Graph::TimeSeries.new({
          :area_fill => true,
          :height => 300,
          :min_y_value => 0,
          :no_css => true,
          :show_x_guidelines => true,
          :scale_x_integers => true,
          :scale_y_integers => true,
          :show_data_points => false,
          :show_data_values => false,
          :stagger_x_labels => true,
          :style_sheet => "/plugin_assets/redmine_graphs/stylesheets/issue_growth.css",
          :width => 720,
          :x_label_format => "%Y-%m-%d"
      })

      ActiveRecord::Base.connection_pool.with_connection do |conn|
        # Get the top visible projects by issue count
        sql = "SELECT project_id, COUNT(*) as issue_count"
        sql << " FROM #{Issue.table_name}"
        sql << " LEFT JOIN #{Project.table_name} ON #{Issue.table_name}.project_id = #{Project.table_name}.id"
        sql << " WHERE (%s)" % Project.allowed_to_condition(User.current, :view_issues)
        unless @project.nil?
            sql << " AND (project_id = #{@project.id}"
            sql << "    OR project_id IN (%s)" % @project.descendants.active.visible.collect { |p| p.id }.join(',') unless @project.descendants.active.visible.empty?
            sql << " )"
        end 
        unless User.current.admin?
            sql << " AND (#{Issue.table_name}.is_private = #{conn.quoted_false} OR "
            sql << "(#{Project.allowed_to_condition(User.current, :view_private_issues)}))"
        end
        sql << " GROUP BY project_id"
        sql << " ORDER BY issue_count DESC"
        sql << " LIMIT 6"
        top_projects = conn.select_all(sql).collect { |p| p["project_id"] }
        
        # Get the issues created per project, per day
        sql = "SELECT project_id, date(#{Issue.table_name}.created_on) as date, COUNT(*) as issue_count"
        sql << " FROM #{Issue.table_name}"
        sql << " LEFT JOIN #{Project.table_name} ON #{Issue.table_name}.project_id = #{Project.table_name}.id"
        sql << " WHERE project_id IN (%s)" % top_projects.compact.join(',')
        unless User.current.admin?
            sql << " AND (#{Issue.table_name}.is_private = #{conn.quoted_false} OR "
            sql << "(#{Project.allowed_to_condition(User.current, :view_private_issues)}))"
        end
        sql << " GROUP BY project_id, date"
        issue_counts = conn.select_all(sql).group_by { |c| c["project_id"] } unless top_projects.compact.empty?
      end
      
      # Generate the created_on lines
      top_projects.each do |project_id|
          counts = Array(issue_counts[project_id])
          created_count = 0
          created_on_line = Hash.new
          created_on_line[(Date.parse( Array(counts).first["date"].to_s )-1).to_s] = 0
          counts.each { |count| created_count += count["issue_count"].to_i; created_on_line[count["date"].to_s] = created_count }
          created_on_line[Date.today.to_s] = created_count
          graph.add_data({
              :data =>  Array(created_on_line).sort.flatten,
              :title => Project.find(project_id).to_s
          })
      end
      graph.add_data(
        :data => [ Date.today.to_s, 0 , (Date.today + 60).to_s, 0 ], 
        :title => Project.find(@project.id).to_s
      ) if top_projects.compact.empty?
      
      # Compile the graph
      headers["Content-Type"] = "image/svg+xml"
      send_data(graph.burn, :type => "image/svg+xml", :disposition => "inline")
    end

    # Displays issues by creation date, cumulatively
    def issue_age_graph
    
        # Initialize the graph
        graph = SVG::Graph::TimeSeries.new({
            :area_fill => true,
            :height => 300,
            :min_y_value => 0,
            :no_css => true,
            :show_x_guidelines => true,
            :scale_x_integers => true,
            :scale_y_integers => true,
            :show_data_points => false,
            :show_data_values => false,
            :stagger_x_labels => true,
            :style_sheet => "/plugin_assets/redmine_graphs/stylesheets/issue_age.css",
            :width => 720,
            :x_label_format => "%b %d"
        })

        # Group issues
        issues_by_created_on = @issues.group_by {|issue| issue.created_on.to_time.localtime.to_date }.sort
        issues_by_updated_on = @issues.group_by {|issue| issue.updated_on.to_time.localtime.to_date }.sort
        
        # Generate the created_on line
        created_count = 0
        created_on_line = Hash.new
        issues_by_created_on.each { |created_on, issues| created_on_line[(created_on-1).to_s] = created_count; created_count += issues.size; created_on_line[created_on.to_s] = created_count }
        created_on_line[Date.today.to_s] = created_count
        graph.add_data({
            :data => created_on_line.sort.flatten,
            :title => l(:field_created_on)
        }) unless issues_by_created_on.empty?
        
        # Generate the closed_on line
        updated_count = 0
        updated_on_line = Hash.new
        issues_by_updated_on.each { |updated_on, issues| updated_on_line[(updated_on-1).to_s] = updated_count; updated_count += issues.size; updated_on_line[updated_on.to_s] = updated_count }
        updated_on_line[Date.today.to_s] = updated_count
        graph.add_data({
            :data => updated_on_line.sort.flatten,
            :title => l(:field_updated_on)
        }) unless issues_by_updated_on.empty?
        
        # Compile the graph
        headers["Content-Type"] = "image/svg+xml"
        send_data(graph.burn, :type => "image/svg+xml", :disposition => "inline")
    end
    
	# Displays bugs over time
    def bug_growth_graph
    
        # Initialize the graph
        graph = SVG::Graph::TimeSeries.new({
            :area_fill => true,
            :height => 300,
            :min_y_value => 0,
            :no_css => true,
            :show_x_guidelines => true,
            :scale_x_integers => true,
            :scale_y_integers => true,
            :show_data_points => false,
            :show_data_values => false,
            :stagger_x_labels => true,
            :style_sheet => "/plugin_assets/redmine_graphs/stylesheets/bug_growth.css",
            :width => 720,
            :x_label_format => "%Y-%m-%d"
        })

        # Group issues
        bug_by_created_on = @bugs.group_by {|issue| issue.created_on.to_time.localtime.to_date }.sort
        bug_by_updated_on = @bugs.delete_if {|issue| !issue.closed? }.group_by {|issue| issue.updated_on.to_time.localtime.to_date }.sort
		
        # Generate the created_on line
        created_count = 0
        created_on_line = Hash.new
        bug_by_created_on.each { |created_on, bugs| created_on_line[(created_on-1).to_s] = created_count; created_count += bugs.size; created_on_line[created_on.to_s] = created_count }
        created_on_line[Date.today.to_s] = created_count
        graph.add_data({
            :data => created_on_line.sort.flatten,
            :title => l(:field_created_on)
        }) unless bug_by_created_on.empty?
        
        # Generate the closed_on line
        updated_count = 0
        updated_on_line = Hash.new
        bug_by_updated_on.each { |updated_on, bugs| updated_on_line[(updated_on-1).to_s] = updated_count; updated_count += bugs.size; updated_on_line[updated_on.to_s] = updated_count }
        updated_on_line[Date.today.to_s] = updated_count
        graph.add_data({
            :data => updated_on_line.sort.flatten,
            :title => l(:label_graphs_closed_bugs)
        }) unless bug_by_updated_on.empty?
        
        # Compile the graph
        headers["Content-Type"] = "image/svg+xml"
        send_data(graph.burn, :type => "image/svg+xml", :disposition => "inline")
    end
	
	# Displays open and total issue counts over time
    def target_version_graph

        # Initialize the graph
        graph = SVG::Graph::TimeSeries.new({
            :area_fill => true,
            :height => 300,
            :no_css => true,
            :show_x_guidelines => true,
            :scale_x_integers => true,
            :scale_y_integers => true,
            :show_data_points => true,
            :show_data_values => false,
            :stagger_x_labels => true,
            :style_sheet => "/plugin_assets/redmine_graphs/stylesheets/target_version.css",
            :width => 800,
            :x_label_format => "%b %d"
        })
        
        if !@version.nil?
          fixed_issues = @version.fixed_issues
          target_date = @version.effective_date.to_time.localtime.to_date unless @version.effective_date.nil?
          completed = @version.completed?
        elsif !@project.nil?
          ids = [@project.id]
          ids += @project.descendants.active.visible.collect(&:id)
          fixed_issues = Issue.visible.find(:all, :include => [:status], :conditions => ["#{Project.table_name}.id IN (?)", ids])
          target_date = @project.due_date.to_time.localtime.to_date unless @project.due_date.nil?
          completed = !@project.active?
        else
          fixed_issues = Issue.all
          target_data = nil
          completed = false
        end
        
        # Group issues
        issues_by_created_on = fixed_issues.group_by {|issue| issue.created_on.to_time.localtime.to_date }.sort
        issues_by_updated_on = fixed_issues.group_by {|issue| issue.updated_on.to_time.localtime.to_date }.sort
        issues_by_closed_on = fixed_issues.collect {|issue| issue if issue.closed? }.compact.group_by {|issue| issue.updated_on.to_time.localtime.to_date }.sort
                    
        # Set the scope of the graph
        scope_end_date = issues_by_updated_on.last.first
        scope_end_date = target_date if !target_date.nil? && target_date > scope_end_date
        scope_end_date = Date.today if !completed
        line_end_date = Date.today
        line_end_date = scope_end_date if scope_end_date < line_end_date
                    
        # Generate the created_on line
        created_count = 0
        created_on_line = Hash.new
        issues_by_created_on.each { |created_on, issues| created_on_line[(created_on-1).to_s] = created_count; created_count += issues.size; created_on_line[created_on.to_s] = created_count }
        created_on_line[scope_end_date.to_s] = created_count
        graph.add_data({
            :data => created_on_line.sort.flatten,
            :title => l(:label_total).capitalize
        })
        
        # Generate the closed_on line
        closed_count = 0
        closed_on_line = Hash.new
        issues_by_closed_on.each { |closed_on, issues| closed_on_line[(closed_on-1).to_s] = closed_count; closed_count += issues.size; closed_on_line[closed_on.to_s] = closed_count }
        closed_on_line[line_end_date.to_s] = closed_count
        graph.add_data({
            :data => closed_on_line.sort.flatten,
            :title => l(:label_closed_issues).capitalize
        })
        
        # Add the version due date marker
        graph.add_data({
            :data => [target_date.to_s, created_count],
            :title => l(:field_due_date).capitalize
        }) unless target_date.nil?
        
        
        # Compile the graph
        headers["Content-Type"] = "image/svg+xml"
        send_data(graph.burn, :type => "image/svg+xml", :disposition => "inline")
    end
    
    def burndown_graph
    
        # Initialize the graph
        graph = SVG::Graph::TimeSeries.new({
            :area_fill => true,
            :height => 300,
            :no_css => true,
            :show_x_guidelines => true,
            :scale_x_integers => true,
            :scale_y_integers => true,
            :show_data_points => true,
            :show_data_values => false,
            :stagger_x_labels => true,
            :style_sheet => "/plugin_assets/redmine_graphs/stylesheets/burndown.css",
            :width => 800,
            :x_label_format => "%b %d"
        })
        
        if !@version.nil?
          fixed_issues = @version.fixed_issues
          target_date = @version.effective_date.to_time.localtime.to_date unless @version.effective_date.nil?
          completed = @version.completed?
        elsif !@project.nil?
          ids = [@project.id]
          ids += @project.descendants.active.visible.collect(&:id)
          fixed_issues = Issue.visible.find(:all, :include => [:status], :conditions => ["#{Project.table_name}.id IN (?)", ids])
          target_date = @project.due_date.to_time.localtime.to_date unless @project.due_date.nil?
          completed = !@project.active?
        else
          fixed_issues = Issue.all
          target_date = nil
          completed = false
        end
        
        # Group issues
        issues_by_created_on = fixed_issues.group_by {|issue| issue.created_on.to_time.localtime.to_date }.sort
        issues_by_updated_on = fixed_issues.group_by {|issue| issue.updated_on.to_time.localtime.to_date }.sort
        issues_by_closed_on = fixed_issues.collect {|issue| issue if issue.closed? }.compact.group_by {|issue| issue.updated_on.to_time.localtime.to_date }.sort
        time_entries_by_spent_on = @entries.group_by { |entry| entry.spent_on.to_time.localtime.to_date }.sort
                    
        # Set the scope of the graph
        scope_end_date = issues_by_updated_on.last.first
        scope_end_date = time_entries_by_spent_on.last.first.to_date if !time_entries_by_spent_on.empty? && time_entries_by_spent_on.last.first.to_date > scope_end_date
        scope_end_date = Date.today if !completed && Date.today > scope_end_date
        line_end_date = Date.today
        line_end_date = scope_end_date if scope_end_date < line_end_date
                    
        
        # Generate the spent_time line
        spent_hours = 0
        spent_on_line = Hash.new
        
        # Generate the remaining_hours line
        remaining_hours = @estimated_hours
        remaining_on_line = Hash.new
        
        # Generate the estimated - remaining line
        completed_hours = 0
        completed_on_line = Hash.new
        
        all_dates = issues_by_created_on + issues_by_closed_on + time_entries_by_spent_on
        all_dates = all_dates.sort! { |x,y| x.first <=> y.first }
        all_dates.each { | key, objects | 
          objects.each { | object |
            if object.is_a? Issue
              remaining_on_line[(key-1).to_s] = remaining_hours
              completed_on_line[(key-1).to_s] = completed_hours
              hours = object.estimated_hours.nil? ? 0 : object.estimated_hours 
              if object.closed? && key == object.updated_on.to_date
                remaining_hours -= remaining_hours >= hours ? hours : remaining_hours
                completed_hours += hours
                remaining_on_line[key.to_s] = remaining_hours
                completed_on_line[key.to_s] = completed_hours
              end
           elsif object.is_a? TimeEntry
            spent_on_line[(key-1).to_s] = spent_hours
            spent_hours += object.hours.to_f
            spent_on_line[key.to_s] = spent_hours   
           end
          }
        }
        
        spent_on_line[scope_end_date.to_s] = spent_hours
        graph.add_data({
            :data => spent_on_line.sort.flatten,
            :title => l(:label_spent_time).capitalize
        })
        
        remaining_on_line[scope_end_date.to_s] = remaining_hours
        graph.add_data({
          :data => remaining_on_line.sort.flatten,
          :title => l(:label_graphs_remaining_hours)
        })
        
        completed_on_line[scope_end_date.to_s] = completed_hours
        graph.add_data({
          :data => completed_on_line.sort.flatten,
          :title => l(:label_graphs_completed_work)
        })
        
        # Add the version due date marker
        graph.add_data({
            :data => [target_date.to_s, 0],
            :title => l(:field_due_date).capitalize
        }) unless target_date.nil?
        
        
        # Compile the graph
        headers["Content-Type"] = "image/svg+xml"
        send_data(graph.burn, :type => "image/svg+xml", :disposition => "inline")
    end
    
    
    ############################################################################
    # Private methods
    ############################################################################
    private
            
    def confirm_issues_exist
        find_optional_project
        if !@project.nil?
            ids = [@project.id]
            ids += @project.descendants.active.visible.collect(&:id)
            @issues = Issue.visible.find(:first, :conditions => ["#{Project.table_name}.id IN (?)", ids])
        else
            @issues = Issue.visible.find(:first)
        end
    rescue ActiveRecord::RecordNotFound
        render_404
    end
    
    def find_open_issues
        find_optional_project
        if !@project.nil?
            ids = [@project.id]
            ids += @project.descendants.active.visible.collect(&:id)
            @issues = Issue.visible.find(:all, :include => [:status], :conditions => ["#{IssueStatus.table_name}.is_closed=? AND #{Project.table_name}.id IN (?)", false, ids])
        else
            @issues = Issue.visible.find(:all, :include => [:status], :conditions => ["#{IssueStatus.table_name}.is_closed=?", false])
        end
    rescue ActiveRecord::RecordNotFound
        render_404
    end
    
    def find_all_issues
        find_optional_project
        if !@project.nil?
            ids = [@project.id]
            ids += @project.descendants.active.visible.collect(&:id)
            @all_issues = Issue.visible.find(:all, :include => [:status], :conditions => ["#{Project.table_name}.id IN (?)", ids])
        else
            @all_issues = Issue.visible.find(:all, :include => [:status])
        end
    rescue ActiveRecord::RecordNotFound
        render_404
    end
	
    def find_bug_issues
        find_optional_project
        if !@project.nil?
            ids = [@project.id]
            ids += @project.descendants.active.visible.collect(&:id)
            @bugs= Issue.visible.find(:all, :include => [:status], :conditions => ["#{Issue.table_name}.tracker_id IN (?) AND #{Project.table_name}.id IN (?)", 1, ids])
        else
            @bugs= Issue.visible.find(:all, :include => [:status], :conditions => ["#{Issue.table_name}.tracker_id IN (?)", 1])
        end
    rescue ActiveRecord::RecordNotFound
        render_404
    end
    
    def find_optional_project
        if @version.nil?
          @project = Project.find(params[:project_id]) unless params[:project_id].blank?
          deny_access unless User.current.allowed_to?(:view_issues, @project, :global => true)
        end
    rescue ActiveRecord::RecordNotFound
        render_404
    end
    
    def find_optional_version
        @version = Version.find(params[:id]) unless params[:id].blank?
        deny_access unless @version.nil? or User.current.allowed_to?(:view_issues, @version.project)
    rescue ActiveRecord::RecordNotFound
        render_404
    end
    
    def find_estimated_hours
      find_optional_project
      find_optional_version
      if !@version.nil?
        @estimated_hours = @version.estimated_hours
      elsif !@project.nil?
        @estimated_hours = get_estimated_hours_by_project(@project)
      else
        @estimated_hours = 0
        Project.all.each { |project| @estimated_hours += get_estimated_hours_by_project(project) }
      end
    end
    
    def find_spent_hours
      find_optional_project
      find_optional_version
      if !@version.nil?
        @entries = TimeEntry.joins(:issue).where("#{Issue.table_name}.fixed_version_id = ?", @version.id)
        @spent_hours = @version.spent_hours
      elsif !@project.nil?
        ids = [@project.id]
        ids += @project.descendants.active.visible.collect(&:id)
        @entries = TimeEntry.visible.joins(:issue).where("#{Issue.table_name}.project_id IN (?)", ids)
        @spent_hours = @entries.sum(:hours).to_f
      else
        @spent_hours = 0
        @entries = TimeEntry.all
        @entries.each { |entry| @spent_hours += entry.hours }
      end
    end
    
    def get_estimated_hours_by_project(project)
      estimated_hours = 0
      ids = [project.id]
      ids += project.descendants.active.visible.collect(&:id)
      issues = Issue.visible.find(:all, :include => [:status], :conditions => ["#{Project.table_name}.id IN (?)", ids])
      issues.each do |issue|
        estimated_hours += issue.estimated_hours unless issue.estimated_hours.nil?
      end
      estimated_hours
    end
    
end
