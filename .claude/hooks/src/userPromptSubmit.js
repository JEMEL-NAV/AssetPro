#!/usr/bin/env node
// C:\GIT\JEMEL\AI_Develop\hooks\src\userPromptSubmit.js
// Claude Code hook for skill auto-activation with lifecycle management
const fs = require('fs');
const path = require('path');
const LifecycleManager = require('./lifecycleManager');

// Load skill rules configuration
let skillRules;
let SKILLS_PATH;
let lifecycleManager;
let USE_LIFECYCLE_MANAGEMENT = false;

try {
  const configPath = path.join(__dirname, '..', 'config', 'skill-rules.json');
  const configData = fs.readFileSync(configPath, 'utf8');
  skillRules = JSON.parse(configData);

  // Get skills path from configuration (absolute path to skills directory)
  // This eliminates the need for symlinks - just update skill-rules.json per project
  SKILLS_PATH = skillRules.globalSettings?.skillsPath || 'skills';

  // Check if lifecycle management is enabled
  USE_LIFECYCLE_MANAGEMENT = skillRules.globalSettings?.enableLifecycleManagement !== false;

  // Initialize lifecycle manager if enabled
  if (USE_LIFECYCLE_MANAGEMENT) {
    const lifecycleRulesPath = path.join(__dirname, '..', 'config', 'lifecycle-rules.json');
    const statePath = path.join(__dirname, '..', 'state', 'conversation-state.json');
    lifecycleManager = new LifecycleManager(configPath, lifecycleRulesPath, statePath);
  }
} catch (error) {
  console.error('Failed to load skill-rules.json:', error.message);
  skillRules = { rules: {}, globalSettings: { enableAutoActivation: false } };
  SKILLS_PATH = 'skills'; // Fallback to relative path
  USE_LIFECYCLE_MANAGEMENT = false;
}

/**
 * Main hook function - processes prompt and outputs modified version
 */
async function processPrompt(prompt) {
  // Skip if auto-activation is disabled
  if (!skillRules.globalSettings?.enableAutoActivation) {
    return prompt;
  }

  // Use lifecycle manager if enabled
  if (USE_LIFECYCLE_MANAGEMENT && lifecycleManager) {
    try {
      return lifecycleManager.processPrompt(prompt);
    } catch (error) {
      console.error('Lifecycle manager error:', error.message);
      // Fall back to legacy behavior on error
      return processPromptLegacy(prompt);
    }
  }

  // Legacy behavior (for backwards compatibility)
  return processPromptLegacy(prompt);
};

/**
 * Legacy prompt processing (original behavior)
 */
function processPromptLegacy(prompt) {
  const activatedSkills = [];
  const promptLower = prompt.toLowerCase();

  // ALWAYS load al-development-core as base skill for BC development
  const coreSkill = skillRules.rules['al-development-core'];
  if (coreSkill) {
    activatedSkills.push({
      name: 'al-development-core',
      priority: coreSkill.priority,
      reminder: coreSkill.reminder
    });
  }

  // Check each skill rule (skip al-development-core since already added)
  for (const [skillName, config] of Object.entries(skillRules.rules)) {
    if (skillName !== 'al-development-core' && shouldActivateSkill(promptLower, config)) {
      activatedSkills.push({
        name: skillName,
        priority: config.priority,
        reminder: config.reminder
      });
    }
  }

  // If skills detected, prepend activation message
  if (activatedSkills.length > 0) {
    // Sort by priority
    const priorityOrder = { critical: 0, high: 1, medium: 2, low: 3 };
    activatedSkills.sort((a, b) =>
      (priorityOrder[a.priority] || 99) - (priorityOrder[b.priority] || 99)
    );

    // Build skill list for invocation
    const skillList = activatedSkills.map(s => s.name).join(', ');

    // Build activation message with explicit instruction
    const skillMessages = activatedSkills
      .map(skill => `  ${skill.reminder}`)
      .join('\n');

    return `🚨 CRITICAL INSTRUCTION: Skill Compliance Required

You MUST read the complete skill documentation before proceeding:

${activatedSkills.map(s => `- ${SKILLS_PATH}/${s.name}/SKILL.md (and all resource files it references)`).join('\n')}

${skillMessages}

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

  return prompt;
}

/**
 * Determines if a skill should be activated based on prompt content
 * @param {string} promptLower - Lowercase prompt text
 * @param {object} config - Skill configuration
 * @returns {boolean}
 */
function shouldActivateSkill(promptLower, config) {
  const triggers = config.promptTriggers;
  if (!triggers) return false;

  // Check keywords
  if (triggers.keywords) {
    const hasKeyword = triggers.keywords.some(keyword =>
      promptLower.includes(keyword.toLowerCase())
    );
    if (hasKeyword) return true;
  }

  // Check intent patterns (regex)
  if (triggers.intentPatterns) {
    const hasPattern = triggers.intentPatterns.some(pattern => {
      try {
        const regex = new RegExp(pattern, 'i');
        return regex.test(promptLower);
      } catch (e) {
        console.error(`Invalid regex pattern: ${pattern}`);
        return false;
      }
    });
    if (hasPattern) return true;
  }

  // Check context indicators
  if (triggers.contextIndicators) {
    const hasContext = triggers.contextIndicators.some(indicator =>
      promptLower.includes(indicator.toLowerCase())
    );
    if (hasContext) return true;
  }

  return false;
}

// Main execution: Read from stdin, process, write to stdout
if (require.main === module) {
  let inputData = '';

  process.stdin.on('data', (chunk) => {
    inputData += chunk;
  });

  process.stdin.on('end', async () => {
    try {
      // Parse JSON input from Claude Code
      const hookData = JSON.parse(inputData);
      const originalPrompt = hookData.prompt || inputData;

      // Process the prompt
      const modifiedPrompt = await processPrompt(originalPrompt.trim());

      // Output modified prompt
      process.stdout.write(modifiedPrompt);
      process.exit(0);
    } catch (error) {
      console.error('Hook error:', error.message);
      // On error, try to extract prompt or pass through original
      try {
        const hookData = JSON.parse(inputData);
        process.stdout.write(hookData.prompt || inputData);
      } catch {
        process.stdout.write(inputData);
      }
      process.exit(0);
    }
  });
}