// C:\GIT\JEMEL\AI_Develop\hooks\src\lifecycleManager.js
// Skill Lifecycle Management System

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

class LifecycleManager {
  constructor(skillRulesPath, lifecycleRulesPath, statePath) {
    this.skillRulesPath = skillRulesPath;
    this.lifecycleRulesPath = lifecycleRulesPath;
    this.statePath = statePath;

    this.skillRules = this.loadJSON(skillRulesPath);
    this.lifecycleRules = this.loadJSON(lifecycleRulesPath, { completionSignals: {} });
    this.state = this.loadState();
    this.dependencies = this.skillRules.dependencies || {};
    this.enableDependencyResolution = this.skillRules.globalSettings?.enableDependencyResolution !== false;
  }

  /**
   * Load JSON file with error handling
   */
  loadJSON(filePath, defaultValue = {}) {
    try {
      if (!fs.existsSync(filePath)) {
        return defaultValue;
      }
      const data = fs.readFileSync(filePath, 'utf8');
      return JSON.parse(data);
    } catch (error) {
      console.error(`Failed to load ${filePath}:`, error.message);
      return defaultValue;
    }
  }

  /**
   * Load or initialize conversation state
   */
  loadState() {
    const defaultState = {
      conversationId: this.generateConversationId(),
      activeSkills: {},
      completedSkills: [],
      conversationContext: null,
      lastPromptAt: null
    };

    if (!fs.existsSync(this.statePath)) {
      return defaultState;
    }

    try {
      const data = fs.readFileSync(this.statePath, 'utf8');
      return JSON.parse(data);
    } catch (error) {
      console.error('Failed to load state:', error.message);
      return defaultState;
    }
  }

  /**
   * Save conversation state to disk
   */
  saveState() {
    try {
      const stateDir = path.dirname(this.statePath);
      if (!fs.existsSync(stateDir)) {
        fs.mkdirSync(stateDir, { recursive: true });
      }
      fs.writeFileSync(this.statePath, JSON.stringify(this.state, null, 2), 'utf8');
    } catch (error) {
      console.error('Failed to save state:', error.message);
    }
  }

  /**
   * Generate unique conversation ID
   */
  generateConversationId() {
    return `conv-${Date.now()}-${crypto.randomBytes(4).toString('hex')}`;
  }

  /**
   * Detect if prompt is BC-related
   */
  isBCContextQuery(prompt) {
    const bcIndicators = [
      /\b(table|page|codeunit|enum|report|query)\b/i,
      /\bal\b.*\b(code|development|extension)\b/i,
      /business central/i,
      /\bbc\b.*\b(app|extension|project)\b/i,
      /dynamics\s*365/i,
      /\.al\b/i,
      /tableextension|pageextension|enumextension/i
    ];

    return bcIndicators.some(pattern => pattern.test(prompt));
  }

  /**
   * Detect if prompt is a non-BC general query
   */
  isNonBCQuery(prompt) {
    const nonBCIndicators = [
      /^(what|who|when|where|why|how)\s+(is|are|was|were|does|do|did)/i,
      /weather/i,
      /news/i,
      /time.*in/i,
      /general.*question/i
    ];

    return nonBCIndicators.some(pattern => pattern.test(prompt));
  }

  /**
   * Calculate relevance score for a skill against prompt
   */
  calculateRelevanceScore(prompt, skillName) {
    const skillConfig = this.skillRules.rules?.[skillName];
    if (!skillConfig || !skillConfig.promptTriggers) {
      return 0;
    }

    let score = 0;
    const promptLower = prompt.toLowerCase();
    const triggers = skillConfig.promptTriggers;

    // Keyword matches: +0.2 per match
    if (triggers.keywords) {
      const matches = triggers.keywords.filter(kw =>
        promptLower.includes(kw.toLowerCase())
      );
      score += matches.length * 0.2;
    }

    // Intent pattern matches: +0.5 per match
    if (triggers.intentPatterns) {
      const matches = triggers.intentPatterns.filter(pattern => {
        try {
          return new RegExp(pattern, 'i').test(prompt);
        } catch (e) {
          return false;
        }
      });
      score += matches.length * 0.5;
    }

    // Context indicators: +0.3 per match
    if (triggers.contextIndicators) {
      const matches = triggers.contextIndicators.filter(indicator =>
        promptLower.includes(indicator.toLowerCase())
      );
      score += matches.length * 0.3;
    }

    // Cap at 1.0
    return Math.min(score, 1.0);
  }

