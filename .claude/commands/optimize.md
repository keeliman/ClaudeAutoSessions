---
name: optimize
description: Universal optimization command - handles all optimization scenarios with intelligent target detection
tools: [Task, Read, Write, Edit, MultiEdit, Bash, Grep, Glob, LS]
orchestration: true
task_type: optimization
estimated_duration: 15
dependencies: []
---

# Universal Optimization Command

Universal optimization command that intelligently detects the optimization target and orchestrates comprehensive optimization workflows through TODO.md.

## 🎯 Intelligent Optimization Detection

### Optimization Types (Auto-detected)
```bash
# Performance Optimization
/optimize "Optimize performance"        → code-performance → eng-backend
/optimize "Improve speed"              → code-performance → eng-backend
/optimize "Performance optimization"    → code-performance → eng-backend

# Workflow Optimization
/optimize "Optimize workflow"           → git-workflow-optimize → eng-devops
/optimize "Improve process"            → git-workflow-optimize → eng-devops
/optimize "Workflow optimization"       → git-workflow-optimize → eng-devops

# Code Optimization
/optimize "Optimize code"              → code-performance → eng-backend
/optimize "Code optimization"          → code-performance → eng-backend
/optimize "Improve code"               → code-performance → eng-backend

# Database Optimization
/optimize "Optimize database"          → code-performance → eng-backend
/optimize "Database optimization"      → code-performance → eng-backend
/optimize "Improve queries"            → code-performance → eng-backend
```

## 🔍 Detection Algorithm

### 1. **Performance Optimization Detection**
- Keywords: "performance", "speed", "fast", "slow", "optimize"
- Triggers: code-performance → eng-backend

### 2. **Workflow Optimization Detection**
- Keywords: "workflow", "process", "efficiency", "automation"
- Triggers: git-workflow-optimize → eng-devops

### 3. **Code Optimization Detection**
- Keywords: "code", "refactor", "improve", "clean"
- Triggers: code-performance → eng-backend

### 4. **Database Optimization Detection**
- Keywords: "database", "queries", "sql", "data"
- Triggers: code-performance → eng-backend

## 🚀 Workflow

### 1. **Optimization Analysis**
```bash
/optimize "Optimize authentication system performance"
# Analysis:
# - "Optimize" → Optimization required
# - "authentication system" → Security + Backend
# - "performance" → Performance optimization
```

### 2. **Optimization Planning**
```yaml
# Auto-selected optimization approach
code-performance: "Authentication system performance optimization"
```

### 3. **Task Creation**
```yaml
# Tasks automatically created in TODO.md
- TASK_001: "Analyze current performance" (ops-analytics)
- TASK_002: "Identify bottlenecks" (eng-backend)
- TASK_003: "Implement optimizations" (eng-backend)
- TASK_004: "Test performance improvements" (test-workflow)
```

### 4. **User Feedback**
```
⚡ Optimization task planned!
✅ Created 4 optimization tasks in TODO.md

📋 Optimization tasks created:
- TASK_001: "Analyze current performance" (ops-analytics)
- TASK_002: "Identify bottlenecks" (eng-backend)
- TASK_003: "Implement optimizations" (eng-backend)
- TASK_004: "Test performance improvements" (test-workflow)

🚀 Next steps:
- Start optimization: /orchestrate claim TASK_001
- Monitor progress: /orchestrate status
- Complete optimization: /orchestrate complete TASK_004
```

## 🎯 Optimization Executor Mapping

### Performance & Code Optimization
- **eng-backend** : Code optimization, performance improvements
- **ops-analytics** : Performance analysis, metrics review

### Workflow & Process Optimization
- **eng-devops** : Workflow optimization, process improvement
- **test-workflow** : Optimization testing, validation

## 🔧 Advanced Optimization Features

### **Comprehensive Optimization**
```bash
/optimize "Full system optimization"
# Automatically:
# - Analyzes performance
# - Identifies bottlenecks
# - Implements improvements
# - Validates results
```

### **Automated Optimization**
```bash
/optimize "Automated optimization with validation"
# Automatically:
# - Runs optimization algorithms
# - Implements improvements
# - Tests performance gains
# - Reports results
```

**Focus** : Universal optimization command that makes optimization 15x faster and 100% effective ! ⚡ 