params ["_group","_plan"];
if (_plan isEqualTo [] || {!([_group] call VCM_fnc_TacticalReady)}) exitWith {false};
_plan params ["_vehicle","_crewGroup","_stage","_passengers","_enemy","_contact"];
if (!([_crewGroup] call VCM_fnc_TacticalReady)) exitWith {false};
if (!(_crewGroup in VcmAI_ActiveList)) then {_crewGroup call VCM_fnc_SquadExc};
private _run = _group getVariable ["VCM_RunId",[]];
private _crewRun = _crewGroup getVariable ["VCM_RunId",[]];
private _key = [_run,diag_tickTime];
private _driver = driver _vehicle;
_group setVariable ["VCM_EscortAfter",diag_tickTime + 60];
_vehicle setVariable ["VCM_InfantryPartner",[_group,_key,time + 40],true];
_crewGroup setVariable ["VCM_ArmorPartner",[_group,_key]];
private _valid = {
    [_group] call VCM_fnc_GroupEnabled && {[_crewGroup] call VCM_fnc_GroupEnabled} && {VCM_COMBINEDARMS} &&
    {_run isEqualTo (_group getVariable ["VCM_RunId",[]])} && {_crewRun isEqualTo (_crewGroup getVariable ["VCM_RunId",[]])} &&
    {local _vehicle} && {alive _vehicle} && {driver _vehicle == _driver} &&
    {(waypoints _group) findIf {(_x select 1) > 0} < 0} && {(waypoints _crewGroup) findIf {(_x select 1) > 0} < 0}
};
if (_passengers isNotEqualTo [] && {call _valid} && {abs speed _vehicle < 5} &&
    {_vehicle distance2D _contact >= 100} && {(getPosATL _vehicle select 2) < 2}) then {
    {unassignVehicle _x; doGetOut _x} forEach _passengers;
    private _deadline = diag_tickTime + 10;
    waitUntil {sleep 0.25; !call _valid || {_passengers findIf {!isNull objectParent _x} < 0} || {diag_tickTime > _deadline}};
};
private _foot = [_group] call VCM_fnc_TacticalUnits;
private _result = false;
if (call _valid && {count _foot >= 2}) then {
    private _rear = _stage getPos [20,(_stage getDir _contact) + 180];
    private _destinations = [];
    {
        private _position = (_rear getPos [5 + 4 * floor (_forEachIndex / 2),(_stage getDir _contact) + ([-90,90] select (_forEachIndex mod 2 == 0))]) findEmptyPosition [0,3,typeOf _x];
        if (_position isNotEqualTo [] && {_x distance2D _position > 90}) then {_position = []};
        _destinations pushBack _position;
    } forEach _foot;
    if (_destinations findIf {_x isEqualTo [] || {surfaceIsWater _x}} < 0) then {
        private _front = _vehicle getPos [10,_vehicle getDir _stage];
        private _blocked = (_vehicle nearEntities ["Man",12]) findIf {
            alive _x && {isNull objectParent _x} && {_x distance2D _front < 8} &&
            {!([side _crewGroup,side group _x] call BIS_fnc_sideIsEnemy)}
        } >= 0;
        if (!_blocked) then {_driver doMove _stage};
        if (alive gunner _vehicle && {!isPlayer gunner _vehicle}) then {gunner _vehicle doWatch (_contact vectorAdd [0,0,1])};
        _group setVariable ["VCM_LastEscort",[_vehicle,_stage,count _foot,count _passengers],true];
        private _job = [_group,"escort",[[[],_foot,_destinations,25,_contact]],_enemy,_contact] spawn VCM_fnc_RunTactical;
        waitUntil {sleep 0.25; scriptDone _job || {!call _valid}};
        if (!call _valid) then {
            private _task = _group getVariable ["VCM_Task",[]];
            if (_task isNotEqualTo [] && {_task select 1 == "escort"}) then {[_group,_task select 0] call VCM_fnc_EndTactical};
        };
        _result = call _valid;
    };
};
if (local _vehicle && {((_vehicle getVariable ["VCM_InfantryPartner",[]]) param [1,[]]) isEqualTo _key}) then {
    _vehicle setVariable ["VCM_InfantryPartner",nil,true];
    if (local _driver && {!isPlayer _driver} && {(waypoints _crewGroup) findIf {(_x select 1) > 0} < 0}) then {doStop _driver};
    if (local gunner _vehicle && {!isPlayer gunner _vehicle}) then {gunner _vehicle doWatch objNull};
};
if (((_crewGroup getVariable ["VCM_ArmorPartner",[]]) param [1,[]]) isEqualTo _key) then {_crewGroup setVariable ["VCM_ArmorPartner",nil]};
_result
