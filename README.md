# graphs

This plugin provides instances of Redmine a method with additional graphs.

Created by Gossamer Threads Inc. (http://www.gossamer-threads.com)
Primary developer: Brad Beattie

Updated by: [David S Anderson](https://github.com/ande3577)

Report any issues to: https://github.com/ande3577/redmine-graphs-plugin/issues?state=open

## How to use

Only tested on Redmine 2.2/2.3 and Ruby 1.9.3.  Use other versions at your own risk.

NOTE: Redmine 2.0.3 has compatibility issue with Ruby 1.9.x. Please see {Defect #11290: ParseDate missing in Ruby 1.9x - Redmine}[http://www.redmine.org/issues/11290].

    $ cd /path/to/redmine/plugins
    $ git clone git://github.com/dmp/redmine-graphs-plugin.git redmine_graphs
    $ rake redmine:plugins:migrate RAILS_ENV=production 

Then restart redmine.

## Graph Description

### Open Aging Issues

View the number of open issues vs the number of issues that have been updated.

![open_aging_issues](/img/open_aging_issues.png "Open Aging Issues")

### Total Issues Over Time

Shows the total number of issues on a project.  Includes sub-projects.

![total_issues_over_time](/img/total_issues_over_time.png "Total Issues Over Time")

### Total Issues vs Closed Issues

Shows the number of total issues on a project and the number of closed issues.

![total_issues_vs_closed_issues](/img/total_issues_vs_closed_issues.png "Total Issues vs. Closed Issues")

### Total Bugs Over Time

Shows the number of total open vs closed bugs on a project.  Will also show the number of closed bugs.

![total_bugs_over_time](/img/total_bugs_over_time.png "Total Bugs Over Time")

### Burndown

Display the progress of a project relative to time spent.  Intended to be used to track a project progress 
relative to an ideal schedule.

* _Spent time_: The total of all time logged to the project
* _Remaining_: The total estimated time of all open issues
* _Estimated - Remaining_: the estimated time to complete closed issues on the project.  This provides a metric
for measuring the accuracy of the projects time estimates
* _Due Date_: the target date of the project/version

![burndown](/img/burndown.png "Burndown")
