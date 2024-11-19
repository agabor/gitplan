#!/bin/bash

# Function to read the root path from an ini file
read_root_path() {
    local ini_file=$1
    local root_path=$(awk -F '=' '/root_path/ {print $2}' "$ini_file" | tr -d ' ')
    echo "$root_path"
}

# Path to the ini file
ini_file="config.ini"

# Read and print the root path
root_path=$(read_root_path "$ini_file")
echo "Root Path: $root_path"

# Function to create a new project
create_new_project() {
    local project_name=$1
    local project_dir="$root_path/$project_name"
    
    # Create the project directory
    mkdir -p "$project_dir"
    
    # Create an index.md file inside the project directory
    touch "$project_dir/index.md"
    
    echo "Project '$project_name' created at '$project_dir'"
}

# Check for the 'project' command and 'new' subcommand
if [[ "$1" == "project" && "$2" == "new" && -n "$3" ]]; then
    create_new_project "$3"
fi

# Function to read the next task ID from the ini file
read_next_task_id() {
    local ini_file=$1
    local next_id=$(awk -F '=' '/next_id/ {print $2}' "$ini_file" | tr -d ' ')
    echo "$next_id"
}

# Function to update the next task ID in the ini file
update_next_task_id() {
    local ini_file=$1
    local next_id=$2
    awk -F '=' -v new_id=$next_id '/next_id/ {$2=new_id}1' OFS='=' "$ini_file" > temp.ini && mv temp.ini "$ini_file"
}

# Check for the 'task' command and 'new' subcommand
if [[ "$1" == "task" && "$2" == "new" && -n "$3" && -n "$4" ]]; then
    project_name=$3
    project_dir="$root_path/$project_name"
    
    if [ ! -d "$project_dir" ]; then
        echo "Project '$project_name' does not exist."
        exit 1
    fi
    task_name=$4
    next_id=$(read_next_task_id "$root_path/gitplan.ini")
    task_file="$root_path/$project_name/$task_name-$next_id.md"
    
    vim "$task_file"
    
    # Increment the next_id and update the ini file
    if [ -f "$task_file" ]; then
        new_next_id=$((next_id + 1))
        update_next_task_id "$root_path/gitplan.ini" "$new_next_id"
    else
        echo "Task creation cancelled."
        exit 1
    fi
fi

# Function to list all tasks for a given project or all projects
list_tasks() {
    local project_name=$1
    
    if [ -n "$project_name" ]; then
        local project_dir="$root_path/$project_name"
        
        if [ -d "$project_dir" ]; then
            echo "Tasks for project '$project_name':"
            ls "$project_dir"/*.md 2>/dev/null | while read -r task_file; do
                task_name=$(basename "$task_file")
                if [[ "$task_name" != "index.md" ]]; then
                    echo "- ${task_name%.md}"
                fi
            done
        else
            echo "Project '$project_name' does not exist."
        fi
    else
        echo "Tasks for all projects:"
        find "$root_path" -name "*.md" 2>/dev/null | while read -r task_file; do
            task_name=$(basename "$task_file")
            if [[ "$task_name" != "index.md" ]]; then
                project_name=$(basename "$(dirname "$task_file")")
                echo "- [$project_name] ${task_name%.md}"
            fi
        done
    fi
}

# Check for the 'task' command and 'list' subcommand
if [[ "$1" == "task" && "$2" == "list" ]]; then
    list_tasks "$3"
fi

# Function to display help information
display_help() {
    echo "Usage: gitplan.sh [command] [subcommand] [arguments]"
    echo
    echo "Commands:"
    echo "  project new [project-name]    Create a new project"
    echo "  project list                  List all projects"
    echo "  task new [project-name] [task-name]    Create a new task in a project"
    echo "  task list [project-name]      List all tasks for a project or all projects if no project name is provided"
    echo "  task del [task-name]          Delete a task"
    echo "  task show [task-name]         Show the content of a task"
    echo "  help                          Display this help message"
    echo
    echo "Examples:"
    echo "  ./gitplan.sh project new my-project"
    echo "  ./gitplan.sh project list"
    echo "  ./gitplan.sh task new my-project my-task"
    echo "  ./gitplan.sh task list my-project"
    echo "  ./gitplan.sh task list"
    echo "  ./gitplan.sh task del my-task"
    echo "  ./gitplan.sh task show my-task"
    echo "  ./gitplan.sh help"
}
# Function to list all projects
list_projects() {
    echo "Projects:"
    find "$root_path" -mindepth 1 -maxdepth 1 -type d | while read -r project_dir; do
        project_name=$(basename "$project_dir")
        echo "- $project_name"
    done
}

# Check for the 'project' command and 'list' subcommand
if [[ "$1" == "project" && "$2" == "list" ]]; then
    list_projects
    exit 0
fi
# Check for the 'task' command and 'del' subcommand
if [[ "$1" == "task" && "$2" == "del" && -n "$3" ]]; then
    task_file=$(find "$root_path" -name "$3.md" 2>/dev/null)
    
    if [ -n "$task_file" ]; then
        rm "$task_file"
        echo "Task '$3' deleted."
    else
        echo "Task '$3' not found."
    fi
fi
# Check for the 'task' command and 'show' subcommand
if [[ "$1" == "task" && "$2" == "show" && -n "$3" ]]; then
    task_file=$(find "$root_path" -name "$3.md" 2>/dev/null)
    
    if [ -n "$task_file" ]; then
        cat "$task_file"
    else
        echo "Task '$3' not found."
    fi
fi
# Check for the 'help' command
if [[ "$1" == "help" ]]; then
    display_help
    exit 0
fi