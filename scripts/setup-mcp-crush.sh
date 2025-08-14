#!/bin/bash
# Script to configure MCP servers for Crush development environment

# Configuration
CRUSH_CONFIG_FILE="crush.json"
CONFIG_DIR="$(pwd)"

# Display usage information
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Configure MCP servers for Crush development environment"
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help       Show this help message"
    echo "  -c, --config     Specify custom config file path (default: ./crush.json)"
    echo "  -d, --dir        Specify config directory (default: current directory)"
    echo "  -l, --list       List currently configured MCP servers in crush.json"
    echo "  -r, --remove     Remove specific MCP servers from crush.json"
    echo "  -a, --remove-all Remove all MCP servers from crush.json"
    echo ""
    echo "EXAMPLES:"
    echo "  $0                           Setup MCP servers in ./crush.json"
    echo "  $0 -c /path/to/config.json   Use custom config file"
    echo "  $0 --list                    Show configured servers"
    echo "  $0 --remove                  Remove specific servers"
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
        -c|--config)
            CRUSH_CONFIG_FILE="$2"
            shift 2
            ;;
        -d|--dir)
            CONFIG_DIR="$2"
            shift 2
            ;;
        -l|--list)
            LIST_ONLY=true
            shift
            ;;
        -r|--remove)
            REMOVE_MODE=true
            shift
            ;;
        -a|--remove-all)
            REMOVE_ALL=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

FULL_CONFIG_PATH="$CONFIG_DIR/$CRUSH_CONFIG_FILE"

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "❌ jq is required but not installed. Please install jq first:"
    echo "   brew install jq  (on macOS)"
    echo "   sudo apt-get install jq  (on Ubuntu/Debian)"
    exit 1
fi

# Create base config structure if file doesn't exist
create_base_config() {
    if [ ! -f "$FULL_CONFIG_PATH" ]; then
        echo "Creating base Crush configuration file at: $FULL_CONFIG_PATH"
        cat > "$FULL_CONFIG_PATH" << 'EOF'
{
  "mcpServers": {},
  "version": "1.0",
  "created": "",
  "description": "MCP servers configuration for Crush development environment"
}
EOF
        # Update created timestamp
        jq --arg date "$(date -Iseconds)" '.created = $date' "$FULL_CONFIG_PATH" > "${FULL_CONFIG_PATH}.tmp" && mv "${FULL_CONFIG_PATH}.tmp" "$FULL_CONFIG_PATH"
    fi
}

# List current MCP servers
list_servers() {
    if [ ! -f "$FULL_CONFIG_PATH" ]; then
        echo "❌ Configuration file not found: $FULL_CONFIG_PATH"
        exit 1
    fi
    
    echo "📋 MCP servers configured in $FULL_CONFIG_PATH:"
    echo ""
    
    # Check if mcpServers exists and has content
    if jq -e '.mcpServers | length > 0' "$FULL_CONFIG_PATH" >/dev/null 2>&1; then
        jq -r '.mcpServers | to_entries[] | "• \(.key): \(.value.transport.type // "stdio") - \(.value.description // "No description")"' "$FULL_CONFIG_PATH"
    else
        echo "No MCP servers configured."
    fi
}

# Remove all servers
remove_all_servers() {
    if [ ! -f "$FULL_CONFIG_PATH" ]; then
        echo "❌ Configuration file not found: $FULL_CONFIG_PATH"
        exit 1
    fi
    
    echo "⚠️  This will remove ALL MCP servers from $CRUSH_CONFIG_FILE"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        jq '.mcpServers = {}' "$FULL_CONFIG_PATH" > "${FULL_CONFIG_PATH}.tmp" && mv "${FULL_CONFIG_PATH}.tmp" "$FULL_CONFIG_PATH"
        echo "✅ All MCP servers removed from configuration"
    else
        echo "❌ Operation cancelled"
    fi
}

# Remove specific servers
remove_servers() {
    if [ ! -f "$FULL_CONFIG_PATH" ]; then
        echo "❌ Configuration file not found: $FULL_CONFIG_PATH"
        exit 1
    fi
    
    echo "🗑️  Remove MCP servers from $CRUSH_CONFIG_FILE"
    echo ""
    list_servers
    echo ""
    
    # Get list of configured servers
    SERVERS=($(jq -r '.mcpServers | keys[]' "$FULL_CONFIG_PATH" 2>/dev/null || echo ""))
    
    if [ ${#SERVERS[@]} -eq 0 ]; then
        echo "No servers to remove."
        return
    fi
    
    for server in "${SERVERS[@]}"; do
        read -p "Remove $server? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            jq --arg server "$server" 'del(.mcpServers[$server])' "$FULL_CONFIG_PATH" > "${FULL_CONFIG_PATH}.tmp" && mv "${FULL_CONFIG_PATH}.tmp" "$FULL_CONFIG_PATH"
            echo "✅ $server removed"
        else
            echo "⏭️  Keeping $server"
        fi
    done
}

# Add MCP server to config
add_mcp_server() {
    local name="$1"
    local transport_type="$2"
    local command_or_url="$3"
    local description="$4"
    local args="$5"
    
    if [ "$transport_type" = "stdio" ]; then
        jq --arg name "$name" \
           --arg cmd "$command_or_url" \
           --arg desc "$description" \
           --argjson args "$args" \
           '.mcpServers[$name] = {
               "transport": {
                   "type": "stdio",
                   "command": $cmd,
                   "args": $args
               },
               "description": $desc
           }' "$FULL_CONFIG_PATH" > "${FULL_CONFIG_PATH}.tmp" && mv "${FULL_CONFIG_PATH}.tmp" "$FULL_CONFIG_PATH"
    else
        # HTTP or SSE transport
        jq --arg name "$name" \
           --arg type "$transport_type" \
           --arg url "$command_or_url" \
           --arg desc "$description" \
           '.mcpServers[$name] = {
               "transport": {
                   "type": $type,
                   "url": $url
               },
               "description": $desc
           }' "$FULL_CONFIG_PATH" > "${FULL_CONFIG_PATH}.tmp" && mv "${FULL_CONFIG_PATH}.tmp" "$FULL_CONFIG_PATH"
    fi
}

