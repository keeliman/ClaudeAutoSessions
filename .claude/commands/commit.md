---
name: commit
description: Smart commit with AI-powered analysis, quality gates, and project tracking
tools: [Task, Read, Write, Edit, MultiEdit, Bash, Grep, Glob, LS]
orchestration: true
task_type: git
estimated_duration: 5
dependencies: []
---

# Orchestrated Smart Commit

Create intelligent commit with project coordination through TODO.md: $ARGUMENTS

## 🎯 Smart Commit Workflow

### 1. **Commit Analysis & Planning**
```bash
/git-commit "feat(auth): add OAuth2 integration"
# Analysis:
# - "feat" → New feature
# - "auth" → Authentication module
# - "OAuth2" → Security + API integration
```

### 2. **Quality Gate Validation**
```yaml
# Auto-created validation tasks in TODO.md
- TASK_001: "Validate code quality for commit" (eng-reviewer)
- TASK_002: "Check test coverage for commit" (test-analyzer)
- TASK_003: "Security scan for commit" (sec-auditor)
- TASK_004: "Analyze changes for commit" (eng-reviewer)
- TASK_005: "Generate commit message" (mkt-content)
- TASK_006: "Update project tracking" (prod-feedback)
```

### 3. **Intelligent Execution**
```bash
# Pre-commit validation
✅ Code quality: PASSED (score: 9.2/10)
✅ Security scan: PASSED (no issues found)
✅ Test coverage: PASSED (85% coverage maintained)
⚠️  Documentation: REVIEW (missing API docs)

# Generated commit message
feat(auth): add OAuth2 integration with Google

- Implement OAuth2 flow for Google authentication
- Add user profile synchronization with refresh tokens
- Update login UI with Google sign-in button
- Add comprehensive test coverage for auth flows

Closes #123
Co-authored-by: Claude <noreply@anthropic.com>
```

## 🔧 Agent Orchestration

### **Phase 1: Multi-Agent Analysis**
- **eng-reviewer**: Code quality validation and best practices
- **test-analyzer**: Test coverage and regression analysis
- **sec-auditor**: Security scanning and compliance
- **eng-reviewer**: Change analysis and impact assessment

### **Phase 2: Intelligent Synthesis**
- **mkt-content**: Conventional commit message generation
- **prod-feedback**: Project tracking and sprint coordination

### **Phase 3: Quality Gates**
```yaml
# Automated validation checks
- Code Quality: Linting, formatting, complexity analysis
- Security: Secret scanning, vulnerability checks
- Testing: Unit test execution, coverage validation
- Documentation: Code comments, README updates
- Dependencies: Version compatibility, security updates
```

### **Phase 4: Smart Recommendations**
- Suggest files to stage if none staged
- Recommend splitting large commits into focused changes
- Identify related files that should be included
- Suggest issue references and PR associations
- Warn about sensitive content or breaking changes

## 🚀 Usage Examples

### **Feature Commit**
```bash
/git-commit "feat(user): add profile management"
# Automatically:
# - Validates user module changes
# - Checks test coverage for profile features
# - Scans for security issues in user data handling
# - Generates conventional commit message
# - Updates project tracking
```

### **Bug Fix Commit**
```bash
/git-commit "fix(auth): resolve login timeout issue"
# Automatically:
# - Analyzes authentication code changes
# - Validates fix doesn't introduce new issues
# - Checks security implications
# - Updates issue tracking
```

### **Documentation Commit**
```bash
/git-commit "docs(api): update authentication endpoints"
# Automatically:
# - Validates API documentation changes
# - Checks for code-doc consistency
# - Updates README and changelog
```

## 📊 Commit Standards

### **Conventional Commit Format**
```yaml
# Automatic formatting
- Type: feat, fix, docs, style, refactor, test, chore
- Scope: component, module, feature
- Description: Clear, concise description
- Body: Detailed explanation (optional)
- Footer: Breaking changes, issue references
```

### **Quality Metrics**
```yaml
# Automated quality assessment
- Code Quality Score: 0-10 scale
- Security Compliance: PASS/FAIL
- Test Coverage: Percentage maintained
- Documentation: Completeness check
- Performance Impact: Minimal/Moderate/Significant
```

## 🎯 Success Metrics

### **Commit Efficiency**
- **5x faster** : 5min vs 25min average
- **100% compliance** : Conventional commit standards
- **0 quality issues** : Automated validation

### **Quality Assurance**
- **Automated reviews** : Reduced manual effort
- **Security integration** : Built-in security checks
- **Project tracking** : Seamless integration

**Focus** : Smart commit command that makes Git commits 5x faster with 100% quality compliance ! 🔧 