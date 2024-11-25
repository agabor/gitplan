#!/bin/bash

# Colors for test output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Setup test environment
setup_test_env() {
    # Create temporary directory for tests
    TEST_ROOT=$(mktemp -d)
    echo "root_path=$TEST_ROOT" > config.ini
    
    # Initialize git repository
    cd "$TEST_ROOT"
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"
    
    # Initial commit
    touch .gitkeep
    git add .gitkeep
    git commit -m "Initial commit"
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
        "./gitplan.sh project new test-project" \
        "Project 'test-project' created at '$TEST_ROOT/test-project'"
    
    # Test project listing
    assert "List projects" \
        "./gitplan.sh project list" \
        "Projects:
- test-project"
    
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

# Test task management
test_task_management() {
    echo "Testing task management..."
    
    # Create test project
    ./gitplan.sh project new test-project >/dev/null
    
    # Test task creation (simulating vim input)
    echo "Test task content" > "$TEST_ROOT/test-project/test-task.md"
    assert "Create new task" \
        "./gitplan.sh task new test-project test-task" \
        ""
    
    # Verify task front matter
    assert "Check task front matter" \
        "grep -A 2 '^---$' '$TEST_ROOT/test-project/test-task.md' | head -n 3" \
        "---
state: todo
created: $(date '+%Y-%m-%d')"
    
    # Test task listing
    assert "List tasks in project" \
        "./gitplan.sh task list test-project" \
        "Tasks for project 'test-project':
- test-task [todo]"
    
    # Test task state update
    assert "Update task state" \
        "./gitplan.sh task state test-project test-task in-progress" \
        "Updated task state to 'in-progress'"
    
    # Verify state update
    assert "Check updated task state" \
        "grep 'state:' '$TEST_ROOT/test-project/test-task.md'" \
        "state: in-progress"
    
    # Test task content display
    assert "Show task content" \
        "./gitplan.sh task show test-project test-task" \
        "Test task content"
    
    # Test task deletion
    assert "Delete task" \
        "./gitplan.sh task del test-project test-task" \
        "Task 'test-task' deleted from project 'test-project'"
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
        "Started working on task 'test-task' in project 'test-project'"
    
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
    
    # Test work log
    assert "Check work log exists" \
        "test -f \"$TEST_ROOT/test-user-worklog.csv\" && echo 'Worklog exists'" \
        "Worklog exists"
    
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
created: $(date '+%Y-%m-%d %H:%M:%S')
---
Task in $state state
EOF
    done
    
    # Generate board
    assert "Generate board" \
        "./gitplan.sh board test-project" \
        "Board generated at: $TEST_ROOT/board.html"
    
    # Verify board file exists and contains all states
    assert "Check board file exists and contains states" \
        "grep -c 'column-header' '$TEST_ROOT/board.html'" \
        "4"
}

# Run all tests
run_tests() {
    echo "Starting tests..."
    setup_test_env
    
    test_project_management
    test_task_management
    test_work_logging
    test_board_generation
    
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