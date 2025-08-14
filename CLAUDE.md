# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ClaudeScheduler is a MCP (Model Context Protocol) server management utility that provides scripts for configuring and managing various MCP servers for both Claude Code and Crush development environments.

## Architecture

The project consists of three main shell scripts in the `scripts/` directory:

- **setup-mcp.sh**: Main MCP server configuration script for Claude Desktop
- **setup-mcp-crush.sh**: MCP server configuration script for Crush environments  
- **websearch-manager.sh**: Unified management script for the Open-WebSearch MCP server

### Key Components

#### setup-mcp.sh
- Configures essential MCP servers: Playwright, Octocode, BrowserMCP
- Optional servers: GitHub, Chrome AppleScript (macOS), Computer Use, Open-WebSearch
- Interactive installation with safety prompts for potentially dangerous servers
- Uses `claude mcp` CLI commands to configure servers

#### setup-mcp-crush.sh  
- Similar functionality to setup-mcp.sh but outputs to JSON configuration files
- Creates/manages `crush.json` configuration files
- Uses `jq` for JSON manipulation
- Supports listing, removing, and adding MCP servers to JSON config

#### websearch-manager.sh
- Manages Open-WebSearch HTTP server on port 3100
- Auto-detects environment (Crush vs Claude Code) based on presence of crush.json
- Provides start/stop/restart/status/install commands
- Handles both global npm installations and npx executions

## Common Commands

### MCP Server Setup
```bash
# Setup MCP servers for Claude Desktop
./scripts/setup-mcp.sh

# Setup MCP servers for Crush environment
./scripts/setup-mcp-crush.sh

# List installed MCP servers (Claude Desktop)
./scripts/setup-mcp.sh --list

# Remove all MCP servers (Claude Desktop)  
./scripts/setup-mcp.sh --remove-all

# List configured servers in crush.json
./scripts/setup-mcp-crush.sh --list
```

### Open-WebSearch Management
```bash
# Start the Open-WebSearch server
./scripts/websearch-manager.sh start

# Check server status
./scripts/websearch-manager.sh status

# Stop the server
./scripts/websearch-manager.sh stop

# Install Open-WebSearch globally
./scripts/websearch-manager.sh install
```

## Development Environment

### Dependencies
- **bash**: All scripts are bash-based
- **jq**: Required for Crush configuration management (JSON manipulation)
- **npm/npx**: Required for MCP server installations
- **curl**: Used for health checks
- **lsof**: Used for port checking

### MCP Servers Managed
- **Playwright**: Browser automation and testing
- **Octocode**: Code generation and file operations  
- **BrowserMCP**: Browser automation and web interaction
- **GitHub**: Repository management (optional)
- **Chrome AppleScript**: Chrome browser control via AppleScript (macOS only)
- **Open-WebSearch**: Web search capabilities without API keys (HTTP server)
- **Computer Use**: Complete computer control (⚠️ use with caution)

### File Structure
```
ClaudeScheduler/
├── scripts/
│   ├── setup-mcp.sh           # Claude Desktop MCP setup
│   ├── setup-mcp-crush.sh     # Crush environment MCP setup  
│   └── websearch-manager.sh   # Open-WebSearch server management
└── CLAUDE.md                  # This documentation file
```

## Important Notes

- The Computer Use MCP server provides complete system control and should only be used in sandboxed environments
- Open-WebSearch runs as a separate HTTP server process on port 3100
- Chrome AppleScript server is only available on macOS systems
- All scripts include comprehensive help documentation accessible with `-h` or `--help` flags
- The websearch-manager.sh script automatically detects the environment (Crush vs Claude Code) based on the presence of crush.json