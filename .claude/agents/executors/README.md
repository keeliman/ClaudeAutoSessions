# Executor Agents

Executor agents are responsible for claiming and completing tasks from CLAUDE.md. They focus on implementation and delivery, working on tasks created by planner agents.

## How Executors Work

1. **Claim Tasks**: Use `/orchestrate claim [task-id]` to claim a task
2. **Implement Solution**: Do the actual work (code, design, test, etc.)
3. **Update Progress**: Use `/orchestrate progress [task-id] [%] "[note]"`
4. **Complete Tasks**: Use `/orchestrate complete [task-id] "[completion-notes]"`

## Executor Categories

### 🛠️ Engineering Executors
Located in `.claude/agents/engineering/`
- `eng-frontend`: UI implementation, React/Vue/Angular
- `eng-backend`: API development, databases, services
- `eng-mobile`: iOS/Android app development
- `eng-ai`: ML model implementation, data pipelines
- `eng-devops`: Infrastructure, CI/CD, deployment

### 🎨 Design Executors
Located in `.claude/agents/design/`
- `design-ui`: Interface design implementation
- `design-ux`: User research execution
- `design-brand`: Brand asset creation
- `design-visual`: Data visualization, infographics

### 🔍 Debug Executors
Located in `.claude/agents/debug/`
- `debug-detective`: Bug investigation and analysis
- `debug-fixer`: Bug fixing and code correction

### 🧪 Testing Executors
Located in `.claude/agents/testing/`
- `test-api`: API test implementation
- `test-performance`: Performance testing execution
- `test-tools`: Testing tool setup and configuration

### 📈 Marketing Executors
Located in `.claude/agents/marketing/`
- `mkt-content`: Content creation and SEO
- `mkt-growth`: Growth experiment execution
- Platform-specific: `mkt-tiktok`, `mkt-instagram`, etc.

## Executor Workflow

```yaml
1. Check Available Tasks:
   /orchestrate status todo
   
2. Claim a Task:
   /orchestrate claim TASK_001
   # or claim next available
   /orchestrate claim next
   
3. Work on Task:
   - Read requirements
   - Implement solution
   - Test thoroughly
   
4. Update Progress:
   /orchestrate progress TASK_001 50 "Implemented core logic"
   /orchestrate progress TASK_001 75 "Adding tests"
   
5. Complete Task:
   /orchestrate complete TASK_001 "All acceptance criteria met"
```

## Executor Best Practices

### Before Starting
1. **Read Task Completely**: Understand all acceptance criteria
2. **Check Dependencies**: Ensure prerequisite tasks are done
3. **Claim Atomically**: Use orchestration to avoid conflicts

### During Execution
1. **Update Regularly**: Progress updates every 30-60 minutes
2. **Follow Standards**: Match existing code style
3. **Test Thoroughly**: Meet all acceptance criteria
4. **Document Issues**: Note any blockers or concerns

### After Completion
1. **Verify Criteria**: Double-check all requirements met
2. **Update Status**: Mark complete with notes
3. **Clean Up**: Commit code, update docs
4. **Hand Off**: Note any follow-up needed

## Executor Selection

Planners suggest executors, but you can reassign:

```bash
# View suggested executor
/orchestrate status TASK_001

# Reassign if needed
/orchestrate assign TASK_001 eng-frontend
```

## Blocked Task Handling

If blocked during execution:

```bash
# Mark task as blocked
/orchestrate block TASK_001 "Waiting for API credentials from client"

# When unblocked
/orchestrate unblock TASK_001
/orchestrate claim TASK_001
```

## Quality Standards

All executors must:
- Meet acceptance criteria completely
- Follow project coding standards
- Include appropriate tests
- Update documentation
- Handle errors gracefully

## Integration Example

```bash
# Planner creates task
plan-feature: Creates "Implement user login form"

# Frontend executor claims and implements
eng-frontend: 
  /orchestrate claim TASK_001
  # ... implements login form ...
  /orchestrate progress TASK_001 50 "Created form component"
  # ... adds validation ...
  /orchestrate progress TASK_001 75 "Added form validation"
  # ... writes tests ...
  /orchestrate complete TASK_001 "Login form complete with tests"

# Backend executor works on related task
eng-backend:
  /orchestrate claim TASK_002  # "Create login API endpoint"
  # ... implements endpoint ...
```

This separation ensures clear responsibilities: planners think and organize, executors build and deliver.