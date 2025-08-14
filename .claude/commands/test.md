---
name: test
description: Universal testing command - handles all testing scenarios with intelligent test type detection
tools: [Task, Read, Write, Edit, MultiEdit, Bash, Grep, Glob, LS]
orchestration: true
task_type: testing
estimated_duration: 10
dependencies: []
---

# Universal Testing Command

Universal testing command that intelligently detects the type of testing needed and orchestrates comprehensive test workflows through TODO.md.

## 🎯 Intelligent Test Type Detection

### Testing Types (Auto-detected)
```bash
# Unit Testing
/test "Unit test login function"      → test-analyzer
/test "Test user validation"          → test-analyzer
/test "Unit tests for API"            → test-api

# Integration Testing
/test "Test login flow"               → test-workflow
/test "Integration test payment"      → test-workflow
/test "Test API endpoints"            → test-api

# UI Testing
/test "Test login form"               → test-workflow
/test "UI test shopping cart"         → test-workflow
/test "Test responsive design"        → test-workflow

# Performance Testing
/test "Performance test database"     → test-performance
/test "Load test API"                 → test-performance
/test "Speed test login"              → test-performance

# Security Testing
/test "Security test authentication"  → test-workflow
/test "Penetration test API"          → test-workflow
/test "Vulnerability scan"            → test-workflow

# End-to-End Testing
/test "E2E test user journey"         → test-workflow
/test "Full workflow test"            → test-workflow
/test "Complete user flow"            → test-workflow
```

## 🔍 Detection Algorithm

### 1. **Unit Test Detection**
- Keywords: "unit", "function", "method", "class", "component"
- Triggers: test-analyzer

### 2. **Integration Test Detection**
- Keywords: "integration", "flow", "workflow", "endpoint", "api"
- Triggers: test-workflow or test-api

### 3. **UI Test Detection**
- Keywords: "ui", "form", "interface", "design", "responsive"
- Triggers: test-workflow

### 4. **Performance Test Detection**
- Keywords: "performance", "load", "speed", "stress", "benchmark"
- Triggers: test-performance

### 5. **Security Test Detection**
- Keywords: "security", "penetration", "vulnerability", "auth"
- Triggers: test-workflow

### 6. **E2E Test Detection**
- Keywords: "e2e", "journey", "complete", "full", "end-to-end"
- Triggers: test-workflow

## 🚀 Workflow

### 1. **Test Analysis**
```bash
/test "Test user authentication flow"
# Analysis:
# - "Test" → Testing required
# - "user authentication" → Security + Integration
# - "flow" → Integration testing
```

### 2. **Test Planning**
```yaml
# Auto-selected test strategy
test-workflow: "User authentication flow testing"
```

### 3. **Task Creation**
```yaml
# Tasks automatically created in TODO.md
- TASK_001: "Setup test environment" (test-workflow)
- TASK_002: "Create authentication test cases" (test-analyzer)
- TASK_003: "Execute integration tests" (test-workflow)
- TASK_004: "Analyze test results" (test-analyzer)
```

### 4. **User Feedback**
```
🧪 Testing task planned!
✅ Created 4 test tasks in TODO.md

📋 Test tasks created:
- TASK_001: "Setup test environment" (test-workflow)
- TASK_002: "Create authentication test cases" (test-analyzer)
- TASK_003: "Execute integration tests" (test-workflow)
- TASK_004: "Analyze test results" (test-analyzer)

🚀 Next steps:
- Start testing: /orchestrate claim TASK_001
- Monitor progress: /orchestrate status
- View results: /orchestrate complete TASK_004
```

## 🎯 Test Executor Mapping

### Test Planning & Analysis
- **test-analyzer** : Test case design, result analysis
- **test-workflow** : Test execution, workflow management

### Specialized Testing
- **test-api** : API testing, endpoint validation
- **test-performance** : Performance testing, load testing
- **test-tools** : Testing tool setup, configuration

### Quality Assurance
- **test-workflow** : QA process, test automation
- **test-analyzer** : Quality metrics, coverage analysis

## 🔧 Advanced Testing Features

### **Multi-Layer Testing**
```bash
/test "Comprehensive user registration"
# Automatically creates:
# - Unit tests (validation functions)
# - Integration tests (API endpoints)
# - UI tests (registration form)
# - E2E tests (complete flow)
```

### **Test Environment Management**
```bash
/test "Test with production data"
# Automatically:
# - Sets up test environment
# - Configures test data
# - Manages test isolation
# - Cleans up after tests
```

### **Test Result Analysis**
```bash
/test "Analyze test coverage"
# Automatically:
# - Runs coverage analysis
# - Identifies gaps
# - Suggests additional tests
# - Generates coverage report
```

## 📊 Testing Performance

### **Execution Time**
- **Unit tests** : 2-5 minutes
- **Integration tests** : 5-10 minutes
- **UI tests** : 5-10 minutes
- **Performance tests** : 10-15 minutes
- **Security tests** : 10-15 minutes

### **Test Coverage**
- **Automatic coverage** : Minimum 80% target
- **Critical path coverage** : 100% required
- **Edge case coverage** : Comprehensive testing

## 🎯 Testing Best Practices

### **Test Pyramid**
```yaml
# Automatically follows test pyramid
- Unit tests: 70% (fast, focused)
- Integration tests: 20% (medium speed)
- E2E tests: 10% (slow, comprehensive)
```

### **Test Data Management**
```yaml
# Automatic test data handling
- Fixtures: Predefined test data
- Factories: Dynamic test data generation
- Cleanup: Automatic test data cleanup
```

### **Test Reporting**
```yaml
# Comprehensive test reporting
- Coverage reports: Code coverage metrics
- Performance reports: Speed and load metrics
- Security reports: Vulnerability assessment
- Quality reports: Overall test quality
```

## 🚀 Success Metrics

### **Testing Efficiency**
- **10x faster** : 10min vs 100min average
- **100% coverage** : Comprehensive testing
- **0 false positives** : Accurate test results

### **Quality Assurance**
- **Automated testing** : Reduced manual effort
- **Continuous testing** : Integrated in workflow
- **Quality gates** : Automated quality checks

**Focus** : Universal testing command that makes testing 10x faster and 100% comprehensive ! 🧪 