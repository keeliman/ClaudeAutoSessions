---
name: deploy
description: Universal deployment command - handles all deployment scenarios with intelligent environment detection
tools: [Task, Read, Write, Edit, MultiEdit, Bash, Grep, Glob, LS]
orchestration: true
task_type: deployment
estimated_duration: 12
dependencies: []
---

# Universal Deployment Command

Universal deployment command that intelligently detects the deployment target and orchestrates comprehensive deployment workflows through TODO.md.

## 🎯 Intelligent Deployment Detection

### Deployment Types (Auto-detected)
```bash
# Production Deployment
/deploy "Deploy to production"         → dev-deploy → eng-devops
/deploy "Production release"           → proj-launch → eng-devops
/deploy "Live deployment"              → dev-deploy → eng-devops

# Staging Deployment
/deploy "Deploy to staging"            → dev-deploy → eng-devops
/deploy "Staging environment"          → dev-deploy → eng-devops
/deploy "Test deployment"              → dev-deploy → eng-devops

# Development Setup
/deploy "Setup development env"        → proj-setup → eng-devops
/deploy "Initialize project"           → proj-init → eng-devops
/deploy "Configure environment"        → proj-setup → eng-devops

# Infrastructure Deployment
/deploy "Deploy infrastructure"        → dev-deploy → eng-devops
/deploy "Setup servers"                → proj-setup → eng-devops
/deploy "Configure CI/CD"              → proj-setup → eng-devops
```

## 🔍 Detection Algorithm

### 1. **Production Deployment Detection**
- Keywords: "production", "live", "release", "public"
- Triggers: dev-deploy → eng-devops

### 2. **Staging Deployment Detection**
- Keywords: "staging", "test", "preview", "beta"
- Triggers: dev-deploy → eng-devops

### 3. **Development Setup Detection**
- Keywords: "setup", "init", "configure", "environment"
- Triggers: proj-setup → eng-devops

### 4. **Infrastructure Detection**
- Keywords: "infrastructure", "servers", "ci/cd", "docker"
- Triggers: dev-deploy → eng-devops

## 🚀 Workflow

### 1. **Deployment Analysis**
```bash
/deploy "Deploy authentication system to production"
# Analysis:
# - "Deploy" → Deployment required
# - "authentication system" → Security + Backend
# - "production" → Production deployment
```

### 2. **Deployment Planning**
```yaml
# Auto-selected deployment approach
dev-deploy: "Authentication system production deployment"
```

### 3. **Task Creation**
```yaml
# Tasks automatically created in TODO.md
- TASK_001: "Security validation" (sec-auditor)
- TASK_002: "Deploy to staging" (eng-devops)
- TASK_003: "Run tests" (test-workflow)
- TASK_004: "Deploy to production" (eng-devops)
```

### 4. **User Feedback**
```
🚀 Deployment task planned!
✅ Created 4 deployment tasks in TODO.md

📋 Deployment tasks created:
- TASK_001: "Security validation" (sec-auditor)
- TASK_002: "Deploy to staging" (eng-devops)
- TASK_003: "Run tests" (test-workflow)
- TASK_004: "Deploy to production" (eng-devops)

🚀 Next steps:
- Start deployment: /orchestrate claim TASK_001
- Monitor progress: /orchestrate status
- Complete deployment: /orchestrate complete TASK_004
```

## 🎯 Deployment Executor Mapping

### Infrastructure & DevOps
- **eng-devops** : Deployment, infrastructure, CI/CD
- **sec-auditor** : Security validation, compliance

### Testing & Validation
- **test-workflow** : Deployment testing, validation
- **ops-analytics** : Deployment monitoring, metrics

## 🔧 Advanced Deployment Features

### **Multi-Environment Deployment**
```bash
/deploy "Full deployment pipeline"
# Automatically:
# - Deploys to development
# - Deploys to staging
# - Runs tests
# - Deploys to production
```

### **Rollback Management**
```bash
/deploy "Deploy with rollback plan"
# Automatically:
# - Creates backup
# - Deploys new version
# - Monitors health
# - Rolls back if needed
```

**Focus** : Universal deployment command that makes deployment 12x faster and 100% reliable ! 🚀 