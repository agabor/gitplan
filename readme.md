# GitPlan

GitPlan is a lightweight, git-based task management system that operates entirely within a git repository. No database, no server, no backend required - just git and bash.

## Features

- **100% Git-Based**: All data is stored in markdown files and tracked with git
- **Zero Backend**: No servers, no databases, just files in a git repo
- **Kanban Board**: Generate a static HTML board view of your tasks
- **Time Tracking**: Built-in work logging and time summaries
- **Project Organization**: Group tasks by project
- **State Management**: Track task progress through todo → in-progress → review → done
- **Task Tagging**: Organize and filter tasks using tags
- **Markdown Support**: Write task details in markdown format
- **Command Line Interface**: Fast and efficient task management from your terminal

## Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/gitplan.git
cd gitplan
```

2. Make the script executable:
```bash
chmod +x gitplan.sh
```

3. Run the script - it will guide you through configuration on first run:
```bash
./gitplan.sh
```
The configuration process will ask for:
- Root path for Git Plan data
- Your preferred editor (defaults to vim)

This creates a config file at `$HOME/.gitplan/config.ini` or `./config.ini` if run from the current directory.

4. Optional: Add to your PATH for system-wide access

## Usage

### Project Management

```bash
# Create a new project
./gitplan.sh project new my-project

# List all projects
./gitplan.sh project list

# Delete a project
./gitplan.sh project del my-project
```

### Task Management

```bash
# Create a new task
./gitplan.sh task new my-project "Implement feature X"

# List tasks
./gitplan.sh task list  # all tasks
./gitplan.sh task list my-project  # project tasks
./gitplan.sh task list my-project backend  # filter by tag

# Edit a task
./gitplan.sh task edit my-project implement-feature-x

# Update task state
./gitplan.sh task state my-project implement-feature-x in-progress

# Show task details
./gitplan.sh task show my-project implement-feature-x

# Delete task
./gitplan.sh task del my-project implement-feature-x
```

### Tag Management

```bash
# List all tags in use
./gitplan.sh tag

# List all tasks with a specific tag
./gitplan.sh tag list backend

# List project tasks with a specific tag
./gitplan.sh task list my-project backend
```

### Work Logging

```bash
# Start working on a task
./gitplan.sh work start my-project implement-feature-x

# End current work session
./gitplan.sh work end

# View work log
./gitplan.sh work log
./gitplan.sh work log my-project  # filtered by project

# View work summary
./gitplan.sh work summary
./gitplan.sh work summary my-project  # filtered by project
```

### Kanban Board

```bash
# Generate board for all projects
./gitplan.sh board

# Generate board for specific project
./gitplan.sh board my-project
```

## Task Structure

Tasks are stored as markdown files with front matter:

```markdown
---
state: todo
created: 2024-11-27 10:00
name: Implement Feature X
tags: backend security sprint-1
---

Task details go here in markdown format.

- [ ] Subtask 1
- [ ] Subtask 2
```

## Storage Structure

```
root_path/
├── project1/
│   ├── project.ini
│   ├── task-1.md
│   └── task-2.md
├── project2/
│   ├── project.ini
│   └── another-task.md
└── username-worklog.csv
```

## Git Integration

GitPlan automatically commits changes to your git repository, creating a complete history of your task management:

- Task creation and deletion
- State changes
- Work log entries
- Project creation and deletion
- Tag modifications

## Why GitPlan?

- **Portable**: Your entire task management system lives in a git repo
- **Simple**: No complex setup, just clone and start using
- **Offline-First**: Works without internet connection
- **Version Controlled**: Full history of all changes
- **Text-Based**: Easy to script and integrate with other tools
- **No Lock-In**: Your data is just markdown files in a git repo
- **Collaborative**: Share tasks via git push/pull
- **Private**: Your data stays in your git repo

## Dependencies

- Git
- Bash
- Text editor (vim by default, configurable)

## License

GPL-3.0