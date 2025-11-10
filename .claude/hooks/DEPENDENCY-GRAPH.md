# Skill Dependency Graph Documentation

## Overview

The Dependency Graph feature automatically activates required skills when parent skills are activated. This ensures consistency and prevents missing functionality.

## Current Dependency Graph

```
al-testing-specialist
  └─ al-development-core
    └─ al-symbols-navigator

al-build-workflow
  └─ al-development-core
    └─ al-symbols-navigator

al-development-core
  └─ al-symbols-navigator

al-best-practices
  (no dependencies)

bc-troubleshooter
  (no dependencies)

al-symbols-navigator
  (no dependencies - leaf node)
```

## Rationale

### Why al-development-core depends on al-symbols-navigator

When developing AL objects, you frequently need to:
- Look up base Business Central objects (tables, pages, etc.)
- Check field names and IDs in standard tables
- Verify object IDs before extending

**Example scenario:**
```
User: "Create a table extension for the Customer table"

Without dependency:
❌ al-development-core activates
❌ User must manually mention "symbols" to get al-symbols-navigator
❌ Claude may create extension without verifying base object

With dependency:
✅ al-development-core activates
✅ al-symbols-navigator auto-activates (dependency)
✅ Claude automatically verifies Customer table structure
✅ Extension is created with correct base object reference
```

### Why al-testing-specialist depends on al-development-core

Testing requires understanding the code being tested:
- Test codeunits are AL objects themselves
- Need development standards for test code
- Follow same conventions as production code

**Example scenario:**
```
User: "Write tests for the Product table"

Without dependency:
❌ al-testing-specialist activates
❌ Testing patterns loaded but no development context
❌ May miss development standards in test code

With dependency:
✅ al-testing-specialist activates
✅ al-development-core auto-activates (dependency)
✅ al-symbols-navigator auto-activates (transitive)
✅ Tests follow development standards
✅ Can verify base objects being tested
```

### Why al-build-workflow depends on al-development-core

Build scripts operate on AL code:
- Need to understand project structure
- Validate against development standards
- Reference app.json and project configuration

**Example scenario:**
```
User: "Run the build script"

Without dependency:
❌ al-build-workflow activates
❌ Build instructions loaded but no development context
❌ May not validate code structure correctly

With dependency:
✅ al-build-workflow activates
✅ al-development-core auto-activates (dependency)
✅ Build process validates against development standards
✅ Project structure is understood
```

## Transitive Dependencies

Dependencies are resolved recursively:

```
Activate: al-testing-specialist
  └─ Requires: al-development-core
       └─ Requires: al-symbols-navigator

Result: All 3 skills activated
```

## Dependency Metadata

Each dependency activation tracks which skill triggered it:

```json
{
  "al-symbols-navigator": {
    "activatedAt": "2025-11-06T13:12:54.121Z",
    "status": "active",
    "activatedByDependency": "al-development-core"
  }
}
```

## Visual Indicators

Dependency activations are shown with the 🔗 icon:

```
🎯 Skills Status:
  🆕 al-testing-specialist - Activated
  🔗 al-development-core - Dependency (required by al-testing-specialist)
  🔗 al-symbols-navigator - Dependency (required by al-development-core)
```

## Configuration

### Adding a New Dependency

In `hooks/config/skill-rules.json`:

```json
{
  "dependencies": {
    "parent-skill": ["required-skill-1", "required-skill-2"],
    "another-skill": ["its-dependency"]
  }
}
```

### Removing a Dependency

Simply remove the skill from the array or set to empty array:

```json
{
  "dependencies": {
    "al-development-core": []  // No dependencies
  }
}
```

### Disabling Dependency Resolution

In `globalSettings`:

```json
{
  "globalSettings": {
    "enableDependencyResolution": false
  }
}
```

## Benefits

1. **Automatic Consistency**: Required skills always available
2. **Reduced Errors**: No missing functionality when dependent work is needed
3. **Better UX**: User doesn't need to know internal dependencies
4. **Maintainability**: Dependencies documented in config, not scattered in code
5. **Transitive Support**: Deep dependency chains resolved automatically
6. **Cycle Prevention**: Circular dependencies detected and prevented

## Edge Cases

### Circular Dependencies

Detected and prevented:

```
al-skill-a depends on al-skill-b
al-skill-b depends on al-skill-a
→ Warning logged, cycle broken
```

