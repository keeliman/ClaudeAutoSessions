#!/bin/bash
# Script to configure essential MCP servers for development

# Display usage information
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Configure essential MCP servers for Claude Desktop development"
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help       Show this help message"
    echo "  -r, --remove     Remove MCP servers instead of adding them"
    echo "  -a, --remove-all Remove all MCP servers"
    echo "  -l, --list       List currently installed MCP servers"
    echo ""
    echo "EXAMPLES:"
    echo "  $0               Install all MCP servers (interactive)"
    echo "  $0 --remove      Remove specific MCP servers (interactive)"
    echo "  $0 --remove-all  Remove all MCP servers"
    echo "  $0 --list        Show installed MCP servers"
}

# Parse command line arguments
REMOVE_MODE=false
REMOVE_ALL=false
LIST_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -r|--remove)
            REMOVE_MODE=true
            shift
            ;;
        -a|--remove-all)
            REMOVE_ALL=true
            shift
            ;;
        -l|--list)
            LIST_ONLY=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Find claude command
CLAUDE_CMD=""
if command -v claude &> /dev/null; then
    CLAUDE_CMD="claude"
elif [ -f ~/.claude/local/claude ]; then
    CLAUDE_CMD="$HOME/.claude/local/claude"
elif type claude &> /dev/null 2>&1; then
    CLAUDE_CMD="claude"
else
    echo "❌ Claude CLI not found. Please make sure it's installed."
    echo "Visit: https://docs.anthropic.com/en/docs/claude-code/quickstart"
    exit 1
fi

# Handle list option
if [ "$LIST_ONLY" = true ]; then
    echo "📋 Currently installed MCP servers:"
    $CLAUDE_CMD mcp list
    exit 0
fi

# Handle remove all option
if [ "$REMOVE_ALL" = true ]; then
    echo "⚠️  This will remove ALL MCP servers from your configuration."
    read -p "Are you sure? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Removing all MCP servers..."
        
        # Get list of servers and remove them
        SERVERS=$($CLAUDE_CMD mcp list | grep -E "^[a-zA-Z0-9_-]+:" | cut -d: -f1 || true)
        
        if [ -z "$SERVERS" ]; then
            echo "ℹ️  No MCP servers found to remove."
        else
            for server in $SERVERS; do
                echo "Removing $server..."
                $CLAUDE_CMD mcp remove "$server" 2>/dev/null || echo "  ⚠️  Failed to remove $server"
            done
            echo "✅ All MCP servers have been removed."
        fi
    else
        echo "❌ Operation cancelled."
    fi
    exit 0
fi

# Handle selective remove mode
if [ "$REMOVE_MODE" = true ]; then
    echo "🗑️  MCP Server Removal"
    echo ""
    
    # Get current servers
    echo "📋 Currently installed MCP servers:"
    $CLAUDE_CMD mcp list
    echo ""
    
    # Common MCP servers to check for removal
    COMMON_SERVERS=("playwright" "chrome-applescript" "github" "octocode" "browsermcp" "open-websearch" "computer-use" "sqlite")
    
    for server in "${COMMON_SERVERS[@]}"; do
        # Check if server exists by trying to get details (suppress error output)
        if $CLAUDE_CMD mcp get "$server" &>/dev/null; then
            read -p "Remove $server MCP server? (y/N): " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "Removing $server..."
                $CLAUDE_CMD mcp remove "$server"
                echo "✅ $server removed successfully"
            else
                echo "⏭️  Keeping $server"
            fi
            echo ""
        fi
    done
    
    echo "✅ MCP server removal process complete!"
    echo ""
    echo "To see remaining servers, run: claude mcp list"
    exit 0
fi

echo "🔧 Setting up essential MCP servers..."

# Playwright - Browser automation and testing
echo "Adding Playwright MCP server..."
$CLAUDE_CMD mcp add playwright npx @playwright/mcp@latest


