#!/bin/bash

output_file="$1/board.html"
project_filter="$2"
    
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
    find_cmd="find \"$root_path\" -name \"*.md\" 2>/dev/null"
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