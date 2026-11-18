/* Native behavior and inventory acceptance: real travel, prone stance, gunfire events and ACE surrender. */
private _saved = [VCM_CIVILIANS,VCM_CIVILIANFREEZE,VCM_SURRENDER,VCM_SURRENDERDROP,VCM_SURRENDERCHANCE];
VCM_CIVILIANS = true;
VCM_CIVILIANFREEZE = 0;
VCM_SURRENDER = false;
VCM_SURRENDERCHANCE = 0;
private _hostiles = createGroup [east,true];
_hostiles setVariable ["Vcm_Disable",true];
_hostiles setCombatMode "BLUE";
private _shooter = _hostiles createUnit ["O_Soldier_F",[16000,16000,0],[],0,"NONE"];
_shooter allowDamage false;
_shooter disableAI "TARGET";
_shooter disableAI "AUTOTARGET";
private _civilians = createGroup [civilian,true];
private _civilian = _civilians createUnit ["C_man_1",[16040,16000,0],[],0,"NONE"];
_civilian allowDamage false;
_civilian disableAI "AUTOTARGET";
_civilian setUnitPos "MIDDLE";
_civilian forceSpeed 4;
private _waypoint = _civilians addWaypoint [[16200,16000,0],0];
_waypoint setWaypointName "CIVILIAN_AUTHORED_ROUTE";
private _start = getPosATL _civilian;
private _distance = _civilian distance2D _shooter;
private _alarm = {
    _shooter setVariable ["VCM_ServerHearing",-100];
    [_shooter,currentWeapon _shooter] call VCM_fnc_HearingRelay;
    sleep 0.2;
};
[_civilian] call VCM_fnc_CivilianEligible call {[_this,"unarmed civilians react without enabling civilian combat squads"] call _assert};
call _alarm;
private _state = _civilian getVariable ["VCM_CivilianState",[]];
[_state isNotEqualTo [] && {(_state select 5) == "flee"},"gunfire selects civilian escape when freeze chance is zero"] call _assert;
[_state isNotEqualTo [] && {(_state select 7) distance2D _shooter > _distance},"civilian escape destination increases distance from heard gunfire"] call _assert;
private _deadline = diag_tickTime + 15;
waitUntil {sleep 0.2; _civilian distance2D _start > 5 || {diag_tickTime > _deadline}};
[_civilian distance2D _start > 5 && {_civilian distance2D _shooter > _distance + 3},"civilian physically runs away from gunfire"] call _assert;
_civilian setVariable ["VCM_CivilianThreat",[getPosATL _shooter,time - 1],true];
[_civilian] call VCM_fnc_CivilianTick;
[_civilian getVariable ["VCM_CivilianState",[]] isEqualTo [] && {_civilian checkAIFeature "PATH"} &&
    {!(_civilian checkAIFeature "AUTOTARGET")} && {unitPos _civilian == "MIDDLE"} && {getForcedSpeed _civilian == 4},
    "calm civilians restore stance, speed and original AI feature locks"] call _assert;
[(waypoints _civilians) findIf {waypointName _x == "CIVILIAN_AUTHORED_ROUTE"} >= 0,"civilian panic preserves authored waypoints"] call _assert;
VCM_CIVILIANFREEZE = 1;
call _alarm;
sleep 3;
_state = _civilian getVariable ["VCM_CivilianState",[]];
[(_state param [5,""]) == "freeze" && {stance _civilian == "PRONE"} && {getForcedSpeed _civilian == 0},"frightened civilian lies prone and freezes"] call _assert;
if (_state isNotEqualTo []) then {_state set [6,time - 1]; _civilian setVariable ["VCM_CivilianState",_state,true]};
[_civilian] call VCM_fnc_CivilianTick;
[(_civilian getVariable ["VCM_CivilianState",[]]) param [5,""] == "flee" && {_civilian checkAIFeature "PATH"},"prone freeze ends with another escape attempt"] call _assert;
VCM_CIVILIANS = false;
[_civilian] call VCM_fnc_CivilianTick;
[_civilian getVariable ["VCM_CivilianState",[]] isEqualTo [] && {getForcedSpeed _civilian == 4},"live civilian disable restores owned state"] call _assert;
call _alarm;
[_civilian getVariable ["VCM_CivilianState",[]] isEqualTo [],"disabled civilian feature ignores gunfire"] call _assert;
VCM_CIVILIANS = true;
_civilian disableAI "PATH";
call _alarm;
[_civilian getVariable ["VCM_CivilianState",[]] isEqualTo [] && {!(_civilian checkAIFeature "PATH")},"civilian mission path lock prevents takeover"] call _assert;
_civilian enableAI "PATH";
_civilians setVariable ["VCM_NOCIVILIAN",true];
call _alarm;
[_civilian getVariable ["VCM_CivilianState",[]] isEqualTo [],"civilian group opt-out prevents takeover"] call _assert;
_civilians setVariable ["VCM_NOCIVILIAN",false];
VCM_CIVILIANFREEZE = 0;
_shooter setVariable ["VCM_FTH",-100];
_shooter setVariable ["VCM_ServerHearing",-100];
_shooter forceWeaponFire [currentWeapon _shooter,"Single"];
_deadline = diag_tickTime + 5;
waitUntil {sleep 0.1; _civilian getVariable ["VCM_CivilianState",[]] isNotEqualTo [] || {diag_tickTime > _deadline}};
[_civilian getVariable ["VCM_CivilianState",[]] isNotEqualTo [],"actual gunfire from a non-VCOM shooter triggers civilian fear through the server"] call _assert;
[_civilian] call VCM_fnc_CivilianRelease;

private _squad = createGroup [west,true];
_squad setVariable ["VCM_Skilldisable",true];
_squad setCombatMode "BLUE";
private _soldiers = [];
for "_i" from 0 to 1 do {
    private _soldier = _squad createUnit ["B_Soldier_F",[16020,16010 + _i * 3,0],[],0,"NONE"];
    _soldier allowDamage false;
    _soldier disableAI "AUTOTARGET";
    _soldier addPrimaryWeaponItem "optic_Aco";
    _soldier setAmmo [primaryWeapon _soldier,7];
    _soldier setUnitPos "MIDDLE";
    _soldier forceSpeed 3;
    _soldiers pushBack _soldier;
};
private _soldier = _soldiers select 0;
_squad reveal [_shooter,4];
_squad setVariable ["VCM_PeakStrength",8,true];
sleep 1;
[[_squad] call VCM_fnc_SurrenderPlan isEqualTo [],"disabled surrender setting blocks even a broken squad"] call _assert;
VCM_SURRENDER = true;
private _plan = [_squad] call VCM_fnc_SurrenderPlan;
[_plan isNotEqualTo [],"severe casualties plus a nearby known enemy permit surrender"] call _assert;
_squad setVariable ["VCM_NOSURRENDER",true];
[[_squad] call VCM_fnc_SurrenderPlan isEqualTo [],"mission surrender opt-out is honored"] call _assert;
_squad setVariable ["VCM_NOSURRENDER",false];
_squad forgetTarget _shooter;
sleep 0.2;
[[_squad] call VCM_fnc_SurrenderPlan isEqualTo [],"unknown enemies cannot trigger surrender"] call _assert;
_squad reveal [_shooter,4];
sleep 0.2;
_squad call VCM_fnc_SquadExc;
sleep 1.5;
private _loadout = getUnitLoadout _soldier;
private _directHolder = [_soldier] call VCM_fnc_DropWeapons;
private _unarmedLoadout = getUnitLoadout _soldier;
[_loadout select [3,7] isEqualTo (_unarmedLoadout select [3,7]),"dropping firearms alone preserves the rest of the loadout"] call _assert;
deleteVehicle _directHolder;
_soldier setUnitLoadout [_loadout,false];
private _roundsBefore = 0;
private _firearmMagazines = [];
{
    {if (_x isNotEqualTo []) then {_firearmMagazines pushBackUnique (_x select 0)}} forEach [_x param [4,[]],_x param [5,[]]];
} forEach (_loadout select [0,3]);
{if (_x select 0 in _firearmMagazines) then {_roundsBefore = _roundsBefore + (_x select 1)}} forEach magazinesAmmoFull _soldier;
VCM_SURRENDERDROP = true;
[[_squad] call VCM_fnc_Surrender,"eligible squad enters surrender"] call _assert;
sleep 1;
[!([_squad] call VCM_fnc_GroupEnabled) && {_soldiers findIf {!captive _x} < 0},"surrender makes soldiers captive and stops combat controllers"] call _assert;
[_soldiers findIf {primaryWeapon _x != "" || {handgunWeapon _x != ""} || {secondaryWeapon _x != ""}} < 0,"surrendered soldiers drop equipped firearms"] call _assert;
private _holder = _soldier getVariable ["VCM_DroppedWeapons",objNull];
private _cargo = weaponsItemsCargo _holder;
[!isNull _holder && {_cargo findIf {_x isEqualTo (_loadout select 0)} >= 0},"ground weapon preserves attachments and seven loaded rounds"] call _assert;
private _roundsAfter = 0;
{if (_x select 0 in _firearmMagazines) then {_roundsAfter = _roundsAfter + (_x select 1)}} forEach magazinesAmmoFull _soldier;
{
    {if (_x isNotEqualTo []) then {_roundsAfter = _roundsAfter + (_x select 1)}} forEach [_x select 4,_x select 5];
} forEach _cargo;
[_roundsBefore == _roundsAfter,"weapon transfer conserves loaded and spare firearm ammunition"] call _assert;
private _holders = count nearestObjects [_soldier,["GroundWeaponHolder_Scripted"],10];
[_soldier] call VCM_fnc_SurrenderTick;
[_soldier] call VCM_fnc_DropWeapons;
[_holders == count nearestObjects [_soldier,["GroundWeaponHolder_Scripted"],10] && {_cargo isEqualTo weaponsItemsCargo _holder},"repeated surrender updates do not duplicate dropped weapons"] call _assert;
if (!isNil "ace_captives_fnc_setSurrendered") then {
    [_soldier getVariable ["ace_captives_isSurrendering",false],"ACE captives owns the surrendered pose when available"] call _assert;
};
VCM_SURRENDER = false;
{[_x] call VCM_fnc_SurrenderTick} forEach _soldiers;
// The ordinary owner scanner must also initiate surrender without a test calling its start function.
{_x setUnitLoadout _loadout} forEach _soldiers;
_squad setVariable ["VCM_SurrenderAfter",-1,true];
_squad setVariable ["VCM_NextMorale",-1];
_squad reveal [_shooter,4];
VCM_SURRENDER = true;
VCM_SURRENDERCHANCE = 1;
_deadline = diag_tickTime + 8;
waitUntil {sleep 0.1; _squad getVariable ["VCM_Surrendered",false] &&
    {_soldiers findIf {_x getVariable ["VCM_SurrenderState",[]] isEqualTo []} < 0} || {diag_tickTime > _deadline}};
[_squad getVariable ["VCM_Surrendered",false],"ordinary owner scanner automatically initiates eligible surrender"] call _assert;
VCM_SURRENDER = false;
VCM_SURRENDERCHANCE = 0;
{[_x] call VCM_fnc_SurrenderTick} forEach _soldiers;
[_soldiers findIf {captive _x || {!(_x checkAIFeature "PATH")} || {_x checkAIFeature "AUTOTARGET"} ||
    {unitPos _x != "MIDDLE"} || {getForcedSpeed _x != 3}} < 0,"disabling surrender restores captive status, stance, speed and original AI locks"] call _assert;
[primaryWeapon _soldier == "" && {!isNull _holder} && {_cargo isEqualTo weaponsItemsCargo _holder},"release leaves the dropped equipment on the ground"] call _assert;

// With dropping disabled, a surrendered soldier keeps weapons but cannot fire or rearm.
_deadline = diag_tickTime + 4;
waitUntil {sleep 0.1; _soldiers findIf {isSwitchingWeapon _x || {captive _x} ||
    {_x getVariable ["ace_captives_isSurrendering",false]} || {!(_x checkAIFeature "ANIM")}} < 0 || {diag_tickTime > _deadline}};
VCM_SURRENDER = true;
VCM_SURRENDERDROP = false;
{_x setUnitLoadout _loadout} forEach _soldiers;
_squad setVariable ["VCM_SurrenderAfter",-1,true];
_squad reveal [_shooter,4];
_deadline = diag_tickTime + 4;
waitUntil {sleep 0.1; [_squad] call VCM_fnc_SurrenderPlan isNotEqualTo [] || {diag_tickTime > _deadline}};
if ([_squad] call VCM_fnc_SurrenderPlan isEqualTo []) then {
    diag_log format ["VCM_SURRENDER_PREP: enabled=%1 after=%2 now=%3 flags=%4",[_squad] call VCM_fnc_GroupEnabled,
        _squad getVariable ["VCM_SurrenderAfter",-1],time,_soldiers apply {[captive _x,_x checkAIFeature "PATH",
        _x checkAIFeature "MOVE",_x checkAIFeature "ANIM",_x getVariable ["ace_captives_isSurrendering",false],primaryWeapon _x]}];
};
[[_squad] call VCM_fnc_Surrender,"surrender also works with weapon dropping disabled"] call _assert;
[primaryWeapon _soldier != "" && {!(_soldier checkAIFeature "FIREWEAPON")},"drop toggle preserves carried weapons while blocking fire"] call _assert;
VCM_SURRENDERDROP = true;
[_soldier] call VCM_fnc_SurrenderTick;
[primaryWeapon _soldier == "" && {(_soldier getVariable ["VCM_SurrenderState",[]]) param [8,false]},
    "enabling weapon dropping during surrender performs one transfer"] call _assert;
if (!isNil "ace_captives_fnc_setHandcuffed") then {
    [_soldier,true] call ace_captives_fnc_setHandcuffed;
    [_soldier] call VCM_fnc_SurrenderTick;
    [_soldier getVariable ["VCM_SurrenderState",[]] isEqualTo [] && {captive _soldier} &&
        {_soldier getVariable ["ace_captives_isHandcuffed",false]},"handcuffing transfers control to ACE without releasing its captive"] call _assert;
    [_soldier,false] call ace_captives_fnc_setHandcuffed;
};
VCM_SURRENDER = false;
{[_x] call VCM_fnc_SurrenderTick} forEach _soldiers;
// ACE Medical is required, while the Captives component may be absent or still unavailable.
private _captivityReady = missionNamespace getVariable ["ace_captives_captivityEnabled",false];
ace_captives_captivityEnabled = false;
VCM_SURRENDER = true;
VCM_SURRENDERDROP = false;
{_x setUnitLoadout [_loadout,false]} forEach _soldiers;
_squad setVariable ["VCM_SurrenderAfter",-1,true];
_squad reveal [_shooter,4];
sleep 0.2;
private _nativeSurrender = [_squad] call VCM_fnc_Surrender;
sleep 0.3;
[_nativeSurrender && {captive _soldier} && {!((_soldier getVariable ["VCM_SurrenderState",[]]) param [6,true])} &&
    {toLower animationState _soldier find "amovpercmstpssur" == 0},"native surrender works when ACE Captives is unavailable"] call _assert;
VCM_SURRENDER = false;
{[_x] call VCM_fnc_SurrenderTick} forEach _soldiers;
[_soldiers findIf {captive _x || {!(_x checkAIFeature "PATH")}} < 0,"native surrender release restores captive status and movement"] call _assert;
ace_captives_captivityEnabled = _captivityReady;
{
    private _ground = _x getVariable ["VCM_DroppedWeapons",objNull];
    if (!isNull _ground) then {deleteVehicle _ground};
    deleteVehicle _x;
} forEach _soldiers;
deleteVehicle _civilian;
deleteVehicle _shooter;
deleteGroup _civilians;
deleteGroup _squad;
deleteGroup _hostiles;
VCM_CIVILIANS = _saved select 0;
VCM_CIVILIANFREEZE = _saved select 1;
VCM_SURRENDER = _saved select 2;
VCM_SURRENDERDROP = _saved select 3;
VCM_SURRENDERCHANCE = _saved select 4;
