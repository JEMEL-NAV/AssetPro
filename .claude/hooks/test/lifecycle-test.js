// Test script for lifecycle management
const path = require('path');
const LifecycleManager = require('../src/lifecycleManager');

const skillRulesPath = path.join(__dirname, '..', 'config', 'skill-rules.json');
const lifecycleRulesPath = path.join(__dirname, '..', 'config', 'lifecycle-rules.json');
const statePath = path.join(__dirname, '..', 'state', 'conversation-state-test.json');

// Initialize lifecycle manager
const manager = new LifecycleManager(skillRulesPath, lifecycleRulesPath, statePath);

console.log('=== Lifecycle Management Test ===\n');

// Test 1: BC Development Query
console.log('Test 1: BC Development Query');
console.log('Prompt: "Create a new table for customer preferences"');
const result1 = manager.processPrompt('Create a new table for customer preferences');
console.log('Active skills:', Object.keys(manager.state.activeSkills));
console.log('Context:', manager.state.conversationContext);
console.log('---\n');

// Test 2: Testing Query
console.log('Test 2: Testing Query');
console.log('Prompt: "Write unit tests for the customer table"');
const result2 = manager.processPrompt('Write unit tests for the customer table');
console.log('Active skills:', Object.keys(manager.state.activeSkills));
console.log('---\n');

// Test 3: Non-BC Query (should not activate BC skills if none active)
console.log('Test 3: Non-BC Query');
console.log('Prompt: "What is the weather today?"');
const result3 = manager.processPrompt('What is the weather today?');
console.log('Active skills:', Object.keys(manager.state.activeSkills));
console.log('Should still have active BC skills from previous prompts');
console.log('---\n');

// Test 4: Completion Signal
console.log('Test 4: Completion Signal');
console.log('Prompt: "Phase 6 complete, all tasks completed"');
const result4 = manager.processPrompt('Phase 6 complete, all tasks completed');
console.log('Active skills:', Object.keys(manager.state.activeSkills));
console.log('Completed skills:', manager.state.completedSkills);
console.log('Should have deactivated al-development-core');
console.log('---\n');

// Test 5: Reactivation
console.log('Test 5: Reactivation');
console.log('Prompt: "Now create a page for the customer table"');
const result5 = manager.processPrompt('Now create a page for the customer table');
console.log('Active skills:', Object.keys(manager.state.activeSkills));
console.log('Should have reactivated al-development-core');
console.log('---\n');

// Test 6: Relevance Scoring
console.log('Test 6: Relevance Score Calculation');
const scores = {
  'al-development-core': manager.calculateRelevanceScore('Create a table', 'al-development-core'),
  'al-testing-specialist': manager.calculateRelevanceScore('Create a table', 'al-testing-specialist'),
  'bc-troubleshooter': manager.calculateRelevanceScore('Create a table', 'bc-troubleshooter')
};
console.log('Scores for "Create a table":', scores);
console.log('---\n');

console.log('=== Test Complete ===');
console.log('Final state:', JSON.stringify(manager.state, null, 2));
