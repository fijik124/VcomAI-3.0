import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { fileURLToPath } from 'node:url';

export const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
export const project = JSON.parse(fs.readFileSync(path.join(root,'tools/addon-project.json'),'utf8'));
export const virtualRoot = id => `\\z\\${project.prefix}\\addons\\${id}`;
export const sqfLiteral = value => Array.isArray(value)
  ? `[${value.map(sqfLiteral).join(',')}]` : `"${value.replaceAll('"','""')}"`;

export function moduleLayout() {
  const source = path.join(root,'Vcom/Functions/VCM_Functions');
  const files = new Map(fs.readdirSync(source).filter(name => /^fn_.*\.sqf$/i.test(name))
    .map(name => [name.slice(3,-4).toLowerCase(),name]));
  const declarations = new Map([...fs.readFileSync(path.join(root,'Vcom/cfgFunctions.hpp'),'utf8')
    .matchAll(/class\s+(\w+)\s*\{([^{}]*)\};/g)]
    .filter(match => files.has(match[1].toLowerCase()))
    .map(match => [match[1].toLowerCase(),{name:match[1],body:match[2].trim()}]));
  const owners = new Map();
  const ids = new Set();
  for (const module of project.modules) {
    assert.match(module.id,/^[a-z]+$/);
    assert.ok(!ids.has(module.id),`Duplicate module ${module.id}`);
    ids.add(module.id);
    for (const name of module.functions) {
      const key = name.toLowerCase();
      assert.ok(files.has(key),`Missing function ${name}`);
      assert.ok(!owners.has(key),`Function ${name} belongs to multiple PBOs`);
      owners.set(key,module.id);
    }
  }
  for (const name of files.keys()) assert.ok(owners.has(name),`Assign ${name} to a PBO`);
  return {source,files,declarations,owners};
}

export function addonChecks() {
  const {declarations} = moduleLayout();
  return project.modules.map(module => [
    `${project.prefix}_${module.id}`,module.category,
    `${virtualRoot(module.id)}\\functions`,
    module.id === 'main' ? ['VCM_fnc_AddonStart'] : module.functions
      .filter(name => declarations.has(name.toLowerCase())).map(name => `VCM_fnc_${name}`)
  ]);
}

export function addonAssertions() {
  // This file runs inside the native test's scheduled scope with its real assertion function.
  return `{
    _x params ["_patch","_category","_directory","_functions"];
    [isClass (configFile >> "CfgPatches" >> _patch),format ["addon module %1 is loaded",_patch]] call _assert;
    [getText (configFile >> "CfgFunctions" >> "VCOM" >> _category >> "file") == _directory,
        format ["addon module %1 uses its own PBO directory",_patch]] call _assert;
    [_functions findIf {isNil _x} < 0,format ["addon module %1 compiles all public functions",_patch]] call _assert;
} forEach ${sqfLiteral(addonChecks())};
[getText (configFile >> "CfgFunctions" >> "VCOM" >> "FSM" >> "file") == "${virtualRoot('squad')}\\fsm",
    "squad FSM resolves from the squad PBO"] call _assert;
[missionNamespace getVariable ["VCM_Started",false],"main PBO starts the complete mod"] call _assert;
`;
}
