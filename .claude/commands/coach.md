---
name: coach
description: Universal coaching command - handles all coaching scenarios with intelligent session type detection
tools: [Task, Read, Write, Edit, MultiEdit, Bash, Grep, Glob, LS]
orchestration: true
task_type: coaching
estimated_duration: 20
dependencies: []
---

# Universal Coaching Command

Universal coaching command that intelligently detects the coaching need and orchestrates comprehensive coaching workflows through TODO.md.

## 🎯 Intelligent Coaching Detection

### Coaching Types (Auto-detected)
```bash
# Coaching Sessions
/coach "Coaching session"               → coach-mentor
/coach "Training session"              → coach-mentor
/coach "Mentoring session"             → coach-mentor

# Prompt Optimization
/coach "Optimize prompt"               → prompt-optimizer
/coach "Prompt optimization"           → prompt-optimizer
/coach "Improve prompt"                → prompt-optimizer

# Skill Development
/coach "Skill development"             → coach-mentor
/coach "Learn new skill"               → coach-mentor
/coach "Training program"              → coach-mentor

# Performance Coaching
/coach "Performance coaching"          → coach-mentor
/coach "Improve performance"           → coach-mentor
/coach "Performance review"            → coach-mentor
```

## 🔍 Detection Algorithm

### 1. **Coaching Session Detection**
- Keywords: "coaching", "training", "mentoring", "session"
- Triggers: coach-mentor

### 2. **Prompt Optimization Detection**
- Keywords: "prompt", "optimize", "improve", "enhance"
- Triggers: prompt-optimizer

### 3. **Skill Development Detection**
- Keywords: "skill", "learn", "development", "training"
- Triggers: coach-mentor

### 4. **Performance Coaching Detection**
- Keywords: "performance", "improve", "review", "coaching"
- Triggers: coach-mentor

## 🚀 Workflow

### 1. **Coaching Analysis**
```bash
/coach "Coaching session for authentication development"
# Analysis:
# - "Coaching session" → Coaching required
# - "authentication development" → Security + Development
```

### 2. **Coaching Planning**
```yaml
# Auto-selected coaching approach
coach-mentor: "Authentication development coaching session"
```

### 3. **Task Creation**
```yaml
# Tasks automatically created in TODO.md
- TASK_001: "Assess current skills" (coach-mentor)
- TASK_002: "Create learning plan" (coach-mentor)
- TASK_003: "Conduct coaching session" (coach-mentor)
- TASK_004: "Evaluate progress" (coach-mentor)
```

### 4. **User Feedback**
```
🎯 Coaching task planned!
✅ Created 4 coaching tasks in TODO.md

📋 Coaching tasks created:
- TASK_001: "Assess current skills" (coach-mentor)
- TASK_002: "Create learning plan" (coach-mentor)
- TASK_003: "Conduct coaching session" (coach-mentor)
- TASK_004: "Evaluate progress" (coach-mentor)

🚀 Next steps:
- Start coaching: /orchestrate claim TASK_001
- Monitor progress: /orchestrate status
- Complete coaching: /orchestrate complete TASK_004
```

## 🎯 Coaching Executor Mapping

### Coaching & Mentoring
- **coach-mentor** : Coaching sessions, skill development
- **mkt-content** : Learning materials, documentation

### Assessment & Evaluation
- **ops-analytics** : Progress tracking, performance metrics

## 🔧 Advanced Coaching Features

### **Comprehensive Coaching**
```bash
/coach "Full skill development program"
# Automatically:
# - Assesses current skills
# - Creates learning plan
# - Conducts sessions
# - Evaluates progress
```

### **Personalized Coaching**
```bash
/coach "Personalized coaching program"
# Automatically:
# - Analyzes individual needs
# - Creates custom plan
# - Adapts to progress
# - Provides feedback
```

**Focus** : Universal coaching command that makes coaching 20x more effective and 100% personalized ! 🎯 