---
name: review
description: Universal review command - handles all review scenarios with intelligent review type detection
tools: [Task, Read, Write, Edit, MultiEdit, Bash, Grep, Glob, LS]
orchestration: true
task_type: review
estimated_duration: 10
dependencies: []
---

# Universal Review Command

Universal review command that intelligently detects the type of review needed and orchestrates comprehensive review workflows through TODO.md.

## 🎯 Intelligent Review Detection

### Review Types (Auto-detected)
```bash
# Code Review
/review "Review code"                   → code-review → eng-reviewer
/review "Code review"                   → code-review → eng-reviewer
/review "Review pull request"           → git-pr-review → eng-reviewer

# PR Review
/review "Review PR #123"               → git-pr-review → eng-reviewer
/review "PR review"                    → git-pr-review → eng-reviewer
/review "Review changes"               → git-pr-review → eng-reviewer

# Security Review
/review "Security review"              → code-review → sec-auditor
/review "Review security"              → code-review → sec-auditor
/review "Security audit"               → code-review → sec-auditor

# Architecture Review
/review "Architecture review"          → code-review → eng-reviewer
/review "Review architecture"          → code-review → eng-reviewer
/review "System review"                → code-review → eng-reviewer
```

## 🔍 Detection Algorithm

### 1. **Code Review Detection**
- Keywords: "code", "review", "pull request", "changes"
- Triggers: code-review → eng-reviewer

### 2. **PR Review Detection**
- Keywords: "pr", "pull request", "merge", "changes"
- Triggers: git-pr-review → eng-reviewer

### 3. **Security Review Detection**
- Keywords: "security", "audit", "vulnerability", "secure"
- Triggers: code-review → sec-auditor

### 4. **Architecture Review Detection**
- Keywords: "architecture", "system", "design", "structure"
- Triggers: code-review → eng-reviewer

## 🚀 Workflow

### 1. **Review Analysis**
```bash
/review "Review authentication code for security"
# Analysis:
# - "Review" → Review required
# - "authentication code" → Security + Code
# - "security" → Security review
```

### 2. **Review Planning**
```yaml
# Auto-selected review approach
code-review: "Authentication code security review"
```

### 3. **Task Creation**
```yaml
# Tasks automatically created in TODO.md
- TASK_001: "Review code quality" (eng-reviewer)
- TASK_002: "Security analysis" (sec-auditor)
- TASK_003: "Performance review" (eng-reviewer)
- TASK_004: "Generate review report" (eng-reviewer)
```

### 4. **User Feedback**
```
👀 Review task planned!
✅ Created 4 review tasks in TODO.md

📋 Review tasks created:
- TASK_001: "Review code quality" (eng-reviewer)
- TASK_002: "Security analysis" (sec-auditor)
- TASK_003: "Performance review" (eng-reviewer)
- TASK_004: "Generate review report" (eng-reviewer)

🚀 Next steps:
- Start review: /orchestrate claim TASK_001
- Monitor progress: /orchestrate status
- View report: /orchestrate complete TASK_004
```

## 🎯 Review Executor Mapping

### Code & Quality Review
- **eng-reviewer** : Code review, quality assessment
- **sec-auditor** : Security review, vulnerability assessment

### Documentation & Reporting
- **mkt-content** : Review documentation, report writing

## 🔧 Advanced Review Features

### **Comprehensive Review**
```bash
/review "Full code and security review"
# Automatically:
# - Reviews code quality
# - Checks security vulnerabilities
# - Analyzes performance
# - Generates recommendations
```

### **Automated Review**
```bash
/review "Automated review with manual validation"
# Automatically:
# - Runs automated checks
# - Identifies issues
# - Suggests improvements
# - Requires manual validation
```

**Focus** : Universal review command that makes reviews 10x faster and 100% thorough ! 👀 