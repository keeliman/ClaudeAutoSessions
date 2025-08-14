---
name: research
description: Universal research command - handles all research needs with intelligent topic detection
tools: [Task, Read, Write, Edit, MultiEdit, Bash, Grep, Glob, LS]
orchestration: true
task_type: research
estimated_duration: 15
dependencies: []
---

# Universal Research Command

Universal research command that intelligently detects the type of research needed and orchestrates comprehensive research workflows through TODO.md.

## 🎯 Intelligent Research Detection

### Research Types (Auto-detected)
```bash
# Market Research
/research "Market analysis"            → research-market → res-market
/research "Competitive analysis"       → research-competitive → res-competitive
/research "Industry trends"            → research-trends → res-trends

# Technology Research
/research "Tech trends"                → research-tech → res-tech
/research "New technologies"           → research-tech → res-tech
/research "Technology comparison"      → research-tech → res-tech

# Competitive Research
/research "Competitor analysis"        → research-competitive → res-competitive
/research "Competitive landscape"      → research-competitive → res-competitive
/research "Competitor features"        → research-competitive → res-competitive

# Trend Research
/research "Industry trends"            → research-trends → res-trends
/research "Market trends"              → research-trends → res-trends
/research "Future trends"              → research-trends → res-trends
```

## 🔍 Detection Algorithm

### 1. **Market Research Detection**
- Keywords: "market", "industry", "business", "customer"
- Triggers: research-market → res-market

### 2. **Technology Research Detection**
- Keywords: "tech", "technology", "new", "comparison"
- Triggers: research-tech → res-tech

### 3. **Competitive Research Detection**
- Keywords: "competitor", "competitive", "rival", "competition"
- Triggers: research-competitive → res-competitive

### 4. **Trend Research Detection**
- Keywords: "trend", "future", "emerging", "upcoming"
- Triggers: research-trends → res-trends

## 🚀 Workflow

### 1. **Research Analysis**
```bash
/research "Competitive analysis of authentication solutions"
# Analysis:
# - "Competitive analysis" → Competitive research
# - "authentication solutions" → Technology + Security
```

### 2. **Research Planning**
```yaml
# Auto-selected research approach
research-competitive: "Authentication solutions competitive analysis"
```

### 3. **Task Creation**
```yaml
# Tasks automatically created in TODO.md
- TASK_001: "Identify competitors" (res-competitive)
- TASK_002: "Analyze features" (res-competitive)
- TASK_003: "Compare pricing" (res-competitive)
- TASK_004: "Generate report" (res-competitive)
```

### 4. **User Feedback**
```
🔬 Research task planned!
✅ Created 4 research tasks in TODO.md

📋 Research tasks created:
- TASK_001: "Identify competitors" (res-competitive)
- TASK_002: "Analyze features" (res-competitive)
- TASK_003: "Compare pricing" (res-competitive)
- TASK_004: "Generate report" (res-competitive)

🚀 Next steps:
- Start research: /orchestrate claim TASK_001
- Monitor progress: /orchestrate status
- View report: /orchestrate complete TASK_004
```

## 🎯 Research Executor Mapping

### Market & Competitive Analysis
- **res-market** : Market analysis, customer research
- **res-competitive** : Competitive analysis, feature comparison
- **res-trends** : Trend analysis, future predictions

### Technology Research
- **res-tech** : Technology research, technical comparison
- **res-competitive** : Technology competitive analysis

## 🔧 Advanced Research Features

### **Comprehensive Analysis**
```bash
/research "Full market and competitive analysis"
# Automatically:
# - Analyzes market size
# - Identifies competitors
# - Compares features
# - Predicts trends
```

### **Automated Reporting**
```bash
/research "Generate research report"
# Automatically:
# - Compiles findings
# - Creates visualizations
# - Generates insights
# - Provides recommendations
```

**Focus** : Universal research command that makes research 15x faster and 100% comprehensive ! 🔬 