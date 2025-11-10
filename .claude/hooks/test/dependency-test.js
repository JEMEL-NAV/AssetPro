// Test script for dependency graph functionality
const path = require('path');
const LifecycleManager = require('../src/lifecycleManager');

const skillRulesPath = path.join(__dirname, '..', 'config', 'skill-rules.json');
const lifecycleRulesPath = path.join(__dirname, '..', 'config', 'lifecycle-rules.json');
const statePath = path.join(__dirname, '..', 'state', 'conversation-state-dep-test.json');

// Initialize lifecycle manager
const manager = new LifecycleManager(skillRulesPath, lifecycleRulesPath, statePath);

console.log('=== Dependency Graph Test ===\n');

// Test 1: Visualize dependency graph
console.log('Test 1: Dependency Graph Visualization');
console.log(manager.visualizeDependencyGraph());
console.log('---\n');

// Test 2: Resolve dependencies for a skill
console.log('Test 2: Dependency Resolution');
console.log('al-development-core dependencies:', manager.resolveDependencies('al-development-core'));
console.log('al-testing-specialist dependencies:', manager.resolveDependencies('al-testing-specialist'));
console.log('al-build-workflow dependencies:', manager.resolveDependencies('al-build-workflow'));
console.log('---\n');

// Test 3: Get dependents
console.log('Test 3: Get Dependents (Reverse Lookup)');
console.log('Skills that depend on al-development-core:', manager.getDependents('al-development-core'));
console.log('Skills that depend on al-symbols-navigator:', manager.getDependents('al-symbols-navigator'));
console.log('---\n');

// Test 4: Activate skill and check if dependencies are activated
console.log('Test 4: Auto-Activation of Dependencies');
console.log('Prompt: "Create a new table for products"');
const result1 = manager.processPrompt('Create a new table for products');
console.log('Active skills:', Object.keys(manager.state.activeSkills));
console.log('Expected: al-development-core AND al-symbols-navigator (dependency)');
console.log('---\n');

// Test 5: Activate skill with transitive dependency
console.log('Test 5: Transitive Dependency Activation');
console.log('Prompt: "Write unit tests for the product table"');
const result2 = manager.processPrompt('Write unit tests for the product table');
console.log('Active skills:', Object.keys(manager.state.activeSkills));
console.log('Expected: al-testing-specialist -> al-development-core -> al-symbols-navigator');
console.log('---\n');

// Test 6: Check dependency metadata
console.log('Test 6: Dependency Metadata');
for (const [skillName, skillData] of Object.entries(manager.state.activeSkills)) {
  if (skillData.activatedByDependency) {
    console.log(`${skillName} was activated as a dependency of ${skillData.activatedByDependency}`);
  }
}
console.log('---\n');

// Test 7: Build workflow with dependency
console.log('Test 7: Build Workflow Activation');
console.log('Prompt: "Run the build script"');
const result3 = manager.processPrompt('Run the build script');
console.log('Active skills:', Object.keys(manager.state.activeSkills));
console.log('Expected: al-build-workflow -> al-development-core -> al-symbols-navigator');
console.log('---\n');

console.log('=== Test Complete ===');
console.log('Final state:');
console.log('Active skills:', Object.keys(manager.state.activeSkills));
console.log('\nDependency activation status:');
for (const [skillName, skillData] of Object.entries(manager.state.activeSkills)) {
  const depInfo = skillData.activatedByDependency ? ` (dep of ${skillData.activatedByDependency})` : '';
  console.log(`  - ${skillName}${depInfo}`);
}
