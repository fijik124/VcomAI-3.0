import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {root} from '../tools/addon-project.mjs';

const run = path.resolve(process.argv[2]);
assert.equal(path.dirname(run),path.join(root,'build/debug'));
const mission = path.join(run,'VCM_Debug.VR');
fs.mkdirSync(mission,{recursive:true});
let description = fs.readFileSync(path.join(root,'description.ext'),'utf8')
  .replace(/class CfgFunctions\s*\{[\s\S]*?\};/,'');
fs.writeFileSync(path.join(mission,'description.ext'),description);
fs.copyFileSync(path.join(root,'tests/debug.sqf'),path.join(mission,'debug.sqf'));
fs.writeFileSync(path.join(mission,'init.sqf'),'[] execVM "debug.sqf";\n');
fs.writeFileSync(path.join(mission,'mission.sqm'),`version=12;
class Mission {
 addOns[]={"A3_Characters_F_BLUFOR","A3_Map_VR","A3_Modules_F"};
 addOnsAuto[]={"A3_Characters_F_BLUFOR","A3_Map_VR","A3_Modules_F"}; randomSeed=1;
 class Intel { briefingName="VCOM graphical debugger acceptance"; year=2035; month=6; day=24; hour=12; minute=0; };
 class Groups { items=1; class Item0 { side="WEST"; class Vehicles { items=1; class Item0 {
  position[]={500,0,500}; id=0; side="WEST"; vehicle="B_Soldier_F"; player="PLAYER COMMANDER";
  leader=1; skill=0.6; init="(group this) setVariable ['Vcm_Disable',true]; this allowDamage false;";
 }; }; }; };
};
`);
fs.writeFileSync(path.join(run,'Arma3.cfg'),'Windowed=1; winX=0; winY=0; winWidth=1280; winHeight=720; refresh=60;\n');
console.log(mission);
