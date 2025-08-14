---
name: git-ignore
description: Smart .gitignore management with pattern organization
tools: [Read, Write, Edit, Grep, Glob]
orchestration: false
task_type: git
estimated_duration: 1
dependencies: []
---

# Smart .gitignore Management

Add patterns to .gitignore with intelligent categorization: $ARGUMENTS

## 🎯 Smart Ignore Workflow

### 1. **Pattern Analysis**
```bash
/git-ignore "*.log"
# Analysis:
# - Pattern type: Log files
# - Category: Debug/Logs
# - Placement: Under "# Logs" section
```

### 2. **Intelligent Pattern Organization**
```yaml
# Common Categories:
- Dependencies: node_modules/, vendor/, venv/
- Build Output: dist/, build/, *.o, *.exe
- IDE/Editor: .vscode/, .idea/, *.swp
- OS Files: .DS_Store, Thumbs.db
- Logs: *.log, logs/, npm-debug.log*
- Environment: .env, .env.local, *.pem
- Temporary: tmp/, temp/, *.tmp
- Testing: coverage/, .nyc_output/
- Documentation: docs/_build/, *.pdf
```

### 3. **Smart Execution**
```bash
# Pattern validation
✅ Valid pattern: *.log
✅ Category detected: Logs
✅ No conflicts found
✅ Pattern not already present

# Added to .gitignore:
# Logs
*.log
logs/
npm-debug.log*
```

## 🔧 Features

### **Pattern Intelligence**
- Auto-categorization of patterns
- Duplicate detection and prevention
- Pattern conflict resolution
- Smart grouping by file type

### **Category Management**
- Automatic section creation
- Alphabetical ordering within sections
- Comment headers for readability
- Pattern consolidation

### **Validation Checks**
- Syntax validation for glob patterns
- Conflict detection with existing patterns
- Warning for overly broad patterns
- Suggestion for more specific alternatives

## 🚀 Usage Examples

### **Add Single Pattern**
```bash
/git-ignore "*.log"
# Adds to Logs section with related patterns
```

### **Add with Category**
```bash
/git-ignore "*.tmp" "temporary"
# Explicitly adds to Temporary Files section
```

### **Add Multiple Patterns**
```bash
/git-ignore "node_modules/ package-lock.json .npm/"
# Intelligently groups under Dependencies
```

### **Add IDE Files**
```bash
/git-ignore ".vscode/"
# Adds to IDE section with related patterns
```

## 📊 Pattern Categories

### **Standard Categories**
```yaml
# Dependencies
node_modules/
vendor/
bower_components/

# Build
dist/
build/
out/

# IDE
.vscode/
.idea/
*.sublime-*

# Logs
*.log
logs/
npm-debug.log*

# Environment
.env
.env.*
*.pem

# OS
.DS_Store
Thumbs.db
```

## 🎯 Success Metrics

### **Organization Efficiency**
- **Clean structure**: Categorized patterns
- **No duplicates**: Intelligent detection
- **Easy maintenance**: Well-commented sections

### **Pattern Quality**
- **Specific patterns**: Avoid overly broad rules
- **Standard compliance**: Follow .gitignore best practices
- **Project-aware**: Context-sensitive suggestions

**Focus**: Smart .gitignore management that keeps your repository clean and organized! 🔧