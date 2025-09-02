# Task Tracker

📋 **Task Tracker** is a Bash wrapper that integrates [toggl-track](https://github.com/jeromecoloma/toggl-track) and [zendesk-cli](https://github.com/jeromecoloma/zendesk-cli) for seamless time tracking with Zendesk ticket validation and enhanced stop summaries.

## Features

- 🎫 **Zendesk Ticket Validation**: Automatically validates tickets before starting time tracking (can be disabled with `--no-validate`)
- 🏷️ **Customizable Ticket Formatting**: Configure ticket ID prefix/suffix and default subjects
- ⚡ **Toggl Track Integration**: Full passthrough of toggl-track commands with enhanced stop summaries
- 📋 **Smart Stop Summaries**: Formatted time entry summaries with ticket links and clipboard copying
- 🔧 **Dependency Management**: Automatic detection and setup guidance for required tools
- 📱 **Easy Configuration**: Simple init command for interactive setup
- 🌍 **Timezone Support**: Configurable timezone for time entry summaries
- 📎 **Clipboard Integration**: Automatic copying of time summaries to clipboard

## Installation

### Quick Install
```bash
curl -fsSL https://raw.githubusercontent.com/jeromecoloma/task-tracker/main/install.sh | bash
```

### Manual Install
```bash
git clone https://github.com/jeromecoloma/task-tracker.git
cd task-tracker
chmod +x install.sh
./install.sh
```

## Dependencies

Task Tracker requires these tools to be installed:

- **[toggl-track](https://github.com/jeromecoloma/toggl-track)**: For time tracking functionality
  ```bash
  curl -fsSL https://raw.githubusercontent.com/jeromecoloma/toggl-track/main/install.sh | bash
  ```

- **[zendesk-cli](https://github.com/jeromecoloma/zendesk-cli)**: For ticket validation
  ```bash
  curl -fsSL https://raw.githubusercontent.com/jeromecoloma/zendesk-cli/main/install.sh | bash
  ```

## Quick Start

1. **Initialize configuration:**
   ```bash
   task-tracker init
   ```

2. **Configure dependencies** (follow their respective documentation):
   - Set up toggl-track with your API token
   - Set up zendesk-cli with your Zendesk credentials

3. **Start tracking with ticket validation:**
   ```bash
   task-tracker start 12345
   ```

## Usage

### Basic Commands

```bash
# Start time tracking with default subject
task-tracker start 12345

# Start with custom subject
task-tracker start 12345 "Fix login timeout issue"

# Start without zendesk validation
task-tracker start 67890 --no-validate

# Start with additional tags
task-tracker start 12345 --tags "bugfix,urgent"

# Stop current time entry (shows formatted summary)
task-tracker stop

# Check current status
task-tracker status
```

### Advanced Options

```bash
# Start with custom subject, tags, and project
task-tracker start 12345 "Fix login bug" --tags "development,bugfix" --project 987654

# Start with custom subject and skip validation
task-tracker start 12345 "Research task" --no-validate

# All options combined
task-tracker start 12345 "Bug fix" --project 987654 --tags "bugfix" --no-validate
```

### Other Commands

### Enhanced Stop Command

The `stop` command provides rich summaries with:
- Formatted duration (e.g., "2h 30m")
- Timestamp in configured timezone
- Direct Zendesk ticket links
- Automatic clipboard copying
- Support person name attribution

```bash
task-tracker stop
# Output:
# [2h 30m - 2024-01-15 14:30:00, John Smith] - https://company.zendesk.com/agent/tickets/12345 - Fix login bug
# 📋 Copied to clipboard!
```

### Passthrough Commands

All toggl-track commands are supported:

```bash
task-tracker list-workspaces
task-tracker list-projects
task-tracker list-projects-ws 12345
task-tracker proj-id "Project Name"
task-tracker status
```

## Configuration

Task Tracker looks for configuration files in this order:
1. `./.tasktrackerrc` (current directory)
2. `~/.tasktrackerrc` (home directory)
3. `~/.config/task-tracker/.tasktrackerrc` (XDG config)

### Configuration Options

```bash
# Ticket ID formatting
TICKET_PREFIX="#"                    # Prepend to ticket ID (default: "#")
TICKET_SUFFIX=""                     # Append to ticket ID (usually empty)

# Default subject when none provided
DEFAULT_SUBJECT="Ticket Update"      # Used when no subject given

# Stop command summary settings
SUPPORT_NAME="Your Name"             # Name for time summaries
ZENDESK_BASE_URL="https://company.zendesk.com"  # For ticket links
TIMEZONE="Asia/Manila"               # Timezone for timestamps
COPY_TO_CLIPBOARD="true"             # Auto-copy summaries to clipboard
```

### Example Configurations

**GitHub-style tickets:**
```bash
TICKET_PREFIX="#"
TICKET_SUFFIX=""
DEFAULT_SUBJECT="Working on ticket"
# Result: [#12345] Working on ticket
```

**Jira-style tickets:**
```bash
TICKET_PREFIX="PROJ-"
TICKET_SUFFIX=""
DEFAULT_SUBJECT="Development work"
# Result: [PROJ-12345] Development work
```

**Plain numbers:**
```bash
TICKET_PREFIX=""
TICKET_SUFFIX=""
DEFAULT_SUBJECT="Task work"
# Result: [12345] Task work
```

**Complete configuration example:**
```bash
TICKET_PREFIX="#"
DEFAULT_SUBJECT="Ticket Update"
SUPPORT_NAME="John Smith"
ZENDESK_BASE_URL="https://company.zendesk.com"
TIMEZONE="America/New_York"
COPY_TO_CLIPBOARD="true"
```

## How It Works

1. **Ticket ID Processing**: Task Tracker takes a numeric Zendesk ticket ID as the primary argument
2. **Ticket Validation**: Uses zendesk-cli to verify the ticket exists (unless `--no-validate` is used)
3. **Subject Handling**: Uses provided subject or falls back to `DEFAULT_SUBJECT` from config
4. **Formatting**: Applies configured `TICKET_PREFIX` and `TICKET_SUFFIX` to create `[PREFIX12345SUFFIX]`
5. **Toggl Integration**: Passes the formatted description to toggl-track
6. **Stop Summaries**: Enhanced stop command provides formatted time summaries with ticket links

### Example Flows

**Basic start:**
```bash
task-tracker start 12345
```
1. Validates ticket #12345 exists in Zendesk
2. Uses `DEFAULT_SUBJECT` from config: `"Ticket Update"`
3. Formats with `TICKET_PREFIX="#"`: `[#12345] Ticket Update`
4. Calls: `toggl-track start "[#12345] Ticket Update"`

**Start with custom subject:**
```bash
task-tracker start 12345 "Fix login bug"
```
1. Validates ticket #12345 exists in Zendesk
2. Uses provided subject: `"Fix login bug"`
3. Formats: `[#12345] Fix login bug`
4. Calls: `toggl-track start "[#12345] Fix login bug"`

**Enhanced stop:**
```bash
task-tracker stop
```
1. Stops the current toggl-track timer
2. Extracts ticket ID and subject from description
3. Generates formatted summary: `[2h 30m - 2024-01-15 14:30:00, John Smith] - https://company.zendesk.com/agent/tickets/12345 - Fix login bug`
4. Copies summary to clipboard (if enabled)
5. Shows summary in terminal

## Command Reference

### Start Command
```bash
task-tracker start <ticket_id> ["subject"] [options]

Arguments:
  ticket_id           Zendesk ticket ID (required, must be numeric)
  subject             Custom subject for time entry (optional, uses DEFAULT_SUBJECT if not provided)

Options:
  --no-validate       Skip Zendesk ticket validation
  --tags "tag1,tag2"  Add comma-separated tags to the time entry
  --project ID        Set project ID for the time entry
  --help, -h          Show start command help

Examples:
  task-tracker start 12345
  task-tracker start 12345 "Fix login bug"
  task-tracker start 12345 "Code review" --tags "review,development"
  task-tracker start 12345 "Research" --no-validate --project 987654
```

### Global Options
```bash
--help, -h          Show main help
--version, -v       Show version and dependency status
```

### Environment Variables
```bash
TASK_TRACKER_DEBUG=1    # Enable debug output
```

## Development

### Testing
```bash
./test-task-tracker.sh
```

### Project Structure
```
task-tracker/
├── task-tracker              # Main executable script
├── install.sh                # Quick installation script
├── install-local.sh          # Local development installation
├── test-task-tracker.sh      # Test suite
├── .tasktrackerrc.example    # Example configuration file
├── README.md                 # This documentation
└── LICENSE                   # MIT License
```

## Examples

### Daily Workflow
```bash
# Morning: Start working on a bug
task-tracker start 12345 "Fix login timeout"

# Check what's currently running
task-tracker status

# Switch to another ticket
task-tracker stop  # Shows formatted summary with ticket link
task-tracker start 67890 "Code review" --tags "review"

# End of day - stop with summary
task-tracker stop
# Output: [2h 45m - 2024-01-15 17:30:00, John Smith] - https://company.zendesk.com/agent/tickets/67890 - Code review
# ^ Automatically copied to clipboard
```

### Custom Formatting Examples
```bash
# With TICKET_PREFIX="PROJ-" and DEFAULT_SUBJECT="Development work"
task-tracker start 12345
# Results in: "[PROJ-12345] Development work"

# With custom subject
task-tracker start 12345 "Fix critical bug"
# Results in: "[PROJ-12345] Fix critical bug"

# Plain formatting with TICKET_PREFIX=""
task-tracker start 12345 "Research task"
# Results in: "[12345] Research task"
```

## Troubleshooting

### Common Issues

**Dependencies not found:**
```bash
❌ Missing Dependencies
The following required tools are not installed:
  • toggl-track
  • zendesk-cli
```
*Solution:* Install the missing dependencies using the provided curl commands.

**Ticket validation fails:**
```bash
❌ Ticket #12345 not found or inaccessible
```
*Solutions:*
- Check if the ticket exists in Zendesk
- Verify zendesk-cli is properly configured
- Use `--no-validate` flag to skip validation

**Invalid ticket ID:**
```bash
❌ Ticket ID must be numeric: abc
```
*Solution:* Use only numeric ticket IDs (e.g., 12345, not ABC-12345)

**Stop command shows incomplete summary:**
```bash
⚠️ Could not extract time entry details for summary
```
*Solutions:*
- Check if toggl-track is properly configured and working
- Enable debug mode: `TASK_TRACKER_DEBUG=1 task-tracker stop`
- Verify the time entry was created properly with `task-tracker status`

**Configuration not found:**
```bash
⚠️  No task-tracker configuration found
💡 Run 'task-tracker init' to create a configuration file
   Using default settings for now...
```
*Solution:* Run `task-tracker init` to create configuration, or manually create `.tasktrackerrc` file.

### Debug Mode
Enable debug output to troubleshoot configuration loading:
```bash
TASK_TRACKER_DEBUG=1 task-tracker start 12345
```

## License

MIT License - see LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `./test-task-tracker.sh`
5. Submit a pull request

## Related Projects

- [toggl-track](https://github.com/jeromecoloma/toggl-track) - Toggl Track CLI helper
- [zendesk-cli](https://github.com/jeromecoloma/zendesk-cli) - Zendesk command-line interface