### Missing Dependencies

If a dependency doesn't exist:

```
al-development-core depends on "non-existent-skill"
→ Warning logged, dependency skipped
→ al-development-core still activates
```

### Dependency of Completed Skill

If a dependency was previously completed:

```
al-symbols-navigator: completed
al-development-core: activating
→ al-symbols-navigator reactivated (removed from completed list)
```

## Testing

### Test Dependency Resolution

```bash
node hooks/test/dependency-test.js
```

Output shows:
- Full dependency graph
- Resolved dependencies for each skill
- Reverse lookup (dependents)
- Auto-activation behavior

### Test Transitive Dependencies

```javascript
manager.resolveDependencies('al-testing-specialist')
// Returns: ['al-symbols-navigator', 'al-development-core']
// Note: depth-first order - deepest dependencies first
```

## Best Practices

### When to Add a Dependency

✅ Add dependency if:
- Parent skill ALWAYS needs the dependent skill
- Dependent skill provides foundational functionality
- User shouldn't need to think about the dependency

❌ Don't add dependency if:
- Only needed in some scenarios (use relevance scoring instead)
- Creates circular dependency
- Dependent skill is optional/nice-to-have

### Dependency Order

Dependencies are activated in **depth-first order**:

```
Skill A depends on B, C
Skill B depends on D
Skill C depends on E

Activation order: D, B, E, C, A
(deepest first, then parents)
```

This ensures foundational skills load before higher-level skills.

## API Reference

### LifecycleManager Methods

#### `resolveDependencies(skillName, visited = new Set())`

Recursively resolves all dependencies for a skill.

**Parameters:**
- `skillName` (string): Skill to resolve dependencies for
- `visited` (Set): Internal cycle detection

**Returns:** Array of dependency names in depth-first order

**Example:**
```javascript
manager.resolveDependencies('al-testing-specialist')
// ['al-symbols-navigator', 'al-development-core']
```

#### `getDependents(skillName)`

Find all skills that depend on a given skill (reverse lookup).

**Parameters:**
- `skillName` (string): Skill to find dependents for

**Returns:** Array of skill names that depend on this skill

**Example:**
```javascript
manager.getDependents('al-development-core')
// ['al-testing-specialist', 'al-build-workflow']
```

#### `visualizeDependencyGraph()`

Generate ASCII art visualization of full dependency graph.

**Returns:** String with formatted graph

**Example:**
```javascript
console.log(manager.visualizeDependencyGraph())
```

## Future Enhancements

### Optional Dependencies

Dependencies that are nice-to-have but not required:

```json
{
  "dependencies": {
    "al-development-core": ["al-symbols-navigator"]
  },
  "optionalDependencies": {
    "al-development-core": ["al-best-practices"]
  }
}
```

### Conditional Dependencies

Dependencies that only activate in certain contexts:

```json
{
  "conditionalDependencies": {
    "al-development-core": [
      {
        "skill": "al-symbols-navigator",
        "when": "extending base objects"
      }
    ]
  }
}
```

### Dependency Versions

Specify version constraints:

```json
{
  "dependencies": {
    "al-development-core": ["al-symbols-navigator@^1.0.0"]
  }
}
```

### Conflict Resolution

Detect and resolve conflicting skills:

```json
{
  "conflicts": {
    "al-legacy-mode": ["al-development-core"]
  }
}
```

## Migration Guide

### Upgrading from Non-Dependency System

1. **Analyze current skill usage**
   ```bash
   grep -r "skill activation" logs/
   ```

2. **Identify common co-activations**
   - Which skills are frequently activated together?
   - Which skills provide foundational functionality?

3. **Add dependencies gradually**
   ```json
   // Start with obvious ones
   "dependencies": {
     "al-development-core": ["al-symbols-navigator"]
   }
   ```

4. **Test and monitor**
   ```bash
   node hooks/test/dependency-test.js
   ```

5. **Add remaining dependencies**
   ```json
   "dependencies": {
     "al-development-core": ["al-symbols-navigator"],
     "al-testing-specialist": ["al-development-core"],
     "al-build-workflow": ["al-development-core"]
   }
   ```

### Rolling Back

To disable dependency resolution temporarily:

```json
{
  "globalSettings": {
    "enableDependencyResolution": false
  }
}
```

The system will fall back to relevance-based activation only.
