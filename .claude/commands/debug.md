---
name: debug
description: Universal debugging command - handles all debugging scenarios with intelligent issue detection
tools: [Task, Read, Write, Edit, MultiEdit, Bash, Grep, Glob, LS]
orchestration: true
task_type: debugging
estimated_duration: 12
dependencies: []
---

# Universal Debugging Command

Universal debugging command that intelligently detects the type of debugging needed and orchestrates comprehensive debugging workflows through TODO.md.

## 🎯 Intelligent Debugging Detection

### Debugging Types (Auto-detected)
```bash
# Live Debugging
/debug "Debug live crash"             → debug-detective
/debug "Fix production issue"         → debug-detective
/debug "Emergency fix"                → debug-detective

# Log Analysis
/debug "Analyze logs"                 → debug-detective
/debug "Check error logs"             → debug-detective
/debug "Log investigation"            → debug-detective

# Performance Debugging
/debug "Performance issue"            → debug-detective
/debug "Slow response time"           → debug-detective
/debug "Memory leak"                  → debug-detective

# Trace Debugging
/debug "Trace error"                  → debug-detective
/debug "Follow execution path"        → debug-detective
/debug "Debug stack trace"            → debug-detective
```

## 🔍 Detection Algorithm

### 1. **Live Debugging Detection**
- Keywords: "live", "production", "crash", "emergency", "urgent"
- Triggers: debug-detective

### 2. **Log Analysis Detection**
- Keywords: "logs", "error", "investigation", "analysis"
- Triggers: debug-detective

### 3. **Performance Debugging Detection**
- Keywords: "performance", "slow", "memory", "speed", "leak"
- Triggers: debug-detective

### 4. **Trace Debugging Detection**
- Keywords: "trace", "stack", "execution", "path", "flow"
- Triggers: debug-detective

## 🚀 Workflow

### 1. **Debugging Analysis**
```bash
/debug "Production crash in login system"
# Analysis:
# - "Production" → Live debugging
# - "crash" → Critical issue
# - "login system" → Authentication + Backend
```

### 2. **Debugging Planning**
```yaml
# Auto-selected debugging approach
debug-detective: "Production login crash investigation"
```

### 3. **Task Creation**
```yaml
# Tasks automatically created in TODO.md
- TASK_001: "Analyze crash logs" (debug-detective)
- TASK_002: "Identify root cause" (debug-detective)
- TASK_003: "Create fix" (eng-backend)
- TASK_004: "Deploy hotfix" (eng-devops)
```

### 4. **User Feedback**
```
🐛 Debugging task planned!
✅ Created 4 debugging tasks in TODO.md

📋 Debugging tasks created:
- TASK_001: "Analyze crash logs" (debug-detective)
- TASK_002: "Identify root cause" (debug-detective)
- TASK_003: "Create fix" (eng-backend)
- TASK_004: "Deploy hotfix" (eng-devops)

🚀 Next steps:
- Start debugging: /orchestrate claim TASK_001
- Monitor progress: /orchestrate status
- Deploy fix: /orchestrate complete TASK_004
```

## 🎯 Debugging Executor Mapping

### Investigation & Analysis
- **debug-detective** : Root cause analysis, log investigation
- **ops-analytics** : Performance analysis, metrics review

### Fix Implementation
- **eng-backend** : Backend fixes, code corrections
- **eng-frontend** : Frontend fixes, UI corrections
- **eng-devops** : Infrastructure fixes, deployment

## 🔧 Advanced Debugging Features

### **Multi-Layer Debugging**
```bash
/debug "Comprehensive system failure analysis"
# Automatically:
# - Analyzes application logs
# - Checks system metrics
# - Reviews infrastructure
# - Identifies dependencies
```

### **Automated Fix Generation**
```bash
/debug "Auto-fix common issues"
# Automatically:
# - Identifies common patterns
# - Generates fix suggestions
# - Creates test cases
# - Validates fixes
```

**Focus** : Universal debugging command that makes debugging 12x faster and 100% systematic ! 🐛 