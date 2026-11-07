/* Author: Genesis. Local groups respond only to a known contact, without replacing mission orders. */
params ["_unit", "_killer"];
private _group = group _unit;
private _run = _group getVariable ["VCM_RunId", []];
if (!([_group] call VCM_fnc_GroupEnabled) || {_group getVariable ["VCM_TOUGHSQUAD", false]} ||
    {_group getVariable ["VCM_NOFLANK", false]} || {time < (_group getVariable ["VCM_HelpAfter", -1])}) exitWith {};
private _hasRadio = {
    params ["_soldier"];
    (assignedItems _soldier) findIf {_x isKindOf ["ItemRadio", configFile >> "CfgWeapons"]} >= 0
};
if (!([leader _group] call _hasRadio)) exitWith {};
private _enemy = (leader _group) call VCM_fnc_ClstEmy;
if (isNull _enemy) exitWith {};
private _position = [leader _group, _enemy] call VCM_fnc_ContactPosition;
if (_position isEqualTo []) exitWith {};
_group setVariable ["VCM_HelpAfter", time + 300];
sleep VCM_WARNDELAY;
if (!([_group] call VCM_fnc_GroupEnabled) || {!(_run isEqualTo (_group getVariable ["VCM_RunId", []]))}) exitWith {};
private _responders = 0;
{
    private _support = _x;
    if (_responders < 2 && {_support != _group} && {[_support] call VCM_fnc_GroupEnabled} &&
        {[side _group, side _support] call BIS_fnc_sideIsFriendly} &&
        {leader _support distance2D leader _group <= VCM_WARNDIST} &&
        {!(_support getVariable ["VCM_NORESCUE", false])} && {!(_support getVariable ["VCM_NOFLANK", false])} &&
        {!(_support getVariable ["VCM_MOVE2SUP", false])} && {[leader _support] call _hasRadio} &&
        {_support getVariable ["VCM_BoundState", []] isEqualTo []} &&
        {(waypoints _support) findIf {(_x select 1) > 0} < 0}) then {
        _support setVariable ["VCM_MOVE2SUP", true];
        private _waypoint = [_support, _position] call VCM_fnc_AddWaypoint;
        private _name = waypointName _waypoint;
        _support setCurrentWaypoint _waypoint;
        [_support, _support getVariable ["VCM_RunId", []], _name, _position] spawn {
            params ["_support", "_run", "_name", "_position"];
            private _deadline = diag_tickTime + 180;
            waitUntil {
                sleep 1;
                !([_support] call VCM_fnc_GroupEnabled) || {!(_run isEqualTo (_support getVariable ["VCM_RunId", []]))} ||
                {diag_tickTime >= _deadline} || {leader _support distance2D _position < 30}
            };
            if (_run isEqualTo (_support getVariable ["VCM_RunId", []])) then {
                [_support, [_name]] call VCM_fnc_ClearWaypoints;
                _support setVariable ["VCM_MOVE2SUP", false];
            };
        };
        _responders = _responders + 1;
    };
} forEach allGroups;
