#!/bin/bash

echo "Usage: gitplan.sh [command] [subcommand] [arguments]"
echo
echo "Commands:"
echo "  project new [project-name]    Create a new project"
echo "  project list                  List all projects"
echo "  task new [project-name] [task-name] [state]    Create a new task in a project (state is optional)"
echo "  task list [project-name]      List all tasks for a project or all projects if no project name is provided"
echo "  task del [project-name] [task-name]    Delete a task"
echo "  task show [project-name] [task-name]   Show the content of a task"
echo "  task state [project-name] [task-name] [new-state]    Update the state of a task"
echo "  help                          Display this help message"
echo
echo
echo "Work Logging Commands:"
echo "  work start [project-name] [task-name]    Start working on a task"
echo "  work end                                 End current work session"
echo "  work log [project-name]                  Show work log (optionally filtered by project)"
echo "  work summary [project-name]              Show work summary (optionally filtered by project)"
echo
echo "States:"
echo "  todo (default)"
echo "  in-progress"
echo "  review"
echo "  done"
echo
echo "Examples:"
echo "  ./gitplan.sh project new my-project"
echo "  ./gitplan.sh task new my-project my-task todo"
echo "  ./gitplan.sh task state my-project my-task in-progress"
echo "  ./gitplan.sh task show my-project my-task"
echo "  ./gitplan.sh task del my-project my-task"
echo "  ./gitplan.sh task list"