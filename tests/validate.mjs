import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import assert from 'node:assert/strict';
import { fileURLToPath } from 'node:url';
import { project, moduleLayout, addonAssertions } from '../tools/addon-project.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
moduleLayout();
const stage = path.join(root, 'build', 'validation');
// This script only ever removes its own generated staging directory.
assert.equal(path.dirname(stage), path.join(root, 'build'));
fs.rmSync(stage, { recursive: true, force: true });
fs.mkdirSync(path.join(stage, '.hemtt'), { recursive: true });
const addon = path.join(stage, 'addons', 'vcom');
fs.mkdirSync(addon, { recursive: true });
fs.cpSync(path.join(root, 'Vcom'), path.join(addon, 'Vcom'), {
  recursive: true,
  filter: source => path.basename(source) !== 'Playground.sqf', // Unregistered scratchpad, not mission code.
});
fs.copyFileSync(path.join(root, 'description.ext'), path.join(addon, 'mission.hpp'));
fs.copyFileSync(path.join(root, 'init.sqf'), path.join(addon, 'init.sqf'));
fs.copyFileSync(path.join(root, 'tests/regression.sqf'), path.join(addon, 'regression.sqf'));
fs.writeFileSync(path.join(addon,'addon-layout.sqf'),addonAssertions());
fs.copyFileSync(path.join(root, 'tests/fire-movement.sqf'), path.join(addon, 'fire-movement.sqf'));
fs.copyFileSync(path.join(root, 'tests/cover.sqf'), path.join(addon, 'cover.sqf'));
fs.copyFileSync(path.join(root, 'tests/safety.sqf'), path.join(addon, 'safety.sqf'));
fs.copyFileSync(path.join(root, 'tests/tactics.sqf'), path.join(addon, 'tactics.sqf'));
fs.copyFileSync(path.join(root, 'tests/vehicle.sqf'), path.join(addon, 'vehicle.sqf'));
fs.copyFileSync(path.join(root, 'tests/performance.sqf'), path.join(addon, 'performance.sqf'));
fs.copyFileSync(path.join(root, 'tests/advanced.sqf'), path.join(addon, 'advanced.sqf'));
fs.copyFileSync(path.join(root, 'tests/coordination.sqf'), path.join(addon, 'coordination.sqf'));
fs.copyFileSync(path.join(root, 'tests/evacuation.sqf'), path.join(addon, 'evacuation.sqf'));
fs.copyFileSync(path.join(root, 'tests/cqb.sqf'), path.join(addon, 'cqb.sqf'));
fs.copyFileSync(path.join(root, 'tests/cqb-control.sqf'), path.join(addon, 'cqb-control.sqf'));
fs.copyFileSync(path.join(root, 'tests/cqb-floors.sqf'), path.join(addon, 'cqb-floors.sqf'));
fs.cpSync(path.join(root, 'tests/multiplayer'), path.join(addon, 'mp'), { recursive: true });
fs.copyFileSync(path.join(root, 'userconfig/VCOM_AI/AISettingsV3.hpp'), path.join(addon, 'userconfig.sqf'));
const [versionMajor,versionMinor,versionPatch] = project.version.split('.');
fs.writeFileSync(path.join(stage, '.hemtt/project.toml'), `name = "${project.name} validation"\nprefix = "vcm"\nmainprefix = "z"\n[version]\nmajor = ${versionMajor}\nminor = ${versionMinor}\npatch = ${versionPatch}\ngit_hash = 0\n`);
fs.writeFileSync(path.join(addon, '$PBOPREFIX$'), 'z\\vcm\\addons\\vcom');
fs.writeFileSync(path.join(addon, 'config.cpp'), 'class CfgPatches { class VCM_validation { units[] = {}; weapons[] = {}; requiredVersion = 2.22; requiredAddons[] = {"A3_Functions_F"}; }; };\n#include "mission.hpp"\n');

// HEMTT's SQF compiler must also see code stored inside FSM config strings.
const fsm = fs.readFileSync(path.join(root, 'Vcom/FSMS/fn_SQUADBEH.fsm'), 'utf8');
const decode = body => [...body.matchAll(/"((?:""|[^"])*)"/g)].map(m => m[1].replaceAll('""', '"')).join('\n');
const clauses = [...fsm.matchAll(/\/\*%FSM<(STATEINIT|ACTION|CONDITION)""">\*\/([\s\S]*?)\/\*%FSM<\/\1""">\*\//g)];
assert.ok(clauses.length > 100, 'FSM code extraction must not silently skip the controller');
const snippets = path.join(addon, 'fsm_checks');
fs.mkdirSync(snippets);
clauses.forEach((m, i) => fs.writeFileSync(path.join(snippets, `clause_${i}.sqf`), decode(m[2]) + '\n'));
const states = [...fsm.matchAll(/\/\*%FSM<STATE "([^"]+)">\*\/([\s\S]*?)\/\*%FSM<\/STATE>\*\//g)];
assert.ok(states.length > 10);
for (const [, name, body] of states) {
  if (!name.startsWith('Exit_FSM')) assert.match(body, /class VCM_Cancel/, `${name} needs a cancellation transition`);
}
const declarations = fs.readFileSync(path.join(root, 'Vcom/cfgFunctions.hpp'), 'utf8');
const declared = new Set([...declarations.matchAll(/class\s+(\w+)\s*\{/g)].map(m => m[1].toLowerCase()));
for (const entry of fs.readdirSync(path.join(root, 'Vcom/Functions/VCM_Functions'))) {
  if (!entry.startsWith('fn_') || !entry.endsWith('.sqf')) continue;
  const name = entry.slice(3, -4).toLowerCase();
  if (name === 'transportvehicle') continue; // Existing unused helper is intentionally unregistered.
  assert.ok(declared.has(name), `${entry} missing CfgFunctions entry`);
}
console.log(`Structural checks passed: ${states.length} FSM states, ${clauses.length} extracted SQF clauses.`);
console.log('Running hemtt check --no-color');
const result = spawnSync('hemtt', ['check', '--no-color'], { cwd: stage, encoding: 'utf8' });
const output = (result.stdout || '') + (result.stderr || '');
fs.writeFileSync(path.join(root, 'build/validation.log'), output);
const lines = output.split(/\r?\n/);
console.log(lines.filter(line => /INFO|^ERROR/.test(line)).join('\n'));
const errors = [...output.matchAll(/^error\[[^\]]+\]:[^\n]*(?:\n(?!\n)[^\n]*)*/gm)];
for (const error of errors) console.error(error[0]);
console.log(`HEMTT: ${errors.length} errors, ${lines.filter(line => /^warning\[/.test(line)).length} warnings. Full log: build/validation.log`);
if (result.error?.code === 'ENOENT') {
  console.error('hemtt is not on PATH. Install HEMTT or refresh the shell PATH, then run this script again.');
  process.exit(2);
}
if (result.error) throw result.error;
process.exit(result.status ?? 1);
