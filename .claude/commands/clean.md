---
name: clean
description: Universal cleaning command - handles all cleaning scenarios with intelligent target detection
tools: [Task, Read, Write, Edit, MultiEdit, Bash, Grep, Glob, LS]
orchestration: true
task_type: cleaning
estimated_duration: 5
dependencies: []
---

# Universal Cleaning Command

Universal cleaning command that intelligently detects the cleaning target and orchestrates comprehensive cleaning workflows through TODO.md.

## 🎯 Intelligent Cleaning Detection

### Cleaning Types (Auto-detected)
```bash
# Code Cleaning
/clean "Clean code"                     → dev-clean → eng-backend
/clean "Code cleanup"                  → dev-clean → eng-backend
/clean "Refactor code"                 → dev-clean → eng-backend

# Branch Cleaning
/clean "Clean branches"                → git-branch-clean → eng-devops
/clean "Branch cleanup"                → git-branch-clean → eng-devops
/clean "Remove old branches"           → git-branch-clean → eng-devops

# Cache Cleaning
/clean "Clean cache"                   → dev-clean → eng-devops
/clean "Cache cleanup"                 → dev-clean → eng-devops
/clean "Clear cache"                   → dev-clean → eng-devops

# Log Cleaning
/clean "Clean logs"                    → dev-clean → eng-devops
/clean "Log cleanup"                   → dev-clean → eng-devops
/clean "Remove old logs"               → dev-clean → eng-devops
```

## 🔍 Detection Algorithm

### 1. **Code Cleaning Detection**
- Keywords: "code", "refactor", "clean", "improve"
- Triggers: dev-clean → eng-backend

### 2. **Branch Cleaning Detection**
- Keywords: "branch", "branches", "remove", "clean"
- Triggers: git-branch-clean → eng-devops

### 3. **Cache Cleaning Detection**
- Keywords: "cache", "clear", "clean", "remove"
- Triggers: dev-clean → eng-devops

### 4. **Log Cleaning Detection**
- Keywords: "logs", "log", "remove", "clean"
- Triggers: dev-clean → eng-devops

## 🚀 Workflow

### 1. **Cleaning Analysis**
```bash
/clean "Clean authentication code"
# Analysis:
# - "Clean" → Cleaning required
# - "authentication code" → Security + Code
# - "code" → Code cleaning
```

### 2. **Cleaning Planning**
```yaml
# Auto-selected cleaning approach
dev-clean: "Authentication code cleaning"
```

### 3. **Task Creation**
```yaml
# Tasks automatically created in TODO.md
- TASK_001: "Analyze code" (eng-backend)
- TASK_002: "Clean code" (eng-backend)
- TASK_003: "Validate changes" (eng-backend)
- TASK_004: "Update documentation" (mkt-content)
```

### 4. **User Feedback**
```
🧹 Cleaning task planned!
✅ Created 4 cleaning tasks in TODO.md

📋 Cleaning tasks created:
- TASK_001: "Analyze code" (eng-backend)
- TASK_002: "Clean code" (eng-backend)
- TASK_003: "Validate changes" (eng-backend)
- TASK_004: "Update documentation" (mkt-content)

🚀 Next steps:
- Start cleaning: /orchestrate claim TASK_001
- Monitor progress: /orchestrate status
- Complete cleaning: /orchestrate complete TASK_004
```

## 🎯 Cleaning Executor Mapping

### Code & Development
- **eng-backend** : Code cleaning, refactoring
- **eng-devops** : Infrastructure cleaning, cache cleanup

### Documentation & Validation
- **mkt-content** : Documentation updates
- **test-workflow** : Validation testing

## 🔧 Advanced Cleaning Features

### **Comprehensive Cleaning**
```bash
/clean "Full system cleanup"
# Automatically:
# - Cleans code
# - Cleans branches
# - Cleans cache
# - Cleans logs
```

### **Automated Cleaning**
```bash
/clean "Automated cleanup with validation"
# Automatically:
# - Identifies cleanup targets
# - Performs cleanup
# - Validates results
# - Reports changes
```

**Focus** : Universal cleaning command that makes cleaning 5x faster and 100% thorough ! 🧹 