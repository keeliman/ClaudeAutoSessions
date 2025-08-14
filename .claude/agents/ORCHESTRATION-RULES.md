# 🤖 AGENT ORCHESTRATION RULES

## EVERY AGENT MUST FOLLOW THESE 3 RULES:

### 1. **CHECK INBOX**
```bash
# Start of any task-related operation
ls tasks/inbox/
```

### 2. **CLAIM ATOMICALLY**  
```bash
# Your agent name = your folder
mv tasks/inbox/task.txt tasks/working/YOUR-AGENT-NAME/
# If mv fails = someone else got it = check next task
```

### 3. **COMPLETE CLEANLY**
```bash
# When done
mv tasks/working/YOUR-AGENT-NAME/task.txt tasks/done/
```

## 🚫 NEVER DO THIS:
- Don't read then move (race condition)
- Don't create tasks in working/ directly  
- Don't edit files in inbox/ (claim first)
- Don't use TODO.md anymore

## ✅ ALWAYS DO THIS:
- Use YOUR exact agent name as folder
- One task at a time
- Create new tasks in inbox/
- Check working/ to see who's doing what

## 📝 CREATING TASKS:
```bash
# Simple task
echo "Fix login bug" > tasks/inbox/fix-login-bug.txt

# With metadata
cat > tasks/inbox/add-user-api.txt << EOF
Priority: high
Agent: eng-backend
---
Create REST API endpoint for user management
EOF
```

## 🎯 THAT'S ALL!

Filesystem = your orchestrator. No complexity. Just move files.