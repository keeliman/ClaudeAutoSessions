---
name: orchestrate
description: Universal orchestration command - handles all orchestration scenarios with intelligent workflow detection
tools: [Task, Read, Write, Edit, MultiEdit, Bash, Grep, Glob, LS]
orchestration: true
task_type: orchestration
estimated_duration: 5
dependencies: []
---

# Universal Orchestration Command

Universal orchestration command that intelligently manages task workflows and orchestrates comprehensive project coordination through TODO.md.

## 🎯 Intelligent Orchestration Detection

### Orchestration Types (Auto-detected)
```bash
# Task Management
/orchestrate "Manage tasks"              → orchestrate → pm-shipper
/orchestrate "Task management"           → orchestrate → pm-shipper
/orchestrate "Coordinate tasks"          → orchestrate → pm-shipper

# Workflow Orchestration
/orchestrate "Orchestrate workflow"      → orchestrate → pm-shipper
/orchestrate "Workflow coordination"     → orchestrate → pm-shipper
/orchestrate "Process orchestration"     → orchestrate → pm-shipper

# System Coordination
/orchestrate "System coordination"       → orchestrate → pm-shipper
/orchestrate "Coordinate system"         → orchestrate → pm-shipper
/orchestrate "System orchestration"      → orchestrate → pm-shipper

# Task Operations
/orchestrate "Claim task"               → orchestrate → pm-shipper
/orchestrate "Complete task"            → orchestrate → pm-shipper
/orchestrate "Status check"             → orchestrate → pm-shipper
```

## 🔍 Detection Algorithm

### 1. **Task Management Detection**
- Keywords: "manage", "coordinate", "tasks", "workflow"
- Triggers: orchestrate → pm-shipper

### 2. **Workflow Orchestration Detection**
- Keywords: "orchestrate", "workflow", "process", "coordinate"
- Triggers: orchestrate → pm-shipper

### 3. **System Coordination Detection**
- Keywords: "system", "coordinate", "orchestrate", "manage"
- Triggers: orchestrate → pm-shipper

### 4. **Task Operations Detection**
- Keywords: "claim", "complete", "status", "task"
- Triggers: orchestrate → pm-shipper

## 🚀 Workflow

### 1. **Orchestration Analysis**
```bash
/orchestrate "Manage authentication project tasks"
# Analysis:
# - "Manage" → Task management
# - "authentication project" → Security + Project
# - "tasks" → Task orchestration
```

### 2. **Orchestration Planning**
```yaml
# Auto-selected orchestration approach
orchestrate: "Authentication project task management"
```

### 3. **Task Creation**
```yaml
# Tasks automatically created in TODO.md
- TASK_001: "Review project status" (pm-shipper)
- TASK_002: "Assign tasks" (pm-shipper)
- TASK_003: "Monitor progress" (pm-shipper)
- TASK_004: "Update stakeholders" (pm-shipper)
```

### 4. **User Feedback**
```
🎼 Orchestration task planned!
✅ Created 4 orchestration tasks in TODO.md

📋 Orchestration tasks created:
- TASK_001: "Review project status" (pm-shipper)
- TASK_002: "Assign tasks" (pm-shipper)
- TASK_003: "Monitor progress" (pm-shipper)
- TASK_004: "Update stakeholders" (pm-shipper)

🚀 Next steps:
- Start orchestration: /orchestrate claim TASK_001
- Monitor progress: /orchestrate status
- Complete orchestration: /orchestrate complete TASK_004
```

## 🎯 Orchestration Executor Mapping

### Project Management & Coordination
- **pm-shipper** : Task management, workflow coordination
- **pm-shipper** : Project delivery, stakeholder management

### Analytics & Reporting
- **ops-analytics** : Progress tracking, metrics reporting

## 🔧 Advanced Orchestration Features

### **Comprehensive Orchestration**
```bash
/orchestrate "Full project orchestration"
# Automatically:
# - Manages all tasks
# - Coordinates workflows
# - Monitors progress
# - Reports status
```

### **Automated Orchestration**
```bash
/orchestrate "Automated task management"
# Automatically:
# - Assigns tasks
# - Tracks progress
# - Manages dependencies
# - Reports completion
```

**Focus** : Universal orchestration command that makes project management 5x faster and 100% coordinated ! 🎼 