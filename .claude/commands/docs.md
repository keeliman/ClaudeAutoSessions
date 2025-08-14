---
name: docs
description: Universal documentation command - handles all documentation needs with intelligent content type detection
tools: [Task, Read, Write, Edit, MultiEdit, Bash, Grep, Glob, LS]
orchestration: true
task_type: documentation
estimated_duration: 10
dependencies: []
---

# Universal Documentation Command

Universal documentation command that intelligently detects the type of documentation needed and orchestrates comprehensive documentation workflows through TODO.md.

## 🎯 Intelligent Documentation Detection

### Documentation Types (Auto-detected)
```bash
# API Documentation
/docs "Document API endpoints"        → docs-architecture → mkt-content
/docs "Create API docs"               → docs-generate → mkt-content
/docs "Update API documentation"      → docs-generate → mkt-content

# README and Guides
/docs "Create README"                 → docs-readme → mkt-content
/docs "Update README"                 → docs-readme → mkt-content
/docs "Write user guide"              → docs-generate → mkt-content

# Architecture Documentation
/docs "Document architecture"         → docs-architecture → mkt-content
/docs "Create system docs"            → docs-architecture → mkt-content
/docs "Architecture overview"         → docs-architecture → mkt-content

# Technical Documentation
/docs "Write technical docs"          → docs-generate → mkt-content
/docs "Create developer guide"        → docs-generate → mkt-content
/docs "Document setup process"        → docs-generate → mkt-content
```

## 🔍 Detection Algorithm

### 1. **API Documentation Detection**
- Keywords: "api", "endpoint", "rest", "graphql", "service"
- Triggers: docs-generate → mkt-content

### 2. **README Detection**
- Keywords: "readme", "guide", "overview", "introduction"
- Triggers: docs-readme → mkt-content

### 3. **Architecture Detection**
- Keywords: "architecture", "system", "design", "structure"
- Triggers: docs-architecture → mkt-content

### 4. **Technical Documentation Detection**
- Keywords: "technical", "developer", "setup", "process"
- Triggers: docs-generate → mkt-content

## 🚀 Workflow

### 1. **Documentation Analysis**
```bash
/docs "Document user authentication API"
# Analysis:
# - "Document" → Documentation required
# - "user authentication" → Security + API
# - "API" → API documentation
```

### 2. **Documentation Planning**
```yaml
# Auto-selected documentation type
docs-generate: "User authentication API documentation"
```

### 3. **Task Creation**
```yaml
# Tasks automatically created in TODO.md
- TASK_001: "Analyze authentication API" (eng-backend)
- TASK_002: "Create API documentation" (mkt-content)
- TASK_003: "Add code examples" (eng-backend)
- TASK_004: "Review documentation" (eng-reviewer)
```

### 4. **User Feedback**
```
📚 Documentation task planned!
✅ Created 4 documentation tasks in TODO.md

📋 Documentation tasks created:
- TASK_001: "Analyze authentication API" (eng-backend)
- TASK_002: "Create API documentation" (mkt-content)
- TASK_003: "Add code examples" (eng-backend)
- TASK_004: "Review documentation" (eng-reviewer)

🚀 Next steps:
- Start documentation: /orchestrate claim TASK_001
- Monitor progress: /orchestrate status
- Complete docs: /orchestrate complete TASK_004
```

## 🎯 Documentation Executor Mapping

### Content Creation
- **mkt-content** : Documentation writing, content creation
- **eng-backend** : Technical details, code examples
- **eng-frontend** : UI documentation, screenshots

### Review & Quality
- **eng-reviewer** : Documentation review, accuracy check
- **ops-support** : User perspective, clarity check

## 🔧 Advanced Documentation Features

### **Multi-Format Documentation**
```bash
/docs "Create comprehensive API documentation"
# Automatically creates:
# - Markdown documentation
# - OpenAPI/Swagger specs
# - Code examples
# - Interactive documentation
```

### **Auto-Generated Content**
```bash
/docs "Document current codebase"
# Automatically:
# - Analyzes code structure
# - Generates API documentation
# - Creates setup guides
# - Updates README
```

**Focus** : Universal documentation command that makes documentation 10x faster and 100% comprehensive ! 📚 