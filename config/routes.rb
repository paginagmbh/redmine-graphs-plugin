RedmineApp::Application.routes.draw do
  match 'graphs/issues/old', :to => 'graphs#old_issues', :via => 'get'
  match 'projects/:project_id/issues/old', :to => 'graphs#old_issues', :via => 'get'
  #
  match 'graphs/old_issues', :to => 'graphs#issue_age_graph', :via => 'get'
  match 'graphs/issues/issue_age_graph', :to => 'graphs#issue_age_graph', :via => 'get'
  match ':project_id/issue_age_graph', :to => 'graphs#issue_age_graph', :via => 'get'


  match 'graphs/issues/growth', :to => 'graphs#issue_growth', :via => 'get'
  match 'projects/:project_id/issues/growth', :to => 'graphs#issue_growth', :via => 'get'
  #
  match 'graphs/issue_growth', :to => 'graphs#issue_growth_graph', :via => 'get'
  match 'graphs/issues/issue_growth_graph', :to => 'graphs#issue_growth_graph', :via => 'get'
  match ':project_id/issue_growth_graph', :to => 'graphs#issue_growth_graph', :via => 'get'


  match 'graphs/issues/bug_growth', :to => 'graphs#bug_growth', :via => 'get'
  match 'projects/:project_id/issues/bug_growth', :to => 'graphs#bug_growth', :via => 'get'
  #
  #match 'graphs/bug_growth', :to => 'graphs#bug_growth_graph', :via => 'get'
  match 'graphs/issues/bug_growth_graph', :to => 'graphs#bug_growth_graph', :via => 'get'
  match ':project_id/bug_growth_graph', :to => 'graphs#bug_growth_graph', :via => 'get'


  match 'projects/:project_id/issues/total_vs_closed', :to => 'graphs#total_vs_closed', :via => 'get'
  match 'graphs/issues/total_vs_closed', :to => 'graphs#total_vs_closed', :via => 'get'
  #
  #match 'graphs/total_vs_closed', :to => 'graphs#target_version_graph', :via => 'get'
  match 'projects/:project_id/issues/total_vs_closed_graph', :to => 'graphs#target_version_graph', :via => 'get'
  match 'graphs/issues/total_vs_closed_graph', :to => 'graphs#target_version_graph', :via => 'get'
  #
  match 'graphs/target-version-burndown/:id', :to => 'graphs#target_version_graph', :via => 'get'
  match 'graphs/target-version/:id', :to => 'graphs#target_version_graph', :via => 'get'


  match 'projects/:project_id/issues/burndown', :to => 'graphs#burndown', :via => 'get'
  match 'graphs/issues/burndown', :to => 'graphs#burndown', :via => 'get'
  #
  match 'projects/:project_id/issues/burndown_graph', :to => 'graphs#burndown_graph', :via => 'get'
  match 'graphs/issues/burndown_graph', :to => 'graphs#burndown_graph', :via => 'get'


  match 'projects/:project_id/issues/burnup', :to => 'graphs#burnup', :via => 'get'
  match 'graphs/issues/burnup', :to => 'graphs#burnup', :via => 'get'
  #
  match 'projects/:project_id/issues/burnup_graph', :to => 'graphs#burndup_graph', :via => 'get'
  match 'graphs/issues/burnup_graph', :to => 'graphs#burnup_graph', :via => 'get'


  #Graphs in My page
  match 'graphs/recent-status-changes', :to => 'graphs#recent_status_changes_graph', :via => 'get'
  match 'graphs/recent-assigned-to-changes', :to => 'graphs#recent_assigned_to_changes_graph', :via => 'get'

end