  /**
   * Detect if skill work is complete based on prompt
   */
  detectCompletion(prompt, skillName) {
    const signals = this.lifecycleRules.completionSignals?.[skillName];
    if (!signals || signals.length === 0) {
      return false;
    }

    return signals.some(patternStr => {
      try {
        const pattern = new RegExp(patternStr, 'i');
        return pattern.test(prompt);
      } catch (e) {
        return false;
      }
    });
  }

  /**
   * Check if skill has been idle too long
   */
  isSkillIdle(skillName) {
    const skillState = this.state.activeSkills[skillName];
    if (!skillState) return false;

    const skillConfig = this.skillRules.rules?.[skillName];
    const lifecycle = skillConfig?.lifecycle;

    if (!lifecycle || !lifecycle.idleTimeout) {
      return false;
    }

    const lastUsed = new Date(skillState.lastUsedAt);
    const now = new Date();
    const elapsed = now - lastUsed;

    return elapsed > lifecycle.idleTimeout;
  }

  /**
   * Get minimum relevance threshold for a skill
   */
  getMinRelevanceScore(skillName) {
    const skillConfig = this.skillRules.rules?.[skillName];
    return skillConfig?.lifecycle?.minRelevanceScore || 0.3;
  }

  /**
   * Check if skill should auto-reactivate
   */
  canAutoReactivate(skillName) {
    const skillConfig = this.skillRules.rules?.[skillName];
    return skillConfig?.lifecycle?.autoReactivate !== false;
  }

  /**
   * Resolve dependencies for a skill recursively
   * @param {string} skillName - The skill to resolve dependencies for
   * @param {Set} visited - Set of already visited skills (for cycle detection)
   * @returns {Array} - List of all dependencies (depth-first order)
   */
  resolveDependencies(skillName, visited = new Set()) {
    // Prevent circular dependencies
    if (visited.has(skillName)) {
      console.warn(`Circular dependency detected for skill: ${skillName}`);
      return [];
    }

    visited.add(skillName);
    const deps = [];
    const directDeps = this.dependencies[skillName] || [];

    // Recursively resolve dependencies
    for (const depName of directDeps) {
      // Check if dependency exists in skill rules
      if (!this.skillRules.rules?.[depName]) {
        console.warn(`Dependency skill not found: ${depName} (required by ${skillName})`);
        continue;
      }

      // Add transitive dependencies first (depth-first)
      const transitiveDeps = this.resolveDependencies(depName, new Set(visited));
      for (const transDep of transitiveDeps) {
        if (!deps.includes(transDep)) {
          deps.push(transDep);
        }
      }

      // Add direct dependency
      if (!deps.includes(depName)) {
        deps.push(depName);
      }
    }

    return deps;
  }

  /**
   * Get all skills that depend on a given skill
   * @param {string} skillName - The skill to check
   * @returns {Array} - List of skills that depend on this skill
   */
  getDependents(skillName) {
    const dependents = [];
    for (const [skill, deps] of Object.entries(this.dependencies)) {
      if (deps.includes(skillName)) {
        dependents.push(skill);
      }
    }
    return dependents;
  }

  /**
   * Visualize dependency graph
   * @returns {string} - ASCII art representation of dependencies
   */
  visualizeDependencyGraph() {
    const lines = [];
    lines.push('Skill Dependency Graph:');
    lines.push('');

    const visited = new Set();

    const renderSkill = (skillName, indent = 0, prefix = '') => {
      if (visited.has(skillName)) {
        lines.push(`${'  '.repeat(indent)}${prefix}${skillName} (circular reference)`);
        return;
      }

      visited.add(skillName);
      lines.push(`${'  '.repeat(indent)}${prefix}${skillName}`);

      const deps = this.dependencies[skillName] || [];
      deps.forEach((dep, index) => {
        const isLast = index === deps.length - 1;
        const newPrefix = isLast ? '└─ ' : '├─ ';
        renderSkill(dep, indent + 1, newPrefix);
      });
    };

    // Render all root skills (skills with no dependents or that are entry points)
    const rootSkills = Object.keys(this.skillRules.rules || {}).filter(skill => {
      const dependents = this.getDependents(skill);
      return dependents.length === 0 || !this.dependencies[skill] || this.dependencies[skill].length === 0;
    });

    rootSkills.forEach(skill => {
      visited.clear();
      renderSkill(skill);
      lines.push('');
    });

    return lines.join('\n');
  }

