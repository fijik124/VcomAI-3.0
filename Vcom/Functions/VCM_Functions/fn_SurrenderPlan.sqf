/* A nearby remembered enemy and a broken squad are required; unseen enemies never affect morale. */
params ["_group"];
if (!VCM_SURRENDER || {!([_group] call VCM_fnc_GroupEnabled)} ||
    {_group getVariable ["VCM_NOSURRENDER",false]} || {_group getVariable ["VCM_NOAUTOTACTICS",false]} ||
    {time < (_group getVariable ["VCM_SurrenderAfter",-1])}) exitWith {[]};
private _units = (units _group) select {alive _x};
if (_units isEqualTo [] || {_units findIf {
    !local _x || {[_x] call VCM_fnc_HumanControlled} || {!simulationEnabled _x} ||
    {!isNull objectParent _x} || {!isNull attachedTo _x} || {captive _x} ||
    {lifeState _x == "INCAPACITATED"} || {_x getVariable ["ACE_isUnconscious",false]} ||
    {_x getVariable ["ace_captives_isHandcuffed",false]} || {_x getVariable ["ace_captives_isSurrendering",false]} ||
    {_x getVariable ["VCM_NOSURRENDER",false]} || {!(_x checkAIFeature "PATH")} ||
    {!(_x checkAIFeature "MOVE")} || {!(_x checkAIFeature "ANIM")}
} >= 0}) exitWith {[]};
private _peak = (_group getVariable ["VCM_PeakStrength",count _units]) max count _units;
private _pressure = 0;
private _supplied = 0;
{
    _pressure = _pressure + getSuppression _x;
    private _weapons = [primaryWeapon _x,handgunWeapon _x] select {_x != ""};
    private _magazines = [];
    {_magazines append compatibleMagazines _x} forEach _weapons;
    if ((magazinesAmmoFull _x) findIf {(_x select 0) in _magazines && {_x select 1 > 0}} >= 0) then {_supplied = _supplied + 1};
} forEach _units;
private _reason = "";
if (_peak >= 4 && {1 - count _units / _peak >= VCM_SURRENDERLOSS}) then {_reason = "severe casualties"};
if (_pressure / count _units >= VCM_SURRENDERSUPPRESSION) then {_reason = "overwhelming suppression"};
if (_supplied == 0) then {_reason = "no usable firearm ammunition"};
if (_reason == "") exitWith {[]};
private _observer = leader _group;
private _contacts = ([_observer] call VCM_fnc_KnownContacts) select {
    !isNull (_x select 4) && {alive (_x select 4)} && {!captive (_x select 4)} &&
    {[side _group,_x select 2] call BIS_fnc_sideIsEnemy} &&
    {_observer distance2D (_x select 0) <= VCM_SURRENDERRANGE}
};
if (_contacts isEqualTo []) exitWith {[]};
[_reason,+(_contacts select 0 select 0)]