# Handle list option
if [ "$LIST_ONLY" = true ]; then
    list_servers
    exit 0
fi

# Handle remove all option
if [ "$REMOVE_ALL" = true ]; then
    remove_all_servers
    exit 0
fi

# Handle remove option
if [ "$REMOVE_MODE" = true ]; then
    remove_servers
    exit 0
fi

# Main installation process
echo "🔧 Setting up MCP servers for Crush environment..."
echo "Configuration file: $FULL_CONFIG_PATH"
echo ""

# Create base config
create_base_config

echo "📌 Essential MCP Servers"
echo ""

# Essential servers - always install
echo "Adding essential MCP servers..."

# Playwright
echo "• Adding Playwright (browser automation)"
add_mcp_server "playwright" "stdio" "npx" "Browser automation and testing" '["@playwright/mcp@latest"]'

# GitHub
echo "• Adding GitHub (repository management)"
add_mcp_server "github" "stdio" "npx" "Repository management and operations" '["@modelcontextprotocol/server-github"]'

# Octocode
echo "• Adding Octocode (code generation)"
add_mcp_server "octocode" "stdio" "npx" "Code generation and file operations" '["octocode-mcp@latest"]'

# BrowserMCP
echo "• Adding BrowserMCP (web interaction)"
add_mcp_server "browsermcp" "stdio" "npx" "Browser automation and web interaction" '["@browsermcp/mcp@latest"]'

echo ""
echo "📌 Optional MCP Servers"
echo ""

# Chrome AppleScript (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
    read -p "Add Chrome AppleScript MCP server (macOS browser control)? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Find chrome-applescript directory
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        CHROME_APPLESCRIPT_DIR=""
        
        if [ -d "$SCRIPT_DIR/chrome-applescript" ]; then
            CHROME_APPLESCRIPT_DIR="$SCRIPT_DIR/chrome-applescript"
        elif [ -d "/Users/mandria/Documents/ClaudeCode/ClaudeCodeTemplates/mcp-servers/chrome-applescript" ]; then
            CHROME_APPLESCRIPT_DIR="/Users/mandria/Documents/ClaudeCode/ClaudeCodeTemplates/mcp-servers/chrome-applescript"
        elif [ -d "$(dirname "$SCRIPT_DIR")/mcp-servers/chrome-applescript" ]; then
            CHROME_APPLESCRIPT_DIR="$(dirname "$SCRIPT_DIR")/mcp-servers/chrome-applescript"
        fi
        
        if [ -n "$CHROME_APPLESCRIPT_DIR" ] && [ -d "$CHROME_APPLESCRIPT_DIR" ]; then
            echo "• Adding Chrome AppleScript (Chrome browser control)"
            add_mcp_server "chrome-applescript" "stdio" "node" "Chrome browser control via AppleScript (macOS)" "[\"$CHROME_APPLESCRIPT_DIR/server/index.js\"]"
        else
            echo "❌ Chrome AppleScript directory not found, skipping..."
        fi
    fi
else
    echo "ℹ️  Chrome AppleScript is only available on macOS"
fi

# Open-WebSearch - Always add by default
echo "• Adding Open-WebSearch (web search capabilities)"
echo "ℹ️  Note: This server requires a separate HTTP process on port 3100"
echo "ℹ️  Use ./scripts/websearch-manager.sh to manage the server"
add_mcp_server "open-websearch" "http" "http://localhost:3100/mcp" "Web search capabilities without API keys" ""

# Computer Use
echo ""
echo "⚠️  Computer Use MCP Server (CAUTION REQUIRED)"
echo "This server gives complete control of your computer."
echo "Only use in a sandboxed environment or supervised closely!"
echo ""
read -p "Add Computer Use MCP server? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "• Adding Computer Use (complete computer control)"
    add_mcp_server "computer-use" "stdio" "npx" "Complete computer control (⚠️  USE WITH CAUTION)" '["computer-use-mcp"]'
    echo ""
    echo "🔒 SECURITY RECOMMENDATIONS:"
    echo "• Consider using a dedicated sandboxed user account"
    echo "• Supervise closely when using computer control"
    echo "• Install Rango browser extension for better keyboard navigation"
fi

echo ""
echo "✅ Crush MCP configuration complete!"
echo ""
echo "📋 Configuration file: $FULL_CONFIG_PATH"
echo ""
echo "To view configured servers: $0 --list"
echo "To remove servers: $0 --remove"
echo ""

# Show final configuration
echo "📄 Final configuration:"
list_servers

echo ""
echo "🚀 Next steps:"
echo "1. Copy the configuration to your Crush environment"
echo "2. Start required HTTP servers: ./scripts/websearch-manager.sh start"
echo "3. Configure Crush to use this MCP configuration file"