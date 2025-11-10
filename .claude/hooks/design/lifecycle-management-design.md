# Skill Lifecycle Management Design

## Current Problems

1. **Always-On Core Skill**: `al-development-core` loads for every prompt, even non-BC queries
2. **No Deactivation**: Skills stay active until conversation ends (context window limit)
3. **No State Tracking**: Each prompt is independent, no memory of previous activations
4. **Context Bloat**: Multiple skills loading increases prompt size unnecessarily
5. **No Completion Detection**: Can't detect when Phase 6 (Summary) is complete

## Proposed Architecture

### 1. Conversation State Tracking

**File**: `hooks/state/conversation-state.json`
```json
{
  "conversationId": "auto-generated-uuid",
  "activeSkills": {
    "al-development-core": {
      "activatedAt": "2025-11-06T14:30:00Z",
      "lastUsedAt": "2025-11-06T14:32:00Z",
      "phase": "implementation",
      "usageCount": 3,
      "status": "active"
    }
  },
  "completedSkills": ["al-symbols-navigator"],
  "conversationContext": "bc-development",
  "lastPromptAt": "2025-11-06T14:32:00Z"
}
```

### 2. Lifecycle States

**Skill States:**
- `inactive` - Not loaded, not in context
- `active` - Currently loaded and in use
- `idle` - Loaded but not recently referenced (candidate for deactivation)
- `completed` - Work finished, can be deactivated
- `suspended` - Temporarily deactivated, can quick-reactivate

### 3. Activation Rules Enhancement

Add to `skill-rules.json`:

```json
{
  "al-development-core": {
    "lifecycle": {
      "activationCondition": "bc-context-detected",
      "deactivationSignals": [
        "phase 6 complete",
        "summary provided",
        "implementation finished",
        "all tasks completed"
      ],
      "idleTimeout": 300000,  // 5 minutes
      "autoReactivate": true,
      "minRelevanceScore": 0.3
    }
  }
}
```

### 4. Relevance Scoring System

**Score Calculation:**
```javascript
function calculateRelevanceScore(prompt, skillConfig) {
  let score = 0;

  // Keyword matches: +0.2 per match
  if (skillConfig.promptTriggers.keywords) {
    const matches = skillConfig.promptTriggers.keywords.filter(kw =>
      prompt.toLowerCase().includes(kw.toLowerCase())
    );
    score += matches.length * 0.2;
  }

  // Intent pattern matches: +0.5 per match
  if (skillConfig.promptTriggers.intentPatterns) {
    const matches = skillConfig.promptTriggers.intentPatterns.filter(pattern =>
      new RegExp(pattern, 'i').test(prompt)
    );
    score += matches.length * 0.5;
  }

  // Context indicators: +0.3 per match
  if (skillConfig.promptTriggers.contextIndicators) {
    const matches = skillConfig.promptTriggers.contextIndicators.filter(indicator =>
      prompt.toLowerCase().includes(indicator.toLowerCase())
    );
    score += matches.length * 0.3;
  }

  // Cap at 1.0
  return Math.min(score, 1.0);
}
```

### 5. Deactivation Detection

**Completion Signals:**
```javascript
const completionSignals = {
  'al-development-core': [
    /phase\s+6\s+(complete|done|finished)/i,
    /implementation\s+(complete|finished|done)/i,
    /summary\s+provided/i,
    /all\s+tasks\s+completed/i
  ],
  'al-testing-specialist': [
    /all\s+tests\s+(passing|passed)/i,
    /test\s+coverage\s+complete/i,
    /testing\s+(complete|finished|done)/i
  ],
  'al-build-workflow': [
    /build\s+(successful|succeeded|complete)/i,
    /deployment\s+complete/i,
    /published\s+successfully/i
  ]
};

function detectCompletion(prompt, skillName) {
  const signals = completionSignals[skillName];
  if (!signals) return false;

  return signals.some(pattern => pattern.test(prompt));
}
```