# Chrome AppleScript - Control Chrome via AppleScript (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo ""
    echo "📌 Chrome AppleScript MCP server (macOS only)"
    echo "This server allows Claude to control Chrome browser via AppleScript."
    read -p "Do you want to install Chrome AppleScript MCP server? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Setting up Chrome AppleScript MCP server..."
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        # Look for chrome-applescript in current directory first, then in ClaudeCodeTemplates
        if [ -d "$SCRIPT_DIR/chrome-applescript" ]; then
            CHROME_APPLESCRIPT_DIR="$SCRIPT_DIR/chrome-applescript"
        elif [ -d "/Users/mandria/Documents/ClaudeCode/ClaudeCodeTemplates/mcp-servers/chrome-applescript" ]; then
            CHROME_APPLESCRIPT_DIR="/Users/mandria/Documents/ClaudeCode/ClaudeCodeTemplates/mcp-servers/chrome-applescript"
        else
            CHROME_APPLESCRIPT_DIR="$(dirname "$SCRIPT_DIR")/mcp-servers/chrome-applescript"
        fi
        
        # Check if chrome-applescript directory exists
        if [ ! -d "$CHROME_APPLESCRIPT_DIR" ]; then
            echo "❌ Chrome AppleScript directory not found at: $CHROME_APPLESCRIPT_DIR"
            echo "Please ensure the chrome-applescript folder exists in the same directory as this script"
            echo "Skipping Chrome AppleScript installation."
        else
            # Install dependencies if node_modules doesn't exist
            if [ ! -d "$CHROME_APPLESCRIPT_DIR/node_modules" ]; then
                echo "Installing Chrome AppleScript dependencies..."
                cd "$CHROME_APPLESCRIPT_DIR"
                if command -v npm &> /dev/null; then
                    npm install
                else
                    echo "❌ npm not found. Please install Node.js and npm first"
                    echo "Skipping Chrome AppleScript installation."
                    cd "$SCRIPT_DIR"
                fi
            fi
            
            if [ -d "$CHROME_APPLESCRIPT_DIR/node_modules" ]; then
                # Add MCP server to Claude configuration
                echo "Adding Chrome AppleScript MCP server to Claude..."
                $CLAUDE_CMD mcp add chrome-applescript node "$CHROME_APPLESCRIPT_DIR/server/index.js"
                echo "✅ Chrome AppleScript installed successfully"
            fi
            cd "$SCRIPT_DIR"
        fi
    else
        echo "⏭️  Skipping Chrome AppleScript MCP server installation"
    fi
else
    echo "ℹ️  Chrome AppleScript MCP server is only available on macOS"
fi

# GitHub - Repository management and operations (OPTIONAL - most git operations use CLI)
echo ""
echo "📌 GitHub MCP server (OPTIONAL)"
echo "Most git operations (commit, push, pull) are done via terminal."
echo "This server is only useful for web operations (creating repos, managing issues)."
read -p "Do you want to install GitHub MCP server? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Adding GitHub MCP server..."
    $CLAUDE_CMD mcp add github npx @modelcontextprotocol/server-github
    echo "✅ GitHub MCP server installed"
else
    echo "⏭️  Skipping GitHub MCP server installation"
fi

# Octocode - Code generation and file operations
echo "Adding Octocode MCP server..."
$CLAUDE_CMD mcp add octocode npx 'octocode-mcp@latest'

# BrowserMCP - Browser automation and web interaction
echo "Adding BrowserMCP server..."
$CLAUDE_CMD mcp add browsermcp npx '@browsermcp/mcp@latest'

# Open-WebSearch - Web search capabilities without API keys
echo "Adding Open-WebSearch MCP server..."

# Check if open-websearch is already configured
if $CLAUDE_CMD mcp get "open-websearch" &>/dev/null; then
    echo "✅ Open-WebSearch already configured"