  /**
   * Update active skills based on prompt analysis
   */
  updateActiveSkills(prompt) {
    const now = new Date().toISOString();
    this.state.lastPromptAt = now;

    // Step 1: Check for deactivation signals
    const skillsToDeactivate = [];
    for (const skillName of Object.keys(this.state.activeSkills)) {
      // Check completion signals
      if (this.detectCompletion(prompt, skillName)) {
        skillsToDeactivate.push(skillName);
        this.state.completedSkills.push(skillName);
        continue;
      }

      // Check idle timeout
      if (this.isSkillIdle(skillName)) {
        skillsToDeactivate.push(skillName);
        // Don't add to completed, mark as suspended
        this.state.activeSkills[skillName].status = 'suspended';
      }
    }

    // Remove deactivated skills
    for (const skillName of skillsToDeactivate) {
      delete this.state.activeSkills[skillName];
    }

    // Step 2: Calculate relevance scores for all skills
    const skillScores = {};
    for (const skillName of Object.keys(this.skillRules.rules || {})) {
      skillScores[skillName] = this.calculateRelevanceScore(prompt, skillName);
    }

    // Step 3: Activate/reactivate skills above threshold
    const activationResults = [];
    for (const [skillName, score] of Object.entries(skillScores)) {
      const minScore = this.getMinRelevanceScore(skillName);

      if (score >= minScore) {
        const wasActive = !!this.state.activeSkills[skillName];
        const wasCompleted = this.state.completedSkills.includes(skillName);

        // Skip if completed and can't auto-reactivate
        if (wasCompleted && !this.canAutoReactivate(skillName)) {
          continue;
        }

        // Activate or update
        if (!wasActive) {
          this.state.activeSkills[skillName] = {
            activatedAt: now,
            lastUsedAt: now,
            phase: null,
            usageCount: 1,
            status: 'active',
            relevanceScore: score
          };

          activationResults.push({
            name: skillName,
            status: wasCompleted ? 'reactivated' : 'new',
            score: score
          });

          // Remove from completed if reactivating
          if (wasCompleted) {
            this.state.completedSkills = this.state.completedSkills.filter(s => s !== skillName);
          }

          // Activate dependencies if enabled
          if (this.enableDependencyResolution) {
            const dependencies = this.resolveDependencies(skillName);
            for (const depName of dependencies) {
              if (!this.state.activeSkills[depName]) {
                this.state.activeSkills[depName] = {
                  activatedAt: now,
                  lastUsedAt: now,
                  phase: null,
                  usageCount: 1,
                  status: 'active',
                  relevanceScore: 0,
                  activatedByDependency: skillName
                };

                activationResults.push({
                  name: depName,
                  status: 'dependency',
                  score: 0,
                  requiredBy: skillName
                });

                // Remove from completed if reactivating via dependency
                if (this.state.completedSkills.includes(depName)) {
                  this.state.completedSkills = this.state.completedSkills.filter(s => s !== depName);
                }
              }
            }
          }
        } else {
          // Update existing
          this.state.activeSkills[skillName].lastUsedAt = now;
          this.state.activeSkills[skillName].usageCount++;
          this.state.activeSkills[skillName].relevanceScore = score;
          this.state.activeSkills[skillName].status = 'active';
        }
      }
    }

    return {
      activated: activationResults,
      deactivated: skillsToDeactivate
    };
  }

