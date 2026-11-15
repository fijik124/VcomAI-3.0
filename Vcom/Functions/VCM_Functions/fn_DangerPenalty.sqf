/* Score destinations only. Native pathfinding still determines the route actually walked. */
params ["_group","_position"];
if (!VCM_DANGERMEMORY) exitWith {0};
private _penalty = 0;
{
    _x params ["_point","_weight","_expires"];
    if (_expires > time) then {
        private _distance = _position distance2D _point;
        if (_distance < VCM_DANGERRADIUS) then {
            _penalty = _penalty + 20 * _weight * (1 - _distance / VCM_DANGERRADIUS);
        };
    };
} forEach (_group getVariable ["VCM_DangerMemory",[]]);
if (VCM_COMMANDPOINTS) then {
    {
        private _distance = _position distance2D (_x select 2);
        private _radius = _x select 4;
        if (_distance < _radius) then {_penalty = _penalty + 100 * (1 - _distance / _radius)};
    } forEach (_group getVariable ["VCM_DangerPoints",[]]);
};
_penalty min 500
