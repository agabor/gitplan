# GitPlan

Hey there! 👋 GitPlan is your friendly command-line buddy for managing tasks and projects, with Git keeping track of all your changes. Think of it as a Kanban board that lives in your terminal!

## What's Cool About It?

- Organize everything into projects (because who doesn't love a good folder structure?)
- See your tasks in a pretty Kanban board right in your browser
- Never lose your work - Git's got your back
- Track how long you spend on tasks (for those pesky time reports)
- Move tasks through states (from "todo" to "done" and everything in between)
- Write task notes in Markdown (because formatting matters!)
- Generate a nice visual board to show off your progress

## Getting Started

1. Grab the code:
```bash
git clone [your-repo-url]
```

2. Create a `config.ini` file (nothing fancy, just two lines):
```ini
root_path=/where/you/want/your/stuff
editor=your-favorite-editor
```

3. Make it executable:
```bash
chmod +x gitplan.sh
```

## How to Use It

### Managing Projects

```bash
# Start a new project
./gitplan.sh project new awesome-project

# See what projects you've got
./gitplan.sh project list

# Clean up old projects
./gitplan.sh project del old-project
```

### Handling Tasks

```bash
# Create something to do
./gitplan.sh task new my-project brilliant-idea

# Check your to-do list
./gitplan.sh task list

# Peek at task details
./gitplan.sh task show my-project brilliant-idea

# Moving things along
./gitplan.sh task state my-project brilliant-idea in-progress

# Done with something?
./gitplan.sh task del my-project finished-task
```

### Track Your Time

```bash
# Clock in
./gitplan.sh work start my-project current-task

# Clock out
./gitplan.sh work end

# See where your time went
./gitplan.sh work log
./gitplan.sh work summary
```

### The Cool Kanban Board

```bash
# See everything
./gitplan.sh board

# Focus on one project
./gitplan.sh board my-project
```

## Task States

Your tasks can be in one of these states:
- `todo` (stuff you need to do)
- `in-progress` (what you're working on)
- `review` (ready for someone to check)
- `done` (🎉 finished!)

## What's Inside a Task?

Tasks are just Markdown files with a little metadata at the top:

```markdown
---
state: todo
created: 2024-11-27 10:00
---

Write your task details here... 
Add links, lists, whatever helps you get things done!
```

## Time Tracking

GitPlan keeps track of your work in a simple CSV file with:
- When you started
- When you finished
- What project and task
- How long it took

## The Board View

Run the board command and you'll get a nice HTML page with:
- All your tasks organized in columns
- Project tags so you know what's what
- A clean, modern look that works on your phone too
- Ready for drag-and-drop (if you want to add that feature!)

## Git Magic

Every time you create, update, or delete something, GitPlan makes a commit. This means:
- You can see how your tasks evolved
- Nothing ever gets lost
- You can share your task board with others
- Easy backups!

## What You Need

- Bash (comes with most Unix-like systems)
- Git (you probably already have this)
- A text editor you like

## Want to Help?

Found a bug? Have an idea for a cool feature? We'd love to see your contributions! Just fork the repo and send us a pull request.

## License

GPL-3.0