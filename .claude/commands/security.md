---
name: security
description: Universal security command - handles all security scenarios with intelligent security type detection
tools: [Task, Read, Write, Edit, MultiEdit, Bash, Grep, Glob, LS]
orchestration: true
task_type: security
estimated_duration: 12
dependencies: []
---

# Universal Security Command

Universal security command that intelligently detects the type of security work needed and orchestrates comprehensive security workflows through TODO.md.

## 🎯 Intelligent Security Detection

### Security Types (Auto-detected)
```bash
# Security Scanning
/security "Security scan"               → dev-security-scan → sec-auditor
/security "Vulnerability scan"          → dev-security-scan → sec-auditor
/security "Security audit"              → dev-security-scan → sec-auditor

# Security Analysis
/security "Security analysis"           → code-security → sec-auditor
/security "Code security"              → code-security → sec-auditor
/security "Security review"            → code-security → sec-auditor

# Workflow Security
/security "Workflow security"           → git-workflow-security → sec-auditor
/security "Security workflow"          → git-workflow-security → sec-auditor
/security "Secure workflow"            → git-workflow-security → sec-auditor

# Security Fixes
/security "Fix vulnerability"          → dev-security-scan → eng-backend
/security "Security fix"               → dev-security-scan → eng-backend
/security "Patch security"             → dev-security-scan → eng-backend
```

## 🔍 Detection Algorithm

### 1. **Security Scanning Detection**
- Keywords: "scan", "audit", "vulnerability", "check"
- Triggers: dev-security-scan → sec-auditor

### 2. **Security Analysis Detection**
- Keywords: "analysis", "review", "code security", "security"
- Triggers: code-security → sec-auditor

### 3. **Workflow Security Detection**
- Keywords: "workflow", "process", "secure", "compliance"
- Triggers: git-workflow-security → sec-auditor

### 4. **Security Fix Detection**
- Keywords: "fix", "patch", "vulnerability", "secure"
- Triggers: dev-security-scan → eng-backend

## 🚀 Workflow

### 1. **Security Analysis**
```bash
/security "Security scan of authentication system"
# Analysis:
# - "Security scan" → Security scanning
# - "authentication system" → Security + Backend
```

### 2. **Security Planning**
```yaml
# Auto-selected security approach
dev-security-scan: "Authentication system security scan"
```

### 3. **Task Creation**
```yaml
# Tasks automatically created in TODO.md
- TASK_001: "Run security scan" (sec-auditor)
- TASK_002: "Analyze vulnerabilities" (sec-auditor)
- TASK_003: "Create security fixes" (eng-backend)
- TASK_004: "Validate security" (sec-auditor)
```

### 4. **User Feedback**
```
🔒 Security task planned!
✅ Created 4 security tasks in TODO.md

📋 Security tasks created:
- TASK_001: "Run security scan" (sec-auditor)
- TASK_002: "Analyze vulnerabilities" (sec-auditor)
- TASK_003: "Create security fixes" (eng-backend)
- TASK_004: "Validate security" (sec-auditor)

🚀 Next steps:
- Start security scan: /orchestrate claim TASK_001
- Monitor progress: /orchestrate status
- Complete security: /orchestrate complete TASK_004
```

## 🎯 Security Executor Mapping

### Security Analysis & Auditing
- **sec-auditor** : Security scanning, vulnerability assessment
- **eng-backend** : Security fixes, code corrections

### Security Validation
- **test-workflow** : Security testing, validation
- **ops-analytics** : Security metrics, monitoring

## 🔧 Advanced Security Features

### **Comprehensive Security**
```bash
/security "Full security audit and fix"
# Automatically:
# - Runs security scans
# - Identifies vulnerabilities
# - Creates fixes
# - Validates security
```

### **Automated Security**
```bash
/security "Automated security with manual review"
# Automatically:
# - Runs automated scans
# - Identifies issues
# - Suggests fixes
# - Requires manual validation
```

**Focus** : Universal security command that makes security 12x faster and 100% comprehensive ! 🔒 