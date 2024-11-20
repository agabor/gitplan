#!/bin/bash

# Function to generate HTML board
generate_board() {
    local output_file="$root_path/board.html"
    
    # Create HTML content
    cat > "$output_file" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            line-height: 1.6;
            background: #f0f2f5;
            padding: 20px;
        }

        .board {
            display: flex;
            gap: 20px;
            margin: 0 auto;
            padding: 20px;
            max-width: 1200px;
        }

        .column {
            background: #ebecf0;
            border-radius: 8px;
            width: 300px;
            padding: 12px;
        }

        .column-header {
            padding: 8px;
            font-weight: bold;
            color: #172b4d;
            margin-bottom: 12px;
        }

        .task-list {
            min-height: 100px;
        }

        .task {
            background: white;
            padding: 12px;
            border-radius: 6px;
            margin-bottom: 8px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.12);
            cursor: move;
        }

        .task:hover {
            background: #f8f9fa;
        }

        .project-tag {
            font-size: 12px;
            background: #e9ecef;
            padding: 2px 6px;
            border-radius: 3px;
            color: #5e6c84;
            margin-bottom: 4px;
            display: inline-block;
        }

        .task-content {
            margin-top: 4px;
            white-space: pre-wrap;
        }
    </style>
</head>
<body>
    <div class="board">
EOF

    # Create columns for each state
    for state in "todo" "in-progress" "review" "done"; do
        # Start column
        cat >> "$output_file" << EOF
        <div class="column">
            <div class="column-header">${state}</div>
            <div class="task-list">
EOF

        # Find all tasks for this state
        while IFS= read -r task_file; do
            if [ -n "$task_file" ]; then
                project_name=$(basename "$(dirname "$task_file")")
                task_name=$(basename "$task_file")
                base_name=$(get_task_base_name "$task_name")
                task_content=$(cat "$task_file")
                
                # Add task to column
                cat >> "$output_file" << EOF
                <div class="task">
                    <div class="project-tag">$project_name</div>
                    <div>$base_name</div>
                    <div class="task-content">$task_content</div>
                </div>
EOF
            fi
        done < <(find "$root_path" -name "*-${state}.md" 2>/dev/null)

        # Close column
        cat >> "$output_file" << EOF
            </div>
        </div>
EOF
    done

    # Close HTML
    cat >> "$output_file" << 'EOF'
    </div>
</body>
</html>
EOF

    echo "Board generated at: $output_file"
}

# Function to display help information
display_help() {
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
}

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

commit() {
    cd "$root_path"
    git add .
    git commit -m "$1"
}

# Validate state
validate_state() {
    local state=$1
    case $state in
        todo|in-progress|review|done)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to get task base name (without state)
get_task_base_name() {
    local full_name=$1
    echo "$full_name" | sed -E 's/-*(todo|in-progress|review|done)*\.md$//'
}

# Function to find task file in project
find_task_in_project() {
    local project_name=$1
    local task_name=$2
    local project_dir="$root_path/$project_name"
    
    if [ ! -d "$project_dir" ]; then
        echo ""
        return 1
    fi
    
    local task_file=$(find "$project_dir" -name "${task_name}*.md" 2>/dev/null | head -n 1)
    echo "$task_file"
}

# Function to create a new project
create_new_project() {
    local project_name=$1
    local project_dir="$root_path/$project_name"
    
    mkdir -p "$project_dir"
    touch "$project_dir/project.ini"
    if [ -n "$2" ]; then
        echo "client=$2" >> "$project_dir/project.ini"
    else
        echo "client=$1" >> "$project_dir/project.ini"
    fi
    echo "Project '$project_name' created at '$project_dir'"
    commit "Create project '$project_name'"
}

# Function to list all tasks for a given project or all projects
list_tasks() {
    local project_name=$1
    
    if [ -n "$project_name" ]; then
        local project_dir="$root_path/$project_name"
        
        if [ -d "$project_dir" ]; then
            echo "Tasks for project '$project_name':"
            ls "$project_dir"/*.md 2>/dev/null | while read -r task_file; do
                task_name=$(basename "$task_file")
                state=$(echo "$task_name" | grep -oE '-(todo|in-progress|review|done)\.md$' | sed 's/[-.]//g')
                base_name=$(get_task_base_name "$task_name")
                echo "- $base_name [$state]"
            done
        else
            echo "Project '$project_name' does not exist."
        fi
    else
        echo "Tasks for all projects:"
        find "$root_path" -name "*.md" 2>/dev/null | while read -r task_file; do
            task_name=$(basename "$task_file")
            project_name=$(basename "$(dirname "$task_file")")
            if [ "$project_name" != ".git" ]; then
                state=$(echo "$task_name" | grep -oE '-(todo|in-progress|review|done)\.md$' | sed 's/[-.]//g')
                base_name=$(get_task_base_name "$task_name")
                echo "- [$project_name] $base_name [$state]"
            fi
        done
    fi
}

# Function to update task state
update_task_state() {
    local project_name=$1
    local task_name=$2
    local new_state=$3
    
    if ! validate_state "$new_state"; then
        echo "Invalid state. Valid states are: todo, in-progress, review, done"
        exit 1
    fi
    
    local task_file=$(find_task_in_project "$project_name" "$task_name")
    
    if [ -z "$task_file" ]; then
        echo "Task '$task_name' not found in project '$project_name'."
        exit 1
    fi
    
    local task_dir=$(dirname "$task_file")
    local base_name=$(get_task_base_name "$(basename "$task_file")")
    local new_file="$task_dir/${base_name}-${new_state}.md"
    
    mv "$task_file" "$new_file"
    echo "Updated task state to '$new_state'"
    commit "Update task '$task_name' state to '$new_state' in project '$project_name'"
}

# Function to list all projects
list_projects() {
    echo "Projects:"
    find "$root_path" -mindepth 1 -maxdepth 1 -type d | while read -r project_dir; do
        project_name=$(basename "$project_dir")
        if [ "$project_name" != ".git" ]; then
            echo "- $project_name"
        fi
    done
}
if [[ "$1" == "board" ]]; then
    generate_board
    exit 0
fi
# Main command processing
if [[ "$1" == "task" ]]; then
    if [[ "$2" == "list" ]]; then
        list_tasks "$3"
        exit 0
    elif [[ "$2" == "show" && -n "$3" && -n "$4" ]]; then
        task_file=$(find_task_in_project "$3" "$4")
        
        if [ -n "$task_file" ]; then
            cat "$task_file"
            exit 0
        else
            echo "Task '$4' not found in project '$3'."
            exit 1
        fi
    elif [[ "$2" == "state" && -n "$3" && -n "$4" && -n "$5" ]]; then
        update_task_state "$3" "$4" "$5"
        exit 0
    elif [[ "$2" == "del" && -n "$3" && -n "$4" ]]; then
        task_file=$(find_task_in_project "$3" "$4")
        
        if [ -n "$task_file" ]; then
            rm "$task_file"
            echo "Task '$4' deleted from project '$3'."
            commit "Deleted task '$4' from project '$3'"
            exit 0
        else
            echo "Task '$4' not found in project '$3'."
            exit 1
        fi
    elif [[ "$2" == "new" && -n "$3" && -n "$4" ]]; then
        project_name=$3
        project_dir="$root_path/$project_name"
        
        if [ ! -d "$project_dir" ]; then
            echo "Project '$project_name' does not exist."
            exit 1
        fi
        
        task_name=$4
        state=${5:-todo}  # Default state is 'todo' if not specified
        
        if ! validate_state "$state"; then
            echo "Invalid state. Valid states are: todo, in-progress, review, done"
            exit 1
        fi
        
        task_rel_path="$project_name/$task_name-$state.md"
        task_file="$root_path/$task_rel_path"

        echo $task_file
        
        vim $task_file
        
        if [ -f "$task_file" ]; then
            commit "Create task '$task_rel_path'"
            exit 0
        else
            echo "Task creation cancelled."
            exit 1
        fi
    fi
elif [[ "$1" == "project" ]]; then
    if [[ "$2" == "new" && -n "$3" ]]; then
        create_new_project "$3" "$4"
        exit 0
    elif [[ "$2" == "list" ]]; then
        list_projects
        exit 0
    elif [[ "$2" == "del" && -n "$3" ]]; then
        project_name=$3
        project_dir="$root_path/$project_name"
        
        if [ -d "$project_dir" ]; then
            rm -rf "$project_dir"
            echo "Project '$project_name' deleted."
            commit "Deleted project '$project_name'"
            exit 0
        else
            echo "Project '$project_name' does not exist."
            exit 1
        fi
    fi
fi

display_help