else
    # Check if server is already running on port 3100
    if lsof -ti:3100 >/dev/null 2>&1; then
        echo "✅ Open-WebSearch server already running on port 3100"
        echo "Adding Open-WebSearch MCP server to Claude..."
        $CLAUDE_CMD mcp add -t http open-websearch http://localhost:3100/mcp
        echo "✅ Open-WebSearch configured successfully"
    else
        echo "Starting Open-WebSearch server on port 3100..."
        # Start the server in background using websearch-manager
        if [ -f "./scripts/websearch-manager.sh" ]; then
            ./scripts/websearch-manager.sh start
        else
            # Fallback to direct npx if manager script not found
            PORT=3100 npx open-websearch@latest >/dev/null 2>&1 &
            sleep 3
        fi
        
        # Check if server started successfully
        if lsof -ti:3100 >/dev/null 2>&1; then
            echo "Adding Open-WebSearch MCP server to Claude..."
            $CLAUDE_CMD mcp add -t http open-websearch http://localhost:3100/mcp
            echo "✅ Open-WebSearch installed successfully"
            echo "ℹ️  Note: The server is running in background."
            echo "    To manage it, use: ./scripts/websearch-manager.sh [start|stop|status]"
        else
            echo "❌ Failed to start Open-WebSearch server"
            echo "⚠️  You can manually start it later with: ./scripts/websearch-manager.sh start"
        fi
    fi
fi

# Computer Use - Control computer via MCP (with warning)
echo ""
echo "⚠️  Computer Use MCP Server (CAUTION REQUIRED)"
echo "This server gives Claude complete control of your computer."
echo "Only use in a sandboxed environment or supervised closely!"
echo ""
read -p "Do you want to install Computer Use MCP server? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Adding Computer Use MCP server..."
    $CLAUDE_CMD mcp add computer-use npx computer-use-mcp
    echo ""
    echo "🔒 SECURITY RECOMMENDATIONS:"
    echo "• Install Rango browser extension for better keyboard navigation:"
    echo "  https://chromewebstore.google.com/detail/rango/lnemjdnjjofijemhdogofbpcedhgcpmb"
    echo "• Consider using a dedicated sandboxed user account"
    echo "• Supervise Claude closely when using computer control"
    echo "• Zoom in on high-resolution displays for better AI vision"
else
    echo "⏭️  Skipping Computer Use MCP server installation"
fi

echo ""
echo "✅ MCP servers setup complete!"
echo ""
echo "To verify installation, run: claude mcp list"
echo ""
# Show note about open-websearch if installed
if $CLAUDE_CMD mcp get "open-websearch" &>/dev/null; then
    echo "📝 Note about Open-WebSearch:"
    echo "• The server runs as a separate HTTP process on port 3100"
    echo "• To manage it: ./scripts/websearch-manager.sh [start|stop|restart|status]"
    echo ""
fi
echo "📋 Installed MCP Servers:"
echo ""
echo "Essential servers:"
echo "• Playwright - Browser automation and testing"
echo "• Octocode - Code generation and file operations"
echo "• BrowserMCP - Browser automation and web interaction"
echo ""
echo "Optional servers:"
# Check if GitHub was installed
if $CLAUDE_CMD mcp get "github" &>/dev/null; then
    echo "• GitHub - Repository web operations (CLI preferred for commits) ✓"
else
    echo "• GitHub - Repository web operations ✗"
fi
# Check if chrome-applescript was installed
if $CLAUDE_CMD mcp get "chrome-applescript" &>/dev/null; then
    echo "• Chrome AppleScript - Chrome browser control (macOS) ✓"
else
    echo "• Chrome AppleScript - Chrome browser control (macOS) ✗"
fi
# Check if open-websearch was installed
if $CLAUDE_CMD mcp get "open-websearch" &>/dev/null; then
    echo "• Open-WebSearch - Web search capabilities (HTTP server on port 3100) ✓"
else
    echo "• Open-WebSearch - Web search capabilities ✗"
fi
# Check if computer-use was installed
if $CLAUDE_CMD mcp get "computer-use" &>/dev/null; then
    echo "• Computer Use - Complete computer control (⚠️  USE WITH CAUTION) ✓"
else
    echo "• Computer Use - Complete computer control ✗"
fi