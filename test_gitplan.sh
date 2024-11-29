#!/bin/bash

# Colors for test output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Create dummy editor script
create_dummy_editor() {
    cat > "$TEST_ROOT/dummy-editor" << 'EOF'
#!/bin/bash
file="$1"
# If test content environment variable is set, use it
if [ -n "$TEST_CONTENT" ]; then
    echo "$TEST_CONTENT" >> "$file"
else
    echo "Test task content" >> "$file"
fi
EOF
    chmod +x "$TEST_ROOT/dummy-editor"
}

# Setup test environment
setup_test_env() {
    # Create temporary directory for tests
    TEST_ROOT=$(mktemp -d)
    
    # Create dummy editor
    create_dummy_editor
    
    # Create config file with test settings
    cat > config.ini << EOF
root_path=$TEST_ROOT
editor=$TEST_ROOT/dummy-editor
EOF
    
    # Initialize git repository (suppress output)
    cd "$TEST_ROOT" > /dev/null 2>&1
    git init > /dev/null 2>&1
    git config user.name "Test User" > /dev/null 2>&1
    git config user.email "test@example.com" > /dev/null 2>&1
    
    # Initial commit (suppress output)
    touch .gitkeep
    git add .gitkeep > /dev/null 2>&1
    git commit -m "Initial commit" > /dev/null 2>&1
    
    # Rename master branch to main if needed (suppress output)
    git branch -m main > /dev/null 2>&1
    cd -
}

# Cleanup test environment
cleanup_test_env() {
    rm -rf "$TEST_ROOT"
    rm config.ini
}

# Test helper function
assert() {
    local message=$1
    local command=$2
    local expected_output=$3
    local expected_exit_code=${4:-0}
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    # Run command and capture output and exit code
    output=$(eval "$command" 2>&1)
    exit_code=$?
    
    # Compare output and exit code
    if [[ "$output" == "$expected_output" && $exit_code -eq $expected_exit_code ]]; then
        echo -e "${GREEN}✓ $message${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ $message${NC}"
        echo "Expected output: $expected_output"
        echo "Actual output: $output"
        echo "Expected exit code: $expected_exit_code"
        echo "Actual exit code: $exit_code"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test project management
test_project_management() {
    echo "Testing project management..."
    
    # Test project creation
    assert "Create new project" \
        "./gitplan.sh project new test-project 'Test Project'" \
        "Project 'test-project' created at '$TEST_ROOT/test-project'"
    
    # Test project listing
    assert "List projects" \
        "./gitplan.sh project list" \
        "Projects:
- [test-project] Test Project"
    
    # Test project deletion
    assert "Delete project" \
        "./gitplan.sh project del test-project" \
        "Project 'test-project' deleted."
    
    # Test deleting non-existent project
    assert "Delete non-existent project" \
        "./gitplan.sh project del nonexistent" \
        "Project 'nonexistent' does not exist." \
        1
}

# Test task management with custom content
test_task_management() {
    echo "Testing task management..."
    
    # Create test project
    ./gitplan.sh project new test-project >/dev/null
    
    # Test task creation with specific content
    export TEST_CONTENT="Custom task content for testing"
    assert "Create new task" \
        "./gitplan.sh task new test-project test-task" \
        ""
    unset TEST_CONTENT
    
    # Verify task front matter and content
    assert "Check task front matter and content" \
        "cat '$TEST_ROOT/test-project/test-task.md'" \
        "---
state: todo
created: $(date '+%Y-%m-%d %H:%M')
name: test-task
tags:
---

Custom task content for testing"
    
    # Test task listing
    assert "List tasks in project" \
        "./gitplan.sh task list test-project" \
        "Tasks for project 'test-project':
- [test-project/test-task] test-task [todo]"
    
    # Test task state update
    assert "Update task state" \
        "./gitplan.sh task state test-project test-task in-progress" \
        "Updated task state to 'in-progress'"
    
    # Verify state update
    assert "Check updated task state" \
        "grep 'state:' '$TEST_ROOT/test-project/test-task.md'" \
        "state: in-progress"
    
    # Test task deletion
    assert "Delete task" \
        "./gitplan.sh task del test-project test-task" \
        "Task 'test-task' deleted from project 'test-project'"
}

# Test editor configuration
test_editor_config() {
    echo "Testing editor configuration..."
    
    # Test with custom editor content
    export TEST_CONTENT="Content from custom editor"
    
    # Create test project
    ./gitplan.sh project new editor-test >/dev/null
    
    # Create task with custom editor
    assert "Create task with custom editor" \
        "./gitplan.sh task new editor-test editor-task" \
        ""
    
    # Verify custom editor was used
    assert "Verify custom editor content" \
        "grep 'Content from custom editor' '$TEST_ROOT/editor-test/editor-task.md'" \
        "Content from custom editor"
    
    unset TEST_CONTENT
}

# Test work logging
test_work_logging() {
    echo "Testing work logging..."
    
    # Create test project and task
    ./gitplan.sh project new test-project >/dev/null
    echo "Test task content" > "$TEST_ROOT/test-project/test-task.md"
    ./gitplan.sh task new test-project test-task >/dev/null
    
    # Test work start
    assert "Start work on task" \
        "./gitplan.sh work start test-project test-task" \
        $'Started working on task \'test-task\' in project \'test-project\'\nUpdated task state to \'in-progress\''
    
    # Verify task state changed to in-progress
    assert "Check task state after work start" \
        "grep 'state:' '$TEST_ROOT/test-project/test-task.md'" \
        "state: in-progress"
    
    # Wait a moment to ensure measurable duration
    sleep 2
    
    # Test work end
    work_end_output=$(./gitplan.sh work end)
    assert "End work on task" \
        "echo \"$work_end_output\" | head -n 1" \
        "Ended work session on task 'test-task' in project 'test-project'"
    
    
    # Test work summary
    assert "Generate work summary" \
        "./gitplan.sh work summary test-project | grep -o 'Total time:.*minutes'" \
        "Total time: 0 minutes"
}

# Test board generation
test_board_generation() {
    echo "Testing board generation..."
    
    # Create test project and tasks
    ./gitplan.sh project new test-project >/dev/null
    
    # Create tasks in different states
    for state in todo in-progress review done; do
        echo "Task in $state state" > "$TEST_ROOT/test-project/task-${state}.md"
        cat > "$TEST_ROOT/test-project/task-${state}.md" << EOF
---
state: $state
created: $(date '+%Y-%m-%d %H:%M')
---
Task in $state state
EOF
    done
    
    # Generate board
    assert "Generate board" \
        "./gitplan.sh board test-project" \
        "Board generated at: $TEST_ROOT/board.html"
    
}

# Run all tests
run_tests() {
    echo "Starting tests..."
    setup_test_env
    
    # Store original commit function
    if declare -f commit > /dev/null; then
        eval "original_commit() $(declare -f commit)"
    fi
    
    # Override commit function to suppress output
    commit() {
        cd "$TEST_ROOT" > /dev/null 2>&1
        git add . > /dev/null 2>&1
        git commit -m "$1" > /dev/null 2>&1
    }
    
    test_project_management
    test_task_management
    test_editor_config
    test_work_logging
    test_board_generation
    
    # Restore original commit function if it existed
    if declare -f original_commit > /dev/null; then
        eval "commit() $(declare -f original_commit)"
        unset -f original_commit
    fi
    
    echo
    echo "Test Summary:"
    echo "Tests run: $TESTS_RUN"
    echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
    
    cleanup_test_env
    
    # Return non-zero exit code if any tests failed
    [ $TESTS_FAILED -eq 0 ]
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi