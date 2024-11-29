#!/bin/bash

echo "Usage: gitplan.sh [command] [subcommand] [arguments]"
echo
echo "Commands:"
echo "  project new [project-id] [project-name] [client]    Create a new project (client is optional)"
echo "  project list                                       List all projects"
echo "  project del [project-name]                         Delete a project"
echo
echo "  task new [project-name] [task-name] [state]        Create a new task in a project (state is optional)"
echo "  task list [project-name]                           List all tasks for a project or all projects"
echo "  task show [project-name] [task-id]                 Show the content of a task"
echo "  task state [project-name] [task-id] [new-state]    Update the state of a task"
echo "  task del [project-name] [task-id]                  Delete a task"
echo
echo "Work Logging Commands:"
echo "  work start [project-name] [task-id]                Start working on a task"
echo "  work end                                          End current work session"
echo "  work log [project-name]                           Show work log (optionally filtered by project)"
echo "  work summary [project-name]                       Show work summary (optionally filtered by project)"
echo
echo "Board View:"
echo "  board [project-name]                              Show kanban board view (optionally filtered by project)"
echo
echo "Valid States:"
echo "  todo         (default)"
echo "  in-progress"
echo "  review"
echo "  done"
echo
echo "Examples:"
echo "  ./gitplan.sh project new my-project \"My Project\" \"Client Name\""
echo "  ./gitplan.sh task new my-project \"Create login page\""
echo "  ./gitplan.sh task state my-project create-login-page in-progress"
echo "  ./gitplan.sh work start my-project create-login-page"
echo "  ./gitplan.sh work end"
echo "  ./gitplan.sh board my-project"