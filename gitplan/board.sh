#!/bin/bash

root_path="$1"
project_filter="$2"
output_file="$root_path/board.html"

# Helper functions (copied from gitplan.sh to make board.sh independent)
get_task_state() {
    local task_file=$1
    if [ -f "$task_file" ]; then
        sed -n '/^---$/,/^---$/p' "$task_file" | grep '^state:' | sed 's/state: *//'
    fi
}

get_task_name() {
    local task_file=$1
    if [ -f "$task_file" ]; then
        sed -n '/^---$/,/^---$/p' "$task_file" | grep '^name:' | sed 's/name: *//'
    fi
}

get_task_tags() {
    local task_file=$1
    if [ -f "$task_file" ]; then
        sed -n '/^---$/,/^---$/p' "$task_file" | grep '^tags:' | sed 's/tags: *//'
    fi
}

read_config() {
    local ini_file=$1
    local key=$2
    awk -F '=' "/^$key=/ {gsub(/^[[:space:]]+|[[:space:]]+$/, \"\", \$2); print \$2}" "$ini_file"
}

get_project_name() {
    local project_dir=$1
    read_config "$project_dir/project.ini" "name"
}

get_task_content() {
    local task_file=$1
    # Skip everything up to and including the second "---" line, 
    # print the rest, and trim leading/trailing whitespace
    awk '
        BEGIN { content = ""; in_content = 0; }
        /^---$/ { 
            if (++count == 2) {
                in_content = 1;
                next;
            }
        }
        in_content {
            if (NF > 0) {  # If line is not empty
                if (content == "") {
                    content = $0;  # First non-empty line
                } else {
                    content = content "\n" $0;  # Subsequent lines
                }
            }
        }
        END {
            if (content != "") print content;
        }
    ' "$task_file"
}

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

        .task-tags {
            margin-top: 8px;
            display: flex;
            gap: 4px;
            flex-wrap: wrap;
        }

        .task-tag {
            font-size: 11px;
            background: #dfe1e6;
            padding: 1px 6px;
            border-radius: 10px;
            color: #44546f;
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
    find_cmd="find \"$root_path\" -name \"*.md\" 2>/dev/null"
    if [ -n "$project_filter" ]; then
        find_cmd="find \"$root_path/$project_filter\" -name \"*.md\" 2>/dev/null"
    fi

    while IFS= read -r task_file; do
        if [ -n "$task_file" ]; then
            # Check if task state matches current column
            task_state=$(get_task_state "$task_file")
            if [ "$task_state" = "$state" ]; then
                project_dir=$(dirname "$task_file")
                project_id=$(basename "$project_dir")
                project_name=$(get_project_name "$project_dir")
                task_name=$(get_task_name "$task_file")
                task_content=$(get_task_content "$task_file")
                task_tags=$(get_task_tags "$task_file")
                
                # Add task to column
                cat >> "$output_file" << EOF
                <div class="task">
                    <div class="project-tag">${project_name:-$project_id}</div>
                    <div><strong>${task_name}</strong></div>
EOF

                # Add tags if they exist
                if [ -n "$task_tags" ]; then
                    echo "<div class=\"task-tags\">" >> "$output_file"
                    for tag in $task_tags; do
                        echo "<span class=\"task-tag\">$tag</span>" >> "$output_file"
                    done
                    echo "</div>" >> "$output_file"
                fi

                cat >> "$output_file" << EOF
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