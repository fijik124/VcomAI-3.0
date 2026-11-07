params ["_group", "_position", ["_type", "MOVE"]];
private _waypoint = _group addWaypoint [_position, 0];
private _name = format ["VCM_%1_%2_%3", clientOwner, diag_tickTime, _waypoint select 1];
_waypoint setWaypointName _name;
_waypoint setWaypointType _type;
_waypoint setWaypointSpeed "FULL";
_waypoint setWaypointCompletionRadius 25;
private _names = _group getVariable ["VCM_WaypointNames", []];
_names pushBack _name;
_group setVariable ["VCM_WaypointNames", _names, true];
_waypoint
