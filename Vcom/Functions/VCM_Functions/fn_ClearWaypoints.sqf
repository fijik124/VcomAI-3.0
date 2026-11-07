/* Names survive waypoint index changes. Never delete a mission/Zeus waypoint. */
params ["_group", ["_only", []]];
if (!local _group) exitWith {};
private _names = _group getVariable ["VCM_WaypointNames", []];
private _remove = if (_only isEqualTo []) then {_names} else {_only};
private _waypoints = waypoints _group;
reverse _waypoints;
{
    if (waypointName _x in _remove) then {deleteWaypoint _x};
} forEach _waypoints;
_group setVariable ["VCM_WaypointNames", _names - _remove, true];
