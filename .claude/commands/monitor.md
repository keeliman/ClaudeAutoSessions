---
name: monitor
description: Universal monitoring command - handles all monitoring scenarios with intelligent system detection
tools: [Task, Read, Write, Edit, MultiEdit, Bash, Grep, Glob, LS]
orchestration: true
task_type: monitoring
estimated_duration: 8
dependencies: []
---

# Universal Monitoring Command

Universal monitoring command that intelligently detects the monitoring target and orchestrates comprehensive monitoring workflows through TODO.md.

## 🎯 Intelligent Monitoring Detection

### Monitoring Types (Auto-detected)
```bash
# Health Monitoring
/monitor "Check health"                 → proj-health → ops-analytics
/monitor "System health"               → proj-health → ops-analytics
/monitor "Health check"                → proj-health → ops-analytics

# Log Monitoring
/monitor "Monitor logs"                → ops-analytics
/monitor "Check logs"                  → ops-analytics
/monitor "Log analysis"                → ops-analytics

# Performance Monitoring
/monitor "Monitor performance"         → ops-analytics
/monitor "Performance check"           → ops-analytics
/monitor "System performance"          → ops-analytics

# Status Monitoring
/monitor "System status"               → proj-health → ops-analytics
/monitor "Check status"                → proj-health → ops-analytics
/monitor "Status monitoring"           → proj-health → ops-analytics
```

## 🔍 Detection Algorithm

### 1. **Health Monitoring Detection**
- Keywords: "health", "status", "check", "system"
- Triggers: proj-health → ops-analytics

### 2. **Log Monitoring Detection**
- Keywords: "logs", "log", "analysis", "check"
- Triggers: ops-analytics

### 3. **Performance Monitoring Detection**
- Keywords: "performance", "speed", "metrics", "monitor"
- Triggers: ops-analytics

### 4. **Status Monitoring Detection**
- Keywords: "status", "state", "condition", "monitor"
- Triggers: proj-health → ops-analytics

## 🚀 Workflow

### 1. **Monitoring Analysis**
```bash
/monitor "Monitor authentication system health"
# Analysis:
# - "Monitor" → Monitoring required
# - "authentication system" → Security + Backend
# - "health" → Health monitoring
```

### 2. **Monitoring Planning**
```yaml
# Auto-selected monitoring approach
proj-health: "Authentication system health monitoring"
```

### 3. **Task Creation**
```yaml
# Tasks automatically created in TODO.md
- TASK_001: "Check system health" (ops-analytics)
- TASK_002: "Analyze performance" (ops-analytics)
- TASK_003: "Review logs" (ops-analytics)
- TASK_004: "Generate report" (ops-analytics)
```

### 4. **User Feedback**
```
📊 Monitoring task planned!
✅ Created 4 monitoring tasks in TODO.md

📋 Monitoring tasks created:
- TASK_001: "Check system health" (ops-analytics)
- TASK_002: "Analyze performance" (ops-analytics)
- TASK_003: "Review logs" (ops-analytics)
- TASK_004: "Generate report" (ops-analytics)

🚀 Next steps:
- Start monitoring: /orchestrate claim TASK_001
- Monitor progress: /orchestrate status
- View report: /orchestrate complete TASK_004
```

## 🎯 Monitoring Executor Mapping

### Analytics & Monitoring
- **ops-analytics** : Health monitoring, performance analysis
- **debug-detective** : Log analysis, issue investigation

### Reporting & Alerts
- **mkt-content** : Report generation, alert creation

## 🔧 Advanced Monitoring Features

### **Comprehensive Monitoring**
```bash
/monitor "Full system monitoring"
# Automatically:
# - Checks system health
# - Monitors performance
# - Analyzes logs
# - Generates alerts
```

### **Automated Monitoring**
```bash
/monitor "Automated monitoring with alerts"
# Automatically:
# - Sets up monitoring
# - Configures alerts
# - Tracks metrics
# - Reports issues
```

**Focus** : Universal monitoring command that makes monitoring 8x faster and 100% comprehensive ! 📊 