  /**
   * Process prompt and return enhanced version with skill activations
   */
  processPrompt(prompt) {
    // Check if this is a BC-related query
    const isBCQuery = this.isBCContextQuery(prompt);
    const isNonBC = this.isNonBCQuery(prompt);

    // Update conversation context
    if (isBCQuery) {
      this.state.conversationContext = 'bc-development';
    } else if (isNonBC) {
      this.state.conversationContext = 'general';
    }

    // If not BC-related and no active BC skills, skip activation
    if (!isBCQuery && Object.keys(this.state.activeSkills).length === 0) {
      return prompt;
    }

    // Update active skills
    const changes = this.updateActiveSkills(prompt);

    // Save state
    this.saveState();

    // Build activation message if there are active skills
    const activeSkillNames = Object.keys(this.state.activeSkills);
    if (activeSkillNames.length === 0) {
      return prompt;
    }

    return this.buildActivationMessage(prompt, changes);
  }

  /**
   * Build enhanced activation message with lifecycle status
   */
  buildActivationMessage(prompt, changes) {
    const skillsPath = this.skillRules.globalSettings?.skillsPath || 'skills';
    const activeSkills = Object.keys(this.state.activeSkills);

    // Sort by priority
    const priorityOrder = { critical: 0, high: 1, medium: 2, low: 3 };
    const sortedSkills = activeSkills.sort((a, b) => {
      const priorityA = this.skillRules.rules?.[a]?.priority || 'medium';
      const priorityB = this.skillRules.rules?.[b]?.priority || 'medium';
      return (priorityOrder[priorityA] || 99) - (priorityOrder[priorityB] || 99);
    });

    // Build status indicators
    const statusLines = [];
    for (const skillName of sortedSkills) {
      const skillState = this.state.activeSkills[skillName];
      const isNew = changes.activated.some(a => a.name === skillName && a.status === 'new');
      const isReactivated = changes.activated.some(a => a.name === skillName && a.status === 'reactivated');
      const isDependency = changes.activated.some(a => a.name === skillName && a.status === 'dependency');

      let icon = '🟢';
      let statusText = 'Active';

      if (isNew) {
        icon = '🆕';
        statusText = 'Activated';
      } else if (isReactivated) {
        icon = '🟡';
        statusText = 'Reactivated';
      } else if (isDependency) {
        icon = '🔗';
        const requiredBy = changes.activated.find(a => a.name === skillName && a.status === 'dependency')?.requiredBy;
        statusText = `Dependency (required by ${requiredBy})`;
      }

      const phase = skillState.phase ? ` (${skillState.phase})` : '';
      statusLines.push(`  ${icon} ${skillName}${phase} - ${statusText}`);
    }

    // Show completed skills (informational)
    if (this.state.completedSkills.length > 0) {
      statusLines.push('');
      statusLines.push('  ✅ Completed: ' + this.state.completedSkills.join(', '));
    }

    // Build skill reminders
    const skillMessages = sortedSkills
      .map(skillName => {
        const config = this.skillRules.rules?.[skillName];
        return config?.reminder ? `  ${config.reminder}` : null;
      })
      .filter(Boolean)
      .join('\n');

    const skillList = sortedSkills.join(', ');

    return `🚨 CRITICAL INSTRUCTION: Skill Compliance Required

You MUST read the complete skill documentation before proceeding:

${sortedSkills.map(s => `- ${skillsPath}/${s}/SKILL.md (and all resource files it references)`).join('\n')}

${skillMessages}

🎯 Skills Status:
${statusLines.join('\n')}

WHAT THIS MEANS:
✓ Read EVERY section of each SKILL.md file, not just summaries
✓ Read ALL resource/*.md files referenced in SKILL.md
✓ Follow EVERY rule, workflow phase, and requirement documented
✓ Apply ALL standards (IDs, properties, naming, workflow phases)
✓ Do NOT skip steps or improvise alternatives

If you proceed without reading the complete skills, you WILL:
- Use wrong workflow or skip critical phases
- Miss mandatory rules and requirements
- Create non-compliant code
- Waste user's time with incorrect implementation

Confirm your understanding by following the documented workflow exactly as written.

Active skills: ${skillList}

USER REQUEST:
${prompt}`;
  }
}

module.exports = LifecycleManager;
