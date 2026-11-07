/* Author: Genesis. Hold a building without disabling engine pathfinding. */
private _group = _this;
if (_group getVariable ["VCM_BoundState", []] isNotEqualTo []) exitWith {};
private _run = _group getVariable ["VCM_RunId", []];
if (!([_group] call VCM_fnc_GroupEnabled) || {_group getVariable ["VCM_GarrisonBusy", false]}) exitWith {};
private _waypoint = [_group, currentWaypoint _group];
if (waypointType _waypoint != "HOLD") exitWith {};
private _buildings = nearestObjects [waypointPosition _waypoint, ["House", "Building"], 50];
_buildings = _buildings select {count (_x buildingPos -1) > 2};
if (_buildings isEqualTo []) exitWith {};
private _positions = (_buildings select 0) buildingPos -1;
_group setVariable ["VCM_GarrisonBusy", true];
{
    if (count _positions == 0) exitWith {};
    if (local _x && {alive _x} && {isNull objectParent _x} && {!isPlayer _x}) then {
        private _position = _positions deleteAt 0;
        [_x, _position, _waypoint, _run] spawn {
            params ["_unit", "_position", "_waypoint", "_run"];
            private _group = group _unit;
            if (!([_unit, _group, _run] call VCM_fnc_ActionValid)) exitWith {};
            private _guard = {params ["_unit", "_group"]; currentWaypoint _group == (_waypoint select 1) && {waypointType _waypoint == "HOLD"}};
            private _arrived = [_unit, _position, 60, _guard] call VCM_fnc_MoveTo;
            if (_arrived) then {doStop _unit};
            waitUntil {
                sleep 0.25;
                !([_unit, _group, _run] call VCM_fnc_ActionValid) || {!([_unit, _group] call _guard)}
            };
            if ([_unit, _group, _run] call VCM_fnc_ActionValid) then {
                if (_unit != leader _group) then {_unit doFollow leader _group};
            };
        };
    };
} forEach units _group;
waitUntil {
    sleep 0.25;
    !([_group] call VCM_fnc_GroupEnabled) || {!(_run isEqualTo (_group getVariable ["VCM_RunId", []]))} ||
    {currentWaypoint _group != (_waypoint select 1)} || {waypointType _waypoint != "HOLD"}
};
if (_run isEqualTo (_group getVariable ["VCM_RunId", []])) then {_group setVariable ["VCM_GarrisonBusy", false]};
