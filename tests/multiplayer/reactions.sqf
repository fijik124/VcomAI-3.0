/* Gunfire crosses owners; public reaction snapshots survive handoff without repeated inventory transfers. */
private _reactionSettings = [VCM_CIVILIANS,VCM_CIVILIANFREEZE,VCM_CIVILIANPANIC,VCM_SURRENDER,VCM_SURRENDERCHANCE];
VCM_CIVILIANS = true; VCM_CIVILIANFREEZE = 1; VCM_CIVILIANPANIC = 60;
VCM_SURRENDER = true; VCM_SURRENDERCHANCE = 0;
sleep 2;
private _shooters = createGroup [east,true];
_shooters setVariable ["Vcm_Disable",true,true];
_shooters setCombatMode "BLUE";
private _shooter = _shooters createUnit ["O_Soldier_F",[17500,17500,0],[],0,"NONE"];
_shooter allowDamage false;
private _civilians = createGroup [civilian,true];
private _civilian = _civilians createUnit ["C_man_1",[17535,17500,0],[],0,"NONE"];
_civilian allowDamage false;
[_shooters,_first,"civilian-threat shooter to HC1"] call _transfer;
[_civilians,_second,"civilian to HC2"] call _transfer;
["prepareReaction",_civilians,""] remoteExecCall ["VCM_test_fnc_Scenario",_second];
["forgeCivilian",_shooters,"",[_second]] remoteExecCall ["VCM_test_fnc_Scenario",_first];
sleep 1;
[_civilian getVariable ["VCM_CivilianState",[]] isEqualTo [],"HC cannot forge a server civilian-danger instruction"] call _assert;
["fireCivilian",_shooters,""] remoteExecCall ["VCM_test_fnc_Scenario",_first];
private _frightened = [{_civilian getVariable ["VCM_CivilianState",[]] isNotEqualTo []},6] call _await;
[_frightened,"HC1 gunfire causes a civilian reaction on HC2 through the server"] call _assert;
[_civilians,_first,"panicked civilian to HC1"] call _transfer;
[_civilian getVariable ["VCM_CivilianState",[]] isNotEqualTo [],"new civilian owner continues the inherited panic episode"] call _assert;
VCM_CIVILIANS = false;
private _calm = [{_civilian getVariable ["VCM_CivilianState",[]] isEqualTo []},6] call _await;
private _probeResult = [_first,"civilian-released",[_civilians]] call _probe;
private _civilState = ((_probeResult param [3,[]]) param [0,[]]) param [5,[]];
diag_log format ["VCM_MP_CIVILIAN_RELEASE: %1",_civilState apply {[_x select 4,_x select 14,_x select 15,_x select 17]}];
[_calm && {_civilState isNotEqualTo []} && {(_civilState select 0 select 4)} &&
    {(_civilState select 0 select 14) == "MIDDLE"} && {(_civilState select 0 select 15) == 2} &&
    {!(_civilState select 0 select 17)},"new owner restores the civilian's original path, stance, speed and targeting lock"] call _assert;

private _prisoners = createGroup [west,true];
_prisoners setVariable ["VCM_Skilldisable",true,true];
_prisoners setVariable ["VCM_PeakStrength",8,true];
_prisoners setCombatMode "BLUE";
private _soldiers = [];
for "_i" from 0 to 1 do {
    private _soldier = _prisoners createUnit ["B_Soldier_F",[17525,17505 + _i * 3,0],[],0,"NONE"];
    _soldier allowDamage false;
    _soldiers pushBack _soldier;
};
private _hold = _prisoners addWaypoint [[17525,17505,0],0];
_hold setWaypointType "HOLD";
[_prisoners,_second,"surrender squad to HC2"] call _transfer;
["prepareReaction",_prisoners,""] remoteExecCall ["VCM_test_fnc_Scenario",_second];
["surrender",_prisoners,"",[_shooter]] remoteExecCall ["VCM_test_fnc_Scenario",_second];
private _surrendered = [{_prisoners getVariable ["VCM_TestSurrender",false]},6] call _await;
[_surrendered && {_soldiers findIf {!captive _x || {primaryWeapon _x != ""}} < 0},"HC2 squad surrenders and drops its firearms"] call _assert;
private _droppedReady = [{_soldiers findIf {isNull (_x getVariable ["VCM_DroppedWeapons",objNull])} < 0},5] call _await;
[_droppedReady,"ground weapon holders replicate before their owning squad transfers"] call _assert;
private _holders = _soldiers apply {_x getVariable ["VCM_DroppedWeapons",objNull]};
private _holderCount = count nearestObjects [leader _prisoners,["GroundWeaponHolder_Scripted"],15];
[_prisoners,_first,"surrendered squad to HC1"] call _transfer;
_probeResult = [_first,"surrender-handoff",[_prisoners]] call _probe;
private _prisonerState = (_probeResult param [3,[]]) param [0,[]];
diag_log format ["VCM_MP_SURRENDER_HANDOFF: controllers=%1 units=%2",_prisonerState param [2,-1],
    (_prisonerState param [5,[]]) apply {[_x select 4,_x select 8,count (_x select 13),_x select 16,_x select 17,_x select 14,_x select 15]}];
[_prisonerState isNotEqualTo [] && {(_prisonerState select 2) == 0} &&
    {(_prisonerState select 5) findIf {(_x select 13) isEqualTo [] || {!(_x select 16)} || {_x select 4} || {_x select 8}} < 0},
    "surrendered handoff retains captive state with no combat controller or enabled firing"] call _assert;
[_holders isEqualTo (_soldiers apply {_x getVariable ["VCM_DroppedWeapons",objNull]}),"surrender handoff preserves the same ground weapon holders"] call _assert;
[_holderCount == count nearestObjects [leader _prisoners,["GroundWeaponHolder_Scripted"],15],"surrender handoff creates no extra ground weapons"] call _assert;
VCM_SURRENDER = false;
private _released = [{_soldiers findIf {_x getVariable ["VCM_SurrenderState",[]] isNotEqualTo []} < 0},6] call _await;
_probeResult = [_first,"surrender-released",[_prisoners]] call _probe;
_prisonerState = (_probeResult param [3,[]]) param [0,[]];
diag_log format ["VCM_MP_SURRENDER_RELEASE: %1",(_prisonerState param [5,[]]) apply {
    [_x select 4,_x select 8,count (_x select 13),_x select 16,_x select 17,_x select 14,_x select 15]
}];
[_released && {_prisonerState isNotEqualTo []} && {(_prisonerState select 5) findIf {
    !(_x select 4) || {!(_x select 8)} || {_x select 16} || {_x select 17} ||
    {(_x select 14) != "MIDDLE"} || {(_x select 15) != 2}
} < 0},"new owner releases surrender and restores only the original AI features"] call _assert;
_prisoners setVariable ["Vcm_Disable",true,true];
sleep 0.5;
{if (!isNull _x) then {deleteVehicle _x}} forEach (_holders + _soldiers + [_civilian,_shooter]);
{deleteGroup _x} forEach [_civilians,_shooters,_prisoners];
VCM_CIVILIANS = _reactionSettings select 0;
VCM_CIVILIANFREEZE = _reactionSettings select 1;
VCM_CIVILIANPANIC = _reactionSettings select 2;
VCM_SURRENDER = _reactionSettings select 3;
VCM_SURRENDERCHANCE = _reactionSettings select 4;