### 6. Context Detection

**BC Context Indicators:**
```javascript
function isBCContextQuery(prompt) {
  const bcIndicators = [
    /\b(table|page|codeunit|enum|report|query)\b/i,
    /\bal\b.*\b(code|development|extension)\b/i,
    /business central/i,
    /\bbc\b.*\b(app|extension|project)\b/i,
    /dynamics\s*365/i,
    /\.al\b/i
  ];

  return bcIndicators.some(pattern => pattern.test(prompt));
}

function isNonBCQuery(prompt) {
  const nonBCIndicators = [
    /^(what|who|when|where|why|how)\s+(is|are|was|were|does|do|did)/i,
    /weather/i,
    /news/i,
    /time.*in/i,
    /general.*question/i
  ];

  return nonBCIndicators.some(pattern => pattern.test(prompt));
}
```

### 7. State Management Flow

```
┌─────────────────────────────────────────────────────────┐
│  1. userPromptSubmit Hook Triggered                     │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  2. Load Conversation State (conversation-state.json)   │
│     - Read active skills                                │
│     - Read conversation context                         │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  3. Context Analysis                                     │
│     - Is this BC-related query?                         │
│     - If NO → Skip BC skills, return prompt             │
│     - If YES → Continue                                 │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  4. Check Active Skills for Deactivation                │
│     - Scan prompt for completion signals                │
│     - Check idle timeout                                │
│     - Mark skills as completed/suspended                │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  5. Calculate Relevance Scores                          │
│     - Score each skill against prompt                   │
│     - Filter by minRelevanceScore threshold             │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  6. Activate/Reactivate Skills                          │
│     - Activate new skills above threshold               │
│     - Reactivate suspended skills if relevant           │
│     - Update state: lastUsedAt, usageCount              │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  7. Build Enhanced Activation Message                   │
│     - Include lifecycle status indicators               │
│     - Show: 🟢 Active, 🟡 Reactivated, 🆕 New          │
│     - List completed skills (informational)             │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  8. Save Updated State (conversation-state.json)        │
│     - Persist active skills                             │
│     - Update timestamps                                 │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  9. Return Enhanced Prompt                              │
└─────────────────────────────────────────────────────────┘
```

## Implementation Files

### New Files:
1. `hooks/src/lifecycleManager.js` - Core lifecycle logic
2. `hooks/state/conversation-state.json` - Runtime state (gitignore)
3. `hooks/config/lifecycle-rules.json` - Deactivation rules

### Modified Files:
1. `hooks/src/userPromptSubmit.js` - Integrate lifecycle manager
2. `hooks/config/skill-rules.json` - Add lifecycle config

## Benefits

1. **Reduced Context Bloat**: Only active, relevant skills loaded
2. **Better Performance**: Smaller prompts = faster processing
3. **Intelligent Activation**: Context-aware skill loading
4. **Completion Awareness**: Auto-deactivate when work done
5. **Visual Feedback**: User sees skill lifecycle status
6. **State Persistence**: Maintains conversation context

## Example Output

**Before (Current):**
```
🚨 CRITICAL INSTRUCTION: Skill Compliance Required
Active skills: al-development-core, al-best-practices, al-testing-specialist
[Long activation message for all 3 skills]
```

**After (With Lifecycle):**
```
🎯 Skills Active:
  🟢 al-development-core (Phase 4 - Implementation)
  🆕 al-testing-specialist (Activated - test writing detected)
  ✅ al-symbols-navigator (Completed - base object lookup done)

Active skills: al-development-core, al-testing-specialist
[Activation message for only 2 active skills]
```

## Rollout Plan

1. **Phase 1**: Implement state tracking and relevance scoring
2. **Phase 2**: Add deactivation detection
3. **Phase 3**: Enhance visual feedback
4. **Phase 4**: Add idle timeout and auto-cleanup
5. **Phase 5**: Test and refine thresholds
