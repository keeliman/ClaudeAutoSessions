---
name: kiss
description: Transform complex features into KISS (Keep It Simple, Stupid) implementations
tools: [Task, Read, Write, Edit, MultiEdit, Bash, Grep, Glob, LS]
orchestration: true
task_type: architecture
estimated_duration: 15
dependencies: []
---

# KISS Feature Transformation

Transform complex feature into simple, elegant implementation: $ARGUMENTS

## 🎯 KISS Philosophy Workflow

### 1. **Complexity Analysis**
```bash
/kiss "user authentication system with OAuth, SAML, LDAP, 2FA"
# Analysis:
# - Current: 4 auth methods + 2FA = high complexity
# - KISS: Start with email/password + optional 2FA
# - 80/20 rule: Email auth covers 80% of users
```

### 2. **Simplification Planning**
```yaml
# Auto-created planning tasks in TODO.md
- TASK_001: "Analyze feature complexity" (plan-architect)
- TASK_002: "Create KISS plan" (plan-feature) 
- TASK_003: "Validate KISS approach" (eng-reviewer)
- TASK_004: "Execute MVP implementation" (eng-backend)
- TASK_005: "Create simple UI" (eng-frontend)
- TASK_006: "Write basic tests" (test-workflow)
```

### 3. **KISS Validation Gate**
```bash
# Validation criteria
✅ Single responsibility: Each component has one job
✅ Minimal dependencies: Only essential packages
✅ Clear naming: Functions and variables are self-explanatory
✅ Linear flow: No complex state machines
✅ Easy testing: Simple unit tests possible
⚠️  Performance: May need optimization later
```

## 🔧 KISS Principles

### **Simplification Rules**
- **One feature at a time**: No kitchen sink implementations
- **80/20 approach**: Handle 80% of use cases simply
- **Defer complexity**: Add features only when needed
- **Clear abstractions**: Hide complexity behind simple interfaces

### **Complexity Reduction**
- **Remove abstractions**: Favor concrete over generic
- **Inline small functions**: Reduce call stack depth
- **Minimize dependencies**: Use standard library when possible
- **Single file when possible**: Avoid over-modularization

### **KISS Validation Checklist**
```yaml
# Automated validation
- Code readability: Can junior dev understand in 5min?
- Function length: Max 20 lines per function
- File length: Max 200 lines per file
- Dependencies: Max 5 external packages
- Abstraction layers: Max 3 levels deep
- Configuration: Single config file
```

## 🚀 Usage Examples

### **Complex E-commerce Cart**
```bash
/kiss "shopping cart with inventory, pricing, promotions, shipping"
# KISS Plan:
# 1. Simple cart: add/remove items
# 2. Basic total calculation
# 3. Checkout with fixed shipping
# 4. Defer: dynamic pricing, promotions
```

### **Over-engineered API**
```bash
/kiss "REST API with GraphQL, caching, rate limiting, auth layers"
# KISS Plan:
# 1. Simple REST endpoints
# 2. Basic authentication
# 3. In-memory data store
# 4. Defer: GraphQL, Redis, complex auth
```

### **Complex Dashboard**
```bash
/kiss "analytics dashboard with real-time, filters, exports, alerts"
# KISS Plan:
# 1. Static charts with basic data
# 2. Simple table view
# 3. CSV export only
# 4. Defer: real-time, complex filters
```

## 🎯 Agent Orchestration

### **Phase 1: Analysis & Planning**
- **plan-architect**: Complexity analysis and simplification strategy
- **plan-feature**: KISS implementation roadmap
- **eng-reviewer**: Technical validation of approach

### **Phase 2: KISS Validation**
```yaml
# Validation Gates
- Complexity Score: Must be < 5/10
- Learning Curve: Junior dev ready in < 1 day
- Testing Effort: Unit tests in < 2 hours
- Maintenance: Single developer can maintain
```

### **Phase 3: Simple Implementation**
- **eng-backend**: Core functionality with minimal features
- **eng-frontend**: Simple, intuitive UI
- **test-workflow**: Basic test coverage

### **Phase 4: Documentation**
- **mkt-content**: Clear, concise documentation
- **design-visual**: Simple architecture diagrams

## 📊 KISS Metrics

### **Simplicity Indicators**
```yaml
# Automated measurement
- Cyclomatic Complexity: < 10 per function
- Lines of Code: Minimal viable implementation
- Dependencies: Essential only
- Configuration: Single source of truth
- Documentation: Self-explanatory code
```

### **Success Criteria**
- **Time to understand**: < 30 minutes for new developer
- **Time to modify**: < 2 hours for simple changes
- **Bug rate**: < 1 bug per 100 lines
- **Test coverage**: > 80% with simple tests

## 🔄 KISS Evolution

### **Phase-based Growth**
```yaml
# Version 1: KISS MVP
- Core functionality only
- Minimal UI
- Basic error handling

# Version 2: Essential Features
- User feedback-driven additions
- Performance optimizations
- Better error messages

# Version 3: Mature Product
- Advanced features if proven necessary
- Maintain simplicity as core principle
```

### **Anti-patterns to Avoid**
- **Premature optimization**: Optimize only when needed
- **Over-abstraction**: Don't abstract until third use
- **Feature creep**: Resist adding "just in case" features
- **Complex configurations**: Favor convention over configuration

## 🎯 Success Metrics

### **Simplicity Achievement**
- **Development speed**: 3x faster than complex approach
- **Bug reduction**: 50% fewer bugs due to simplicity
- **Maintenance cost**: 70% less time spent on maintenance

### **Team Productivity**
- **Onboarding time**: New developers productive in 1 day
- **Code review time**: 50% faster reviews
- **Testing effort**: Simple tests, high coverage

**Focus**: KISS command that transforms complex features into elegantly simple solutions that actually work! 🚀