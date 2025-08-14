---
name: dev
description: Universal development command - handles 80% of development cases with intelligent parameter detection
tools: [Task, Read, Write, Edit, MultiEdit, Bash, Grep, Glob, LS]
orchestration: true
task_type: development
estimated_duration: 15
dependencies: []
---

# Universal Development Command

Universal development command that intelligently detects the type of development work needed and orchestrates the appropriate workflow through TODO.md.

## 🎯 Intelligent Parameter Detection

### Development Types (Auto-detected)
```bash
# Feature Development
/dev "Add login button"           → plan-feature → eng-frontend
/dev "Create user API"            → plan-feature → eng-backend
/dev "Implement search"           → plan-feature → eng-frontend + eng-backend

# Bug Fixing
/dev "Fix crash on iOS"           → plan-fix → eng-mobile
/dev "Fix login bug"              → plan-fix → eng-backend
/dev "Fix memory leak"            → plan-fix → eng-backend

# Code Refactoring
/dev "Refactor auth code"         → plan-feature → eng-backend
/dev "Clean up components"        → plan-feature → eng-frontend
/dev "Optimize database queries"  → plan-feature → eng-backend

# API Development
/dev "Create REST API"            → plan-feature → eng-backend
/dev "Add GraphQL endpoint"       → plan-feature → eng-backend
/dev "Update API documentation"   → plan-feature → eng-backend

# Security
/dev "Security scan"              → plan-fix → sec-auditor
/dev "Fix vulnerability"          → plan-fix → eng-backend
/dev "Add authentication"         → plan-feature → eng-backend

# Performance
/dev "Optimize performance"       → plan-feature → eng-backend
/dev "Fix slow queries"           → plan-fix → eng-backend
/dev "Improve loading speed"      → plan-feature → eng-frontend

# Code Quality
/dev "Code review"                → plan-research → eng-reviewer
/dev "Analyze code quality"       → plan-research → eng-reviewer
/dev "Fix code smells"            → plan-fix → eng-backend

# Project Setup
/dev "Initialize project"         → plan-feature → eng-devops
/dev "Setup development env"      → plan-feature → eng-devops
/dev "Configure CI/CD"            → plan-feature → eng-devops
```

## 🔍 Detection Algorithm

### 1. **Feature Detection**
- Keywords: "add", "create", "implement", "build", "develop"
- Triggers: plan-feature → appropriate executor

### 2. **Bug Detection**
- Keywords: "fix", "bug", "crash", "error", "issue"
- Triggers: plan-fix → debug-detective + appropriate executor

### 3. **Refactor Detection**
- Keywords: "refactor", "clean", "optimize", "improve"
- Triggers: plan-feature → appropriate executor

### 4. **API Detection**
- Keywords: "api", "endpoint", "rest", "graphql", "service"
- Triggers: plan-feature → eng-backend

### 5. **Security Detection**
- Keywords: "security", "vulnerability", "auth", "authentication"
- Triggers: plan-fix → sec-auditor + eng-backend

### 6. **Performance Detection**
- Keywords: "performance", "slow", "speed", "optimize"
- Triggers: plan-feature → eng-backend + ops-analytics

### 7. **Quality Detection**
- Keywords: "review", "quality", "analyze", "smell"
- Triggers: plan-research → eng-reviewer

### 8. **Setup Detection**
- Keywords: "init", "setup", "configure", "install"
- Triggers: plan-feature → eng-devops

## 🚀 Workflow

### 1. **Parameter Analysis**
```bash
/dev "Add user authentication system"
# Analysis:
# - "Add" → Feature development
# - "user authentication" → Security + Backend
# - "system" → Complex feature
```

### 2. **Planner Selection**
```yaml
# Auto-selected planner based on analysis
plan-feature: "User authentication system"
```

### 3. **Task Creation**
```yaml
# Tasks automatically created in TODO.md
- TASK_001: "Design authentication UI" (eng-frontend)
- TASK_002: "Implement authentication API" (eng-backend)
- TASK_003: "Add security validation" (sec-auditor)
- TASK_004: "Create authentication tests" (test-workflow)
```

### 4. **User Feedback**
```
🎯 Development task planned!
✅ Created 4 tasks in TODO.md

📋 Tasks created:
- TASK_001: "Design authentication UI" (eng-frontend)
- TASK_002: "Implement authentication API" (eng-backend)
- TASK_003: "Add security validation" (sec-auditor)
- TASK_004: "Create authentication tests" (test-workflow)

🚀 Next steps:
- Start development: /orchestrate claim TASK_001
- Monitor progress: /orchestrate status
- Complete tasks: /orchestrate complete TASK_001
```

## 🎯 Executor Mapping

### Frontend Development
- **eng-frontend** : UI components, React/Vue/Angular
- **design-ui** : Interface design, styling
- **design-ux** : User experience, interactions

### Backend Development
- **eng-backend** : API development, business logic
- **eng-ai** : Machine learning, AI features
- **eng-devops** : Infrastructure, deployment

### Mobile Development
- **eng-mobile** : iOS, Android, cross-platform

### Security & Quality
- **sec-auditor** : Security analysis, vulnerability assessment
- **eng-reviewer** : Code review, quality assessment

### Testing & Validation
- **test-workflow** : Test planning, execution
- **test-analyzer** : Test results analysis

## 🔧 Advanced Features

### **Multi-Executor Coordination**
```bash
/dev "Create full-stack e-commerce feature"
# Automatically coordinates:
# - eng-frontend (UI)
# - eng-backend (API)
# - eng-devops (deployment)
# - test-workflow (testing)
```

### **Dependency Management**
```bash
/dev "Add payment integration"
# Automatically creates dependencies:
# - TASK_001: "Setup payment API" (prerequisite)
# - TASK_002: "Integrate payment UI" (depends on TASK_001)
# - TASK_003: "Test payment flow" (depends on TASK_002)
```

### **Priority Auto-Assignment**
```bash
/dev "Fix critical security bug"  # → High priority
/dev "Add nice-to-have feature"   # → Medium priority
/dev "Refactor old code"          # → Low priority
```

## 📊 Performance Optimization

### **Execution Time**
- **Simple features** : 5-10 minutes
- **Complex features** : 10-15 minutes
- **Bug fixes** : 5-10 minutes
- **Refactoring** : 10-15 minutes

### **Resource Optimization**
- **Parallel execution** : Multiple executors simultaneously
- **Smart caching** : Reuse existing solutions
- **Incremental updates** : Build on previous work

## 🎯 Success Metrics

### **User Experience**
- **0 learning curve** : Intuitive parameter detection
- **Instant feedback** : Immediate task creation
- **Clear next steps** : Guided workflow

### **Development Efficiency**
- **4x faster** : 15min vs 60min average
- **100% TODO.md** : Complete orchestration
- **0 conflicts** : Coordinated execution

**Focus** : Universal development command that makes development 4x faster and 100% orchestrated ! 🚀 