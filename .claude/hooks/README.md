# Skill Lifecycle Management System

## Overview

The Skill Lifecycle Management System provides intelligent, context-aware activation and deactivation of skills in Claude Code. Instead of always loading all skills, the system:

- **Activates skills dynamically** based on relevance to the current prompt
- **Resolves dependencies automatically** - activates required skills when parent skills load
- **Deactivates skills** when their work is complete or they become idle
- **Tracks conversation state** to maintain context across prompts
- **Reduces context bloat** by only loading relevant skills
- **Provides visual feedback** on skill lifecycle status and dependencies

## Architecture

### Core Components

1. **lifecycleManager.js** - Core lifecycle logic
   - State management and persistence
   - Relevance scoring
   - Activation/deactivation detection
   - Prompt processing

2. **lifecycle-rules.json** - Deactivation rules and settings
   - Completion signals per skill
   - Timeout configurations
   - Relevance thresholds

3. **conversation-state.json** - Runtime state (gitignored)
   - Active skills with metadata
   - Completed skills
   - Conversation context

4. **skill-rules.json** - Enhanced with lifecycle configuration
   - Each skill now has a `lifecycle` object
   - Defines min relevance scores, timeouts, and reactivation rules

### Lifecycle States

- `inactive` - Not loaded, not in context
- `active` - Currently loaded and in use
- `idle` - Loaded but not recently referenced
- `completed` - Work finished, deactivated
- `suspended` - Temporarily deactivated due to idle timeout

## Features

### 1. Context Detection

The system detects BC-related queries vs general queries:

**BC Context Indicators:**
- AL object types (table, page, codeunit, enum, etc.)
- Business Central keywords
- File extensions (.al)
- Dynamics 365 references

**Non-BC Indicators:**
- General questions (what, who, when, where)
- Weather, news, time queries
- Other non-BC topics

### 2. Relevance Scoring

Each skill is scored against the prompt:

- **Keywords**: +0.2 per match
- **Intent patterns**: +0.5 per match (regex)
- **Context indicators**: +0.3 per match
- Maximum score: 1.0

Skills are activated only if their score meets the minimum threshold (configurable per skill).

### 3. Completion Detection

Skills can be automatically deactivated when completion signals are detected:

**Examples:**
- `al-development-core`: "phase 6 complete", "implementation finished"
- `al-testing-specialist`: "all tests passing", "test coverage complete"
- `al-build-workflow`: "build successful", "deployment complete"

### 4. Idle Timeout

Skills that haven't been referenced recently are automatically suspended:

- Default timeout: 5 minutes (300000ms)
- Configurable per skill
- Can be reactivated when relevant again

### 5. Auto-Reactivation

Completed skills can be automatically reactivated if they become relevant again:

- Enabled by default for most skills
- Disabled for troubleshooting skills (manual reactivation preferred)

### 6. Dependency Resolution

Skills can declare dependencies on other skills. When a skill is activated, its dependencies are automatically activated:

**Dependency Graph Example:**
```
al-testing-specialist
  └─ al-development-core
    └─ al-symbols-navigator

al-build-workflow
  └─ al-development-core
    └─ al-symbols-navigator
```

**Features:**
- **Transitive dependencies**: If A depends on B, and B depends on C, activating A activates both B and C
- **Cycle detection**: Prevents infinite loops from circular dependencies
- **Metadata tracking**: Each dependency activation records which skill triggered it
- **Reverse lookup**: Find which skills depend on a given skill

**Benefits:**
- Ensures all required skills are available when needed
- Maintains consistency (e.g., testing always has access to development tools)
- Reduces manual configuration
- Prevents missing dependency errors

## Configuration

### Enable Lifecycle Management

In `hooks/config/skill-rules.json`:

```json
{
  "globalSettings": {
    "enableAutoActivation": true,
    "enableLifecycleManagement": true,
    "enableDependencyResolution": true
  }
}
```

### Configure Skill Dependencies

Define dependencies between skills:

```json
{
  "dependencies": {
    "al-development-core": ["al-symbols-navigator"],
    "al-testing-specialist": ["al-development-core"],
    "al-build-workflow": ["al-development-core"],
    "al-best-practices": []
  }
}
```

This means:
- When `al-development-core` activates → `al-symbols-navigator` activates
- When `al-testing-specialist` activates → `al-development-core` + `al-symbols-navigator` activate (transitive)
- When `al-build-workflow` activates → `al-development-core` + `al-symbols-navigator` activate (transitive)

### Configure Skill Lifecycle

Each skill in `skill-rules.json` can have a `lifecycle` object:

```json
{
  "al-development-core": {
    "lifecycle": {
      "activationCondition": "bc-context-detected",
      "minRelevanceScore": 0.2,
      "idleTimeout": 600000,
      "autoReactivate": true,
      "requiresExplicitCompletion": true
    }
  }
}
```

### Add Completion Signals

In `hooks/config/lifecycle-rules.json`:

```json
{
  "completionSignals": {
    "your-skill-name": [
      "work\\s+(complete|finished|done)",
      "all\\s+tasks\\s+completed"
    ]
  }
}
```

## Visual Feedback

The system provides enhanced status indicators:

```
🎯 Skills Status:
  🆕 al-development-core - Activated
  🔗 al-symbols-navigator - Dependency (required by al-development-core)
  🟢 al-testing-specialist (Phase 4) - Active
  🟡 al-best-practices - Reactivated
  ✅ Completed: al-build-workflow
```

Icons:
- 🆕 = Newly activated
- 🔗 = Activated as dependency of another skill
- 🟢 = Already active (continued use)
- 🟡 = Reactivated (was completed or suspended)
- ✅ = Completed (informational only)

## Benefits

1. **Reduced Context Bloat**: Only relevant skills loaded
2. **Better Performance**: Smaller prompts = faster processing
3. **Intelligent Activation**: Context-aware skill loading
4. **Dependency Management**: Auto-load required skills
5. **Completion Awareness**: Auto-deactivate when work done
6. **State Persistence**: Maintains conversation context
7. **Visual Clarity**: User sees skill lifecycle and dependency status
8. **Consistency**: Dependent skills always available when needed

## Testing

### Lifecycle Test Suite

Run the lifecycle test suite:

```bash
node hooks/test/lifecycle-test.js
```

This tests:
- BC query detection
- Skill activation
- Relevance scoring
- Completion detection
- Reactivation
- State persistence

### Dependency Test Suite

Run the dependency test suite:

```bash
node hooks/test/dependency-test.js
```

This tests:
- Dependency graph visualization
- Dependency resolution (direct and transitive)
- Auto-activation of dependencies
- Reverse lookup (dependents)
- Dependency metadata tracking
- Circular dependency detection

## Backwards Compatibility

The system maintains backwards compatibility:

- If `enableLifecycleManagement` is false, falls back to legacy behavior
- Legacy behavior: Always loads al-development-core as base skill
- Graceful error handling with fallback to legacy mode

## File Structure

```
hooks/
├── src/
│   ├── userPromptSubmit.js       # Main hook (enhanced)
│   └── lifecycleManager.js       # Lifecycle logic (new)
├── config/
│   ├── skill-rules.json          # Enhanced with lifecycle config
│   └── lifecycle-rules.json      # Completion signals (new)
├── state/
│   ├── conversation-state.json.template  # State template
│   └── conversation-state.json   # Runtime state (gitignored)
└── test/
    └── lifecycle-test.js         # Test suite (new)
```

## Rollout Phases

As per the design document:

1. ✅ **Phase 1**: State tracking and relevance scoring
2. ✅ **Phase 2**: Deactivation detection
3. ✅ **Phase 3**: Visual feedback
4. ✅ **Phase 4**: Idle timeout and auto-cleanup
5. 🔄 **Phase 5**: Test and refine thresholds (ongoing)

## Troubleshooting

### Skills not activating

- Check `enableLifecycleManagement` is true
- Verify relevance scores meet thresholds
- Check completion signals haven't deactivated the skill
- Verify dependencies are properly configured

### Dependencies not activating

- Check `enableDependencyResolution` is true
- Verify dependency is defined in `dependencies` object
- Check for circular dependency warnings in console
- Ensure dependent skill exists in `rules`

### Skills not deactivating

- Verify completion signals match your prompt text
- Check idle timeout is configured
- Ensure auto-reactivate isn't immediately reactivating

### State not persisting

- Check `hooks/state/` directory exists
- Verify write permissions
- Check console for errors

## Future Enhancements

- Phase tracking (detect which phase of workflow)
- Error-based activation triggers
- Multi-conversation state management
- Analytics on skill usage patterns
- Dynamic threshold adjustment based on usage
- Optional dependencies (nice-to-have vs required)
- Conditional dependencies (activate only in certain contexts)
- Dependency version constraints
- Skill conflict detection and resolution
