import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { root, project, virtualRoot, moduleLayout } from './addon-project.mjs';

const stage = path.join(root,'build/addon');
const upload = path.join(root,'build/upload');
const {source,files,declarations} = moduleLayout();
// Remove only this script's generated build tree, never a source or game-install directory.
assert.equal(path.dirname(stage),path.join(root,'build'));
fs.rmSync(stage,{recursive:true,force:true});
fs.mkdirSync(path.join(stage,'.hemtt'),{recursive:true});
const resources = new Map([
  ['Vcom\\Functions\\VcomAI_DefaultSettings.sqf',`${virtualRoot('core')}\\settings\\VcomAI_DefaultSettings.sqf`],
  ['Vcom\\FSMS\\fn_SQUADBEH.fsm',`${virtualRoot('squad')}\\fsm\\fn_SQUADBEH.fsm`],
]);
function copyCode(from,to) {
  let text = fs.readFileSync(from,'utf8');
  for (const [legacy,destination] of resources) text = text.replaceAll(legacy,destination);
  assert.ok(!/\bVcom\\/i.test(text),`Unmapped mission-relative resource in ${from}`);
  fs.mkdirSync(path.dirname(to),{recursive:true});
  fs.writeFileSync(to,text);
}
const remoteFunctions = fs.readFileSync(path.join(root,'description.ext'),'utf8')
  .match(/class VCM_fnc_\w+\s*\{[^}]*\};/g);
assert.equal(remoteFunctions?.length,13,'Product RPC whitelist must be included');
for (const module of project.modules) {
  const addon = path.join(stage,'addons',module.id);
  fs.mkdirSync(addon,{recursive:true});
  fs.writeFileSync(path.join(addon,'$PBOPREFIX$'),`z\\${project.prefix}\\addons\\${module.id}`);
  const registered = [];
  for (const name of module.functions) {
    const key = name.toLowerCase();
    copyCode(path.join(source,files.get(key)),path.join(addon,'functions',files.get(key)));
    if (declarations.has(key)) {
      const declaration = declarations.get(key);
      registered.push(`class ${declaration.name} { ${declaration.body} };`);
    }
  }
  let extra = '';
  if (module.id === 'core') {
    copyCode(path.join(root,'Vcom/VcomInit.sqf'),path.join(addon,'VcomInit.sqf'));
    copyCode(path.join(root,'Vcom/Functions/VcomAI_DefaultSettings.sqf'),path.join(addon,'settings/VcomAI_DefaultSettings.sqf'));
  }
  if (module.id === 'squad') {
    copyCode(path.join(root,'Vcom/FSMS/fn_SQUADBEH.fsm'),path.join(addon,'fsm/fn_SQUADBEH.fsm'));
    extra = `class FSM { file="${virtualRoot('squad')}\\fsm"; class SQUADBEH { ext=".fsm"; }; };`;
  }
  if (module.id === 'main') {
    fs.mkdirSync(path.join(addon,'functions'),{recursive:true});
    fs.writeFileSync(path.join(addon,'functions/fn_AddonStart.sqf'),
      `if (!is3DEN) then {[] execVM "${virtualRoot('core')}\\VcomInit.sqf"};\n`);
    registered.push('class AddonStart { postInit=1; };');
  }
  const required = module.id === 'main'
    ? project.modules.filter(item => item.id !== 'main').map(item => `${project.prefix}_${item.id}`)
    : [module.id === 'core' ? 'A3_Functions_F' : `${project.prefix}_core`];
  fs.writeFileSync(path.join(addon,'config.cpp'),`class CfgPatches {
 class ${project.prefix}_${module.id} { name="${project.name} - ${module.id}"; author="${project.author}";
 requiredVersion=2.22; requiredAddons[]={${required.map(name => `"${name}"`).join(',')}};
 units[]={}; weapons[]={}; version="${project.version}"; };
};
class CfgFunctions { class VCOM { tag="VCM";
 class ${module.category} { file="${virtualRoot(module.id)}\\functions"; ${registered.join('\n')} };
 ${extra}
}; };
${module.id === 'core' ? `class CfgRemoteExec { class Functions { ${remoteFunctions.join('\n')} }; };` : ''}
`);
}
fs.writeFileSync(path.join(stage,'REMOTE-EXEC.hpp'),`class CfgRemoteExec { class Functions { ${remoteFunctions.join('\n')} }; };\n`);
const [major,minor,patch] = project.version.split('.');
fs.writeFileSync(path.join(stage,'.hemtt/project.toml'),`name = "${project.name}"
prefix = "${project.prefix}"
mainprefix = "z"
[version]
major = ${major}
minor = ${minor}
patch = ${patch}
git_hash = 0
[files]
include = ["README.md", "MIGRATION.md", "ROADMAP.md", "FEATURES.md", "REMOTE-EXEC.hpp", "ADDON-MODULES.json", "userconfig/**"]
`);
fs.writeFileSync(path.join(stage,'mod.cpp'),`name="${project.name} ${project.version}"; author="${project.author}"; tooltip="${project.name}"; description="Modular VCOM AI edited by Fijik; original VCOM by Genesis";\n`);
fs.writeFileSync(path.join(stage,'README.md'),`# ${project.name} ${project.version}

Install ${project.modFolder} as an Arma 3 mod and load it on server, headless clients and players with -mod=${project.modFolder}. Requires Arma 3 2.22 or newer. CBA and ACE are optional.

Remove older VCOM addons, including the old @VCOM_AI folder, and embedded mission copies before loading this edition. The addon starts itself. Keep all eight PBOs together; disable behaviors through settings rather than deleting PBOs. Shared function calls still require the complete set.

${project.modules.map(module => `- vcm_${module.id}.pbo: ${module.description}.`).join('\n')}

Copy the supplied public .bikey into the server's keys folder when signature verification is enabled. No private key is included. Merge REMOTE-EXEC.hpp into missions that restrict remote execution.

Defaults work without file patching. CBA provides VCOM settings when installed. Optional userconfig files go into the Arma root's userconfig/VCOM_AI folder and require server file patching. Existing VCM_fnc_* names and mission-script paths remain compatible.

Splitting PBOs organizes maintenance and updates; it does not itself increase FPS. FEATURES.md and MIGRATION.md describe behavior and verification. Original VCOM: Genesis. This edition: Fijik.
`);
fs.writeFileSync(path.join(stage,'ADDON-MODULES.json'),JSON.stringify(project,null,2) + '\n');
fs.cpSync(path.join(root,'userconfig'),path.join(stage,'userconfig'),{recursive:true});
for (const name of ['MIGRATION.md','ROADMAP.md','FEATURES.md']) fs.copyFileSync(path.join(root,name),path.join(stage,name));
const result = spawnSync('hemtt',['release','--no-bin','--no-color'],{cwd:stage,encoding:'utf8'});
const output = (result.stdout || '') + (result.stderr || '');
fs.writeFileSync(path.join(root,'build/release.log'),output);
console.log(output.split(/\r?\n/).filter(line => /INFO|ERROR|^error\[/.test(line)).join('\n'));
if (result.error) throw result.error;
if (result.status !== 0) process.exit(result.status ?? 1);
const mod = path.join(upload,project.modFolder);
assert.equal(path.dirname(mod),upload);
fs.mkdirSync(upload,{recursive:true});
fs.rmSync(mod,{recursive:true,force:true});
fs.cpSync(path.join(stage,'.hemttout/release'),mod,{recursive:true});
const inventory = [];
function scan(folder) {
  for (const entry of fs.readdirSync(folder,{withFileTypes:true})) {
    const name = path.join(folder,entry.name);
    if (entry.isDirectory()) scan(name);
    else {
      assert.ok(!/\.biprivatekey$/i.test(entry.name),'Never include a private key in the upload');
      inventory.push({path:path.relative(mod,name).replaceAll('\\','/'),bytes:fs.statSync(name).size,
        sha256:crypto.createHash('sha256').update(fs.readFileSync(name)).digest('hex')});
    }
  }
}
scan(mod);
for (const module of project.modules) {
  const pbo = `addons/${project.prefix}_${module.id}.pbo`;
  assert.ok(inventory.some(file => file.path === pbo),`Missing ${pbo}`);
  assert.ok(inventory.some(file => file.path.startsWith(pbo + '.') && file.path.endsWith('.bisign')),`Missing signature for ${pbo}`);
}
assert.equal(inventory.filter(file => file.path.endsWith('.pbo')).length,project.modules.length);
assert.ok(inventory.some(file => file.path.endsWith('.bikey')));
fs.writeFileSync(path.join(mod,'BUILD-MANIFEST.json'),JSON.stringify({name:project.name,version:project.version,files:inventory},null,2) + '\n');
console.log(`Signed modular mod: ${mod}`);
console.log('Create the final upload ZIP after native addon validation.');
