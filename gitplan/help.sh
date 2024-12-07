#!/bin/bash

echo "Usage: gitplan.sh [-t tag] [command] [subcommand] [arguments]"
echo
echo "Global Options:"
echo "  -t [tag]                                          Filter tasks by tag"
echo
echo "Commands:"
echo "  project new [project-id] [project-name] [client]    Create a new project (client is optional)"
echo "  project list                                       List all projects"
echo "  project del [project-id]                           Delete a project"
echo
echo "  task new [project-id] [task-name]                  Create a new task in a project"
echo "  task list [project-id]                            List all tasks, optionally filtered by project"
echo "  task show [project-id] [task-id]                   Show the content of a task"
echo "  task state [project-id] [task-id] [new-state]      Update the state of a task"
echo "  task del [project-id] [task-id]                    Delete a task"
echo "  task edit [project-id] [task-id]                   Edit a task in your preferred editor"
echo
echo "Tag Commands:"
echo "  tags                                              Show all tags used across all tasks"
echo
echo "Work Logging Commands:"
echo "  work start [project-id] [task-id]                  Start working on a task"
echo "  work end                                           End current work session"
echo "  work log [project-id]                              Show work log (optionally filtered by project)"
echo "  work summary [project-id]                          Show work summary (optionally filtered by project)"
echo
echo "Board View:"
echo "  board [project-id]                                 Generate kanban board view (optionally filtered by project)"
echo "  board show [project-id]                            Generate and open board in default browser"
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
echo "  ./gitplan.sh -t backend task list my-project      # List tasks with 'backend' tag in project"
echo "  ./gitplan.sh -t urgent task list                  # List all urgent tasks across projects"
echo "  ./gitplan.sh work start my-project create-login-page"
echo "  ./gitplan.sh work end"
echo "  ./gitplan.sh board my-project"