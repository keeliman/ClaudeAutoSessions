#!/bin/bash
# Unified script to manage Open-WebSearch MCP server for Claude Code and Crush environments

show_help() {
    echo "Usage: $0 [start|stop|restart|status|install]"
    echo ""
    echo "Manage Open-WebSearch MCP server for Claude Code and Crush environments"
    echo ""
    echo "Commands:"
    echo "  start     Start the Open-WebSearch server on port 3100"
    echo "  stop      Stop the Open-WebSearch server"
    echo "  restart   Restart the Open-WebSearch server"
    echo "  status    Check if the server is running"
    echo "  install   Install Open-WebSearch globally"
    echo ""
    echo "Auto-detection:"
    echo "• Detects Crush environment if crush.json exists"
    echo "• Falls back to Claude Code mode otherwise"
    echo ""
    echo "Note: This server is required if you included Open-WebSearch"
    echo "      in your MCP configuration."
}

PORT=3100

# Detect environment
detect_environment() {
    if [ -f "crush.json" ] || [ -f "./crush.json" ]; then
        echo "crush"
    else
        echo "claude"
    fi
}

ENV=$(detect_environment)

case "$1" in
    install)
        echo "Installing Open-WebSearch globally..."
        if command -v npm &> /dev/null; then
            npm install -g open-websearch@latest
            echo "✅ Open-WebSearch installed globally"
            echo "You can now start it with: $0 start"
        else
            echo "❌ npm not found. Please install Node.js and npm first"
            exit 1
        fi
        ;;
    start)
        if lsof -ti:$PORT >/dev/null 2>&1; then
            echo "⚠️  Open-WebSearch is already running on port $PORT"
            echo "📋 PID: $(lsof -ti:$PORT)"
        else
            if [ "$ENV" = "crush" ]; then
                echo "🔧 Starting Open-WebSearch server on port $PORT for Crush environment..."
            else
                echo "🔧 Starting Open-WebSearch server on port $PORT for Claude Code..."
            fi
            
            # Try global installation first, then npx
            if command -v open-websearch &> /dev/null; then
                PORT=$PORT open-websearch >/dev/null 2>&1 &
            else
                PORT=$PORT npx open-websearch@latest >/dev/null 2>&1 &
            fi
            
            PID=$!
            sleep 3
            
            if lsof -ti:$PORT >/dev/null 2>&1; then
                echo "✅ Open-WebSearch started successfully"
                echo "🌐 Server URL: http://localhost:$PORT"
                echo "🔌 MCP Endpoint: http://localhost:$PORT/mcp"
                echo "📋 PID: $(lsof -ti:$PORT)"
                
                if [ "$ENV" = "crush" ]; then
                    echo ""
                    echo "💡 Crush environment detected:"
                    echo "   Make sure your crush.json includes the open-websearch configuration"
                else
                    echo ""
                    echo "💡 Claude Code environment:"
                    echo "   Server should be configured with: claude mcp add --transport http"
                fi
                
                echo ""
                echo "🔍 Test the server with:"
                echo "   curl http://localhost:$PORT/health"
            else
                echo "❌ Failed to start Open-WebSearch"
                exit 1
            fi
        fi
        ;;
    stop)
        if lsof -ti:$PORT >/dev/null 2>&1; then
            PID=$(lsof -ti:$PORT)
            echo "🛑 Stopping Open-WebSearch server (PID: $PID)..."
            kill $PID
            sleep 1
            if ! lsof -ti:$PORT >/dev/null 2>&1; then
                echo "✅ Open-WebSearch stopped"
            else
                echo "⚠️  Force killing Open-WebSearch..."
                kill -9 $PID
                echo "✅ Open-WebSearch force stopped"
            fi
        else
            echo "ℹ️  Open-WebSearch is not running"
        fi
        ;;
    restart)
        echo "🔄 Restarting Open-WebSearch..."
        $0 stop
        sleep 2
        $0 start
        ;;
    status)
        echo "🔍 Open-WebSearch Status Check"
        echo ""
        
        if [ "$ENV" = "crush" ]; then
            echo "🏗️  Environment: Crush (crush.json detected)"
        else
            echo "🏗️  Environment: Claude Code"
        fi
        
        echo "🌐 Expected Port: $PORT"
        echo ""
        
        if lsof -ti:$PORT >/dev/null 2>&1; then
            PID=$(lsof -ti:$PORT)
            echo "✅ Open-WebSearch is running"
            echo "📋 PID: $PID"
            echo "🔌 MCP Endpoint: http://localhost:$PORT/mcp"
            echo ""
            
            echo "🔍 Testing server health..."
            if curl -s "http://localhost:$PORT/health" >/dev/null 2>&1; then
                echo "✅ Server is responding to health checks"
            else
                echo "⚠️  Server might not be fully ready (health check failed)"
            fi
            
            echo ""
            echo "🔗 Testing MCP endpoint..."
            if curl -s "http://localhost:$PORT/mcp" >/dev/null 2>&1; then
                echo "✅ MCP endpoint is accessible"
            else
                echo "⚠️  MCP endpoint might not be ready"
            fi
            
            if [ "$ENV" = "crush" ]; then
                echo ""
                echo "📄 Crush Configuration:"
                if grep -q "open-websearch" crush.json 2>/dev/null; then
                    echo "✅ open-websearch found in crush.json"
                else
                    echo "❌ open-websearch NOT found in crush.json"
                    echo "   Run: ./scripts/setup-mcp-crush.sh to configure"
                fi
            fi
        else
            echo "❌ Open-WebSearch is not running"
            echo ""
            echo "🚀 To start it, run:"
            echo "   $0 start"
            echo ""
            echo "📦 To install globally first:"
            echo "   $0 install"
        fi
        ;;
    *)
        show_help
        exit 1
        ;;
esac