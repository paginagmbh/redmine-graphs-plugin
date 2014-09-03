# graphs

This plugin provides instances of Redmine a method with additional graphs.

Created by Gossamer Threads Inc. (http://www.gossamer-threads.com)

Author: [Brad Beattie](https://github.com/bradbeattie)

Updated by: [David S Anderson](https://github.com/ande3577)

Report any issues to: https://github.com/ande3577/redmine-graphs-plugin/issues?state=open


## How to use

Only tested on Redmine 2.5 and Ruby 2.*.  Use other versions at your own risk.

    $ cd /path/to/redmine/plugins
    $ git clone https://github.com/luismaia/redmine-graphs-plugin.git redmine_graphs
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

* _Remaining Hours (Estimated)_: The total estimated time of all open issues (assumes that all issues begin at the project start
date
* _Estimated - Spent Hours_: the time spent on the project subtracted from the total estimated time.  Comparing with the remaining
hours provides a metric for measuring the accuracy of the project's time estimates and developer efficiency
* _Due Date_: the target date of the project/version

![burndown](/img/burndown.png "Burndown")

### Burnup

Display the total, completed and spent time in burnup format.  This is an alternative presentation of the
same information contained in a burndown graph.

![burnup](/img/burnup.png "Burnup")
