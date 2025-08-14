---
name: backup
description: Universal backup command - handles all backup scenarios with intelligent backup type detection
tools: [Task, Read, Write, Edit, MultiEdit, Bash, Grep, Glob, LS]
orchestration: true
task_type: backup
estimated_duration: 8
dependencies: []
---

# Universal Backup Command

Universal backup command that intelligently detects the backup target and orchestrates comprehensive backup workflows through TODO.md.

## 🎯 Intelligent Backup Detection

### Backup Types (Auto-detected)
```bash
# Data Backup
/backup "Backup data"                   → git-history → eng-devops
/backup "Data backup"                  → git-history → eng-devops
/backup "Backup database"              → git-history → eng-devops

# Version Backup
/backup "Backup version"               → git-history → eng-devops
/backup "Version backup"               → git-history → eng-devops
/backup "Restore version"              → git-history → eng-devops

# Configuration Backup
/backup "Backup config"                → git-history → eng-devops
/backup "Config backup"                → git-history → eng-devops
/backup "Backup settings"              → git-history → eng-devops

# Code Backup
/backup "Backup code"                  → git-history → eng-devops
/backup "Code backup"                  → git-history → eng-devops
/backup "Backup repository"            → git-history → eng-devops
```

## 🔍 Detection Algorithm

### 1. **Data Backup Detection**
- Keywords: "data", "database", "backup", "save"
- Triggers: git-history → eng-devops

### 2. **Version Backup Detection**
- Keywords: "version", "restore", "rollback", "backup"
- Triggers: git-history → eng-devops

### 3. **Configuration Backup Detection**
- Keywords: "config", "settings", "configuration", "backup"
- Triggers: git-history → eng-devops

### 4. **Code Backup Detection**
- Keywords: "code", "repository", "source", "backup"
- Triggers: git-history → eng-devops

## 🚀 Workflow

### 1. **Backup Analysis**
```bash
/backup "Backup authentication system data"
# Analysis:
# - "Backup" → Backup required
# - "authentication system" → Security + Data
# - "data" → Data backup
```

### 2. **Backup Planning**
```yaml
# Auto-selected backup approach
git-history: "Authentication system data backup"
```

### 3. **Task Creation**
```yaml
# Tasks automatically created in TODO.md
- TASK_001: "Create backup" (eng-devops)
- TASK_002: "Validate backup" (eng-devops)
- TASK_003: "Store backup" (eng-devops)
- TASK_004: "Test restore" (eng-devops)
```

### 4. **User Feedback**
```
💾 Backup task planned!
✅ Created 4 backup tasks in TODO.md

📋 Backup tasks created:
- TASK_001: "Create backup" (eng-devops)
- TASK_002: "Validate backup" (eng-devops)
- TASK_003: "Store backup" (eng-devops)
- TASK_004: "Test restore" (eng-devops)

🚀 Next steps:
- Start backup: /orchestrate claim TASK_001
- Monitor progress: /orchestrate status
- Complete backup: /orchestrate complete TASK_004
```

## 🎯 Backup Executor Mapping

### Infrastructure & DevOps
- **eng-devops** : Backup creation, storage, restoration
- **ops-analytics** : Backup validation, monitoring

### Validation & Testing
- **test-workflow** : Backup testing, restore validation

## 🔧 Advanced Backup Features

### **Comprehensive Backup**
```bash
/backup "Full system backup"
# Automatically:
# - Backs up data
# - Backs up configuration
# - Backs up code
# - Tests restoration
```

### **Automated Backup**
```bash
/backup "Automated backup with validation"
# Automatically:
# - Creates backup
# - Validates integrity
# - Stores securely
# - Tests restore
```

**Focus** : Universal backup command that makes backup 8x faster and 100% reliable ! 💾 