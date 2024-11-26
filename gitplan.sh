#!/bin/bash

# Function to generate HTML board
generate_board() {
    local project_filter="$1"
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

        .board-header {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 20px 10px 20px;
            color: #172b4d;
        }
</style>
</head>
<body>
EOF

    # Add board header with project filter if specified
    if [ -n "$project_filter" ]; then
        cat >> "$output_file" << EOF
    <div class="board-header">
        <h2>Project: $project_filter</h2>
    </div>
EOF
    fi

    # Start board div
    echo '<div class="board">' >> "$output_file"

    # Create columns for each state
    for state in "todo" "in-progress" "review" "done"; do
        # Start column
        cat >> "$output_file" << EOF
        <div class="column">
            <div class="column-header">${state}</div>
            <div class="task-list">
EOF

        # Find all tasks for this state
        local find_cmd="find \"$root_path\" -name \"*.md\" 2>/dev/null"
        if [ -n "$project_filter" ]; then
            find_cmd="find \"$root_path/$project_filter\" -name \"*.md\" 2>/dev/null"
        fi

    while IFS= read -r task_file; do
        if [ -n "$task_file" ]; then
            # Check if task state matches current column
            task_state=$(get_task_state "$task_file")
            if [ "$task_state" = "$state" ]; then
                project_name=$(basename "$(dirname "$task_file")")
                task_name=$(get_task_name "$task_file")
                task_content=$(sed '1,/^---$/d' "$task_file" | sed '1d')
                
                # Add task to column
                cat >> "$output_file" << EOF
                <div class="task">
                    <div class="project-tag">$project_name</div>
                    <div>$task_name</div>
                    <div class="task-content">$task_content</div>
                </div>
EOF
            fi
        fi
    done < <(eval "$find_cmd")

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
}
# Function to get git user name in kebab case
get_git_user_name() {
    local git_name=$(git config --global user.name)
    # Convert to lowercase, replace spaces with hyphens, remove special characters
    echo "$git_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g'
}

# Function to get worklog path
get_worklog_path() {
    local user_name=$(get_git_user_name)
    echo "$root_path/${user_name}-worklog.csv"
}

# Function to validate CSV file existence and create if needed
init_worklog() {
    local worklog=$(get_worklog_path)
    if [ ! -f "$worklog" ]; then
        echo "start_time,end_time,project,task,duration_minutes" > "$worklog"
        commit "Initialize worklog for $(git config --global user.name)"
    fi
}

# Function to get current work state
get_active_work() {
    local worklog=$(get_worklog_path)
    # Look for the most recent entry with empty end_time
    tail -n +2 "$worklog" | awk -F',' '$2==""' | tail -n 1
}

# Function to start work on a task
start_work() {
    local project_name=$1
    local task_id=$2
    local worklog=$(get_worklog_path)
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Check if already working on something
    local active_work=$(get_active_work)
    if [ -n "$active_work" ]; then
        echo "Already working on a task. Please end current work session first."
        echo "$active_work"
        exit 1
    fi
    
    # Find task file and get display name
    local task_file=$(find_task_in_project "$project_name" "$task_id")
    if [ -z "$task_file" ]; then
        echo "Task '$task_id' not found in project '$project_name'."
        exit 1
    fi
    
    local task_name=$(get_task_name "$task_file")
    
    # Log work start with empty end_time and duration
    echo "$timestamp,,$project_name,$task_name," >> "$worklog"
    commit "Start work on $project_name/$task_name"
    
    echo "Started working on task '$task_name' in project '$project_name'"
    update_task_state "$project_name" "$task_id" "in-progress"
}

datetime_to_timestamp() {
    date -d "$1" +%s
}

# Function to end work on a task
end_work() {
    local worklog=$(get_worklog_path)
    
    # Get active work session
    local active_work=$(get_active_work)
    if [ -z "$active_work" ]; then
        echo "No active work session found."
        exit 1
    fi
    
    # Parse active work data
    local start_time=$(echo "$active_work" | cut -d',' -f1)
    local project_name=$(echo "$active_work" | cut -d',' -f3)
    local task_name=$(echo "$active_work" | cut -d',' -f4)
    
    # Calculate duration and format end time
    local end_time=$(date '+%Y-%m-%d %H:%M:%S')
    local start_seconds=$(datetime_to_timestamp "$start_time")
    local end_seconds=$(datetime_to_timestamp "$end_time")
    if [ -z "$start_seconds" ] || [ -z "$end_seconds" ]; then
        echo "Error converting timestamps"
        exit 1
    fi
    local duration_minutes=$(( ($end_seconds - $start_seconds + 30) / 60 ))
    
    # Create new worklog with updated last entry
    local temp_file=$(mktemp)
    sed "\$d" "$worklog" > "$temp_file"  # Delete last line while preserving header
    echo "$start_time,$end_time,$project_name,$task_name,$duration_minutes" >> "$temp_file"
    mv "$temp_file" "$worklog"
    
    commit "End work on $project_name/$task_name"
    
    echo "Ended work session on task '$task_name' in project '$project_name'"
    echo "Duration: $duration_minutes minutes"
}

# Function to show work log
show_worklog() {
    local project_filter=$1
    local worklog=$(get_worklog_path)
    
    if [ ! -f "$worklog" ]; then
        echo "No work log found for $(git config --global user.name)."
        exit 1
    fi
    
    if [ -n "$project_filter" ]; then
        echo "Work log for project '$project_filter' ($(git config --global user.name)):"
        grep ",$project_filter," "$worklog"
    else
        echo "Complete work log for $(git config --global user.name):"
        cat "$worklog"
    fi
}

# Function to summarize work
summarize_work() {
    local project_filter=$1
    local worklog=$(get_worklog_path)
    
    if [ ! -f "$worklog" ]; then
        echo "No work log found for $(git config --global user.name)."
        exit 1
    fi
    
    echo "Work Summary for $(git config --global user.name):"
    if [ -n "$project_filter" ]; then
        echo "Project: $project_filter"
        awk -F',' -v project="$project_filter" '
            $3 == project && $5 != "" {  # Only count completed sessions
                tasks[$4] += $5
                total += $5
            }
            END {
                print "\nTotal time: " total " minutes"
                print "\nTime per task:"
                for (task in tasks) {
                    print task ": " tasks[task] " minutes"
                }
            }
        ' "$worklog"
    else
        awk -F',' '
            NR>1 && $5 != "" {  # Only count completed sessions
                projects[$3] += $5
                total += $5
            }
            END {
                print "\nTotal time: " total " minutes"
                print "\nTime per project:"
                for (project in projects) {
                    print project ": " projects[project] " minutes"
                }
            }
        ' "$worklog"
    fi
}
# Function to read config values from ini file
read_config() {
    local ini_file=$1
    local key=$2
    awk -F '=' "/^$key=/ {gsub(/^[[:space:]]+|[[:space:]]+$/, \"\", \$2); print \$2}" "$ini_file"
}

# Read configuration
ini_file="config.ini"
root_path=$(read_config "$ini_file" "root_path")
editor=$(read_config "$ini_file" "editor" || echo "${EDITOR:-vim}")  # Default to $EDITOR or vim

commit() {
    cd "$root_path"
    git add . > /dev/null 2>&1
    git commit -m "$1" > /dev/null 2>&1
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
    local task_id=$2
    local project_dir="$root_path/$project_name"
    
    if [ ! -d "$project_dir" ]; then
        echo ""
        return 1
    fi
    
    local task_file=$(find "$project_dir" -name "${task_id}.md" 2>/dev/null | head -n 1)
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


# Function to get task state from front matter
get_task_state() {
    local task_file=$1
    if [ -f "$task_file" ]; then
        # Extract state from front matter between first two "---" lines
        sed -n '/^---$/,/^---$/p' "$task_file" | grep '^state:' | sed 's/state: *//'
    fi
}

# Function to update task state in front matter
update_task_front_matter() {
    local task_file=$1
    local new_state=$2
    local temp_file=$(mktemp)
    
    if [ -f "$task_file" ]; then
        # Check if file already has front matter
        if grep -q '^---$' "$task_file"; then
            # Update existing front matter
            awk -v state="$new_state" '
                BEGIN { in_front_matter=0; state_updated=0 }
                /^---$/ { 
                    print; 
                    if (++in_front_matter == 1) { next }
                }
                in_front_matter == 1 {
                    if ($0 ~ /^state:/) {
                        print "state:", state;
                        state_updated=1;
                        next;
                    }
                    if ($0 !~ /^---$/) {
                        print;
                        next;
                    }
                }
                in_front_matter != 1 { print }
                END {
                    if (in_front_matter == 1 && !state_updated) {
                        print "state:", state;
                        print "---";
                    }
                }
            ' "$task_file" > "$temp_file"
        else
            # Add new front matter
            echo "---" > "$temp_file"
            echo "state: $new_state" >> "$temp_file"
            echo "---" >> "$temp_file"
            cat "$task_file" >> "$temp_file"
        fi
        mv "$temp_file" "$task_file"
    fi
}

create_new_task() {
    local project_name=$1
    local task_name=$2
    local state=${3:-todo}  # Default state is 'todo' if not specified
    
    if ! validate_state "$state"; then
        echo "Invalid state. Valid states are: todo, in-progress, review, done"
        exit 1
    fi
    
    # Create a sanitized identifier from the task name
    local task_id=$(echo "$task_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
    
    local project_dir="$root_path/$project_name"
    local task_file="$project_dir/${task_id}.md"
    
    # Create initial content with front matter
    cat > "$task_file" << EOF
---
state: $state
created: $(date '+%Y-%m-%d %H:%M')
name: $task_name
---

EOF
    
    # Open in editor for editing
    $editor "$task_file"
    
    if [ -f "$task_file" ]; then
        commit "Create task '$task_name' in project '$project_name'"
        return 0
    else
        echo "Task creation cancelled."
        return 1
    fi
}


# Function to get task display name from front matter
get_task_name() {
    local task_file=$1
    if [ -f "$task_file" ]; then
        sed -n '/^---$/,/^---$/p' "$task_file" | grep '^name:' | sed 's/name: *//'
    fi
}

list_tasks() {
    local project_name=$1
    
    if [ -n "$project_name" ]; then
        local project_dir="$root_path/$project_name"
        
        if [ -d "$project_dir" ]; then
            echo "Tasks for project '$project_name':"
            find "$project_dir" -name "*.md" 2>/dev/null | while read -r task_file; do
                task_name=$(get_task_name "$task_file")
                state=$(get_task_state "$task_file")
                echo "- $task_name [$state]"
            done
        else
            echo "Project '$project_name' does not exist."
        fi
    else
        echo "Tasks for all projects:"
        find "$root_path" -name "*.md" 2>/dev/null | while read -r task_file; do
            project_name=$(basename "$(dirname "$task_file")")
            if [ "$project_name" != ".git" ]; then
                task_name=$(get_task_name "$task_file")
                state=$(get_task_state "$task_file")
                echo "- [$project_name] $task_name [$state]"
            fi
        done
    fi
}

update_task_state() {
    local project_name=$1
    local task_id=$2
    local new_state=$3
    
    if ! validate_state "$new_state"; then
        echo "Invalid state. Valid states are: todo, in-progress, review, done"
        exit 1
    fi
    
    local task_file=$(find_task_in_project "$project_name" "$task_id")
    
    if [ ! -f "$task_file" ]; then
        echo "Task '$task_id' not found in project '$project_name'."
        exit 1
    fi
    
    update_task_front_matter "$task_file" "$new_state"
    local task_name=$(get_task_name "$task_file")
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
    if [[ -n "$2" ]]; then
        # Check if the specified project exists
        if [ -d "$root_path/$2" ]; then
            generate_board "$2"
        else
            echo "Project '$2' does not exist."
            exit 1
        fi
    else
        generate_board
    fi
    exit 0
fi
# Main command processing

if [[ "$1" == "work" ]]; then
    init_worklog
    if [[ "$2" == "start" && -n "$3" && -n "$4" ]]; then
        start_work "$3" "$4"
        exit 0
    elif [[ "$2" == "end" ]]; then
        end_work
        exit 0
    elif [[ "$2" == "log" ]]; then
        show_worklog "$3"
        exit 0
    elif [[ "$2" == "summary" ]]; then
        summarize_work "$3"
        exit 0
    fi
fi

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
            echo "Task '$4' deleted from project '$3'"
            commit "Deleted task '$4' from project '$3'"
            exit 0
        else
            echo "Task '$4' not found in project '$3'."
            exit 1
        fi
    elif [[ "$2" == "new" && -n "$3" && -n "$4" ]]; then
        create_new_task "$3" "$4" "$5"
        exit 0
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