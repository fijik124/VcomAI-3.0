/* Separate local infantry and AI vehicle groups cooperate without replacing authored routes. */
params ["_group"];
_group setVariable ["VCM_EscortPlanReason","eligibility"];
if (!VCM_COMBINEDARMS || {!([_group] call VCM_fnc_TacticalReady)} ||
    {diag_tickTime < (_group getVariable ["VCM_EscortAfter",-1])}) exitWith {[]};
private _enemy = leader _group call VCM_fnc_ClstEmy;
_group setVariable ["VCM_EscortPlanReason","contact"];
private _contact = [leader _group,_enemy] call VCM_fnc_ContactPosition;
if (_contact isEqualTo [] || {leader _group distance2D _contact < 80} || {leader _group distance2D _contact > 600}) exitWith {[]};
private _vehicles = [];
if (!isNull objectParent leader _group) then {_vehicles pushBack vehicle leader _group} else {
    _vehicles = nearestObjects [leader _group,["LandVehicle"],80];
};
_group setVariable ["VCM_EscortPlanReason","vehicle"];
_vehicles = _vehicles select {
    private _driver = driver _x;
    local _x && {alive _x} && {canMove _x} && {!(_x isKindOf "StaticWeapon")} &&
    {getNumber (configFile >> "CfgVehicles" >> typeOf _x >> "artilleryScanner") != 1} &&
    {alive _driver} && {local _driver} && {!isPlayer _driver} && {group _driver != _group} &&
    {[side _group,side group _driver] call BIS_fnc_sideIsFriendly} && {([group _driver] call VCM_fnc_TacticalReady)} &&
    {_x getVariable ["VCM_InfantryPartner",[]] isEqualTo []}
};
if (_vehicles isEqualTo []) exitWith {[]};
private _vehicle = _vehicles select 0;
private _crewGroup = group driver _vehicle;
private _passengers = (units _group) select {vehicle _x == _vehicle && {_x != driver _vehicle} && {_x != gunner _vehicle} && {_x != commander _vehicle}};
private _foot = [_group] call VCM_fnc_TacticalUnits;
_group setVariable ["VCM_EscortPlanReason",format ["participants:%1:%2",count _foot,count _passengers]];
if (count (_foot + _passengers) < 2 || {count (_foot + _passengers) > 12}) exitWith {[]};
private _standoff = _contact getPos [VCM_DISEMBARKRANGE max 150,_contact getDir getPosATL _vehicle];
private _stage = _vehicle getPos [(_vehicle distance2D _standoff) min 60,_vehicle getDir _standoff];
_stage = _stage findEmptyPosition [0,10,typeOf _vehicle];
_group setVariable ["VCM_EscortPlanReason",if (_stage isEqualTo []) then {"position:none"} else {format ["position:%1:water=%2:normal=%3",_stage,surfaceIsWater _stage,surfaceNormal _stage]}];
if (_stage isEqualTo [] || {surfaceIsWater _stage} || {(surfaceNormal _stage select 2) < 0.85}) exitWith {[]};
_group setVariable ["VCM_EscortPlanReason","ready"];
[_vehicle,_crewGroup,_stage,_passengers,_enemy,_contact]
