require 'redmine'

Rails.configuration.to_prepare do
  require_dependency 'target_version_graph_hook'
  require_dependency 'issues_sidebar_graph_hook'
end

Redmine::Plugin.register :redmine_graphs do
  name 'Redmine Graphs plugin'
  author 'Brad Beattie'
  description 'This plugin provides instances of Redmine with additional graphs.'
  version '0.3.1'
  author_url 'https://github.com/bradbeattie'
  url 'http://github.com/luismaia/redmine-graphs-plugin'
  requires_redmine :version_or_higher => '2.5.1' # required redmine version

  permission :view_graphs, {}

  # include dummy variable to prevent hash from being removed if all faluse
  default_settings = {
      :open_aging_issues_enabled => 1,
      :total_issues_over_time_enabled => 1,
      :total_bugs_over_time_enabled => 1,
      :total_vs_closed_issues_enabled => 1,
      :burndown_enabled => 1,
      :burnup_enabled => 1,
      :bug_tracker => 1,
      :dummy_value => 'dummy value'
  }

  settings(:default => default_settings, :partial => 'settings/graphs')
end
