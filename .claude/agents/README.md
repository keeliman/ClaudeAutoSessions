# Claude Code Agents - Orchestrated Architecture

This repository uses a **planner-executor pattern** with centralized orchestration through CLAUDE.md.

## Directory Structure

```
.claude/agents/
├── planners/          # Agents that CREATE tasks
├── executors/         # Agents that EXECUTE tasks  
└── orchestration/     # System-level orchestration agents
```

## How It Works

### 1. Planning Phase
**Planner agents** analyze requirements and create tasks:
- `plan-architect` - Overall project planning
- `plan-feature` - Feature breakdown
- `plan-debug` - Bug fix planning
- `plan-system` - Architecture planning
- `plan-product` - Product strategy
- `plan-sprint` - Sprint planning

Planners use `/orchestrate create` to add tasks to CLAUDE.md.

### 2. Execution Phase
**Executor agents** claim and complete tasks:
- **Engineering**: `eng-frontend`, `eng-backend`, `eng-mobile`, etc.
- **Design**: `design-ui`, `design-ux`, `design-brand`, etc.
- **Testing**: `test-api`, `test-performance`, etc.
- **Marketing**: `mkt-content`, `mkt-growth`, etc.
- **Operations**: `ops-support`, `ops-analytics`, etc.
- **Research**: `research-market`, `research-tech`, etc.

Executors use:
- `/orchestrate claim [task-id]` - Claim a task
- `/orchestrate progress [task-id] [%]` - Update progress
- `/orchestrate complete [task-id]` - Mark complete

### 3. Orchestration Layer
**System agents** manage the entire process:
- `orchestrate-manager` - Master coordinator
- `state-manager` - State management API

## Workflow Example

```
User Request: "Build user authentication"
    ↓
plan-architect: Creates 10 tasks in CLAUDE.md
    ↓
eng-backend: Claims "Implement JWT service"
eng-frontend: Claims "Create login form"
test-api: Claims "Write auth tests"
    ↓
All executors work in parallel, updating progress
    ↓
Tasks completed, feature delivered
```

## Key Benefits

1. **No Duplication**: Tasks created once, executed once
2. **Clear Separation**: Planners think, executors do
3. **Full Tracking**: Every task tracked in CLAUDE.md
4. **Parallel Work**: Multiple executors can work simultaneously
5. **Audit Trail**: Complete history of who did what

## Using the System

### For Planning
```bash
# Commands delegate to planners
/dev-feature "shopping cart"
/dev-bug-fix "slow page load"
/proj-setup "new React app"
```

### For Execution
```bash
# View available tasks
/orchestrate status todo

# Claim and work
/orchestrate claim TASK_001
/orchestrate progress TASK_001 50 "Halfway done"
/orchestrate complete TASK_001 "All tests passing"
```

### For Monitoring
```bash
# Check progress
/orchestrate status active
/orchestrate status mine
```

## Agent Categories

### Planners (7 agents)
Create comprehensive task breakdowns for different domains

### Executors (40+ agents)
- **Engineering** (7): Frontend, backend, mobile, AI, DevOps
- **Design** (5): UI, UX, brand, visual, whimsy
- **Debugging** (3): Detective, fixer, security
- **Testing** (5): API, performance, tools, workflow
- **Marketing** (7): Content, growth, social platforms
- **Operations** (8): Support, analytics, infrastructure
- **Research** (5): Market, tech, competitive analysis
- **Specialized** (3): Coaching, optimization, feedback

## Installation

1. Copy agents to your project: `.claude/agents/`
2. Or install globally: `~/.claude/agents/`
3. Commands go in: `.claude/commands/`

## Integration

All agents and commands integrate with this system:
- Commands use planners to create tasks
- Planners create structured task lists
- Executors claim and complete work
- State-manager ensures consistency
- CLAUDE.md provides real-time visibility

This architecture ensures efficient, organized, and trackable development workflows.