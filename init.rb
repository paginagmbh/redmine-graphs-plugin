require 'redmine'

require_dependency 'target_version_graph_hook'
require_dependency 'issues_sidebar_graph_hook'

Redmine::Plugin.register :redmine_graphs do
  # include dummy variable to prevent hash from being removed if all faluse
  settings :default => {:open_aging_issues_enabled => 1, :total_issues_over_time_enabled => 1, :total_bugs_over_time_enabled => 1, :total_vs_closed_issues_enabled => 1, :burndown_enabled => 1, :dummy_value => "dummy value"}, :partial => 'settings/graphs'
  
  name 'Redmine Graphs plugin'
  author 'Brad Beattie'
  description 'This plugin provides instances of Redmine with additional graphs.'
  version '0.1.0'
end
