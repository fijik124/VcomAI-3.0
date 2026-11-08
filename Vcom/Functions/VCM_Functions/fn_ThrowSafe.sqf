/* Bounded ballistic samples return [safe, predicted impact ASL, reason]. No synthetic explosives. */
params ["_unit","_ammo","_start","_velocity",["_projectile",objNull]];
private _config = configFile >> "CfgAmmo" >> _ammo;
private _lethal = getNumber (_config >> "indirectHit") > 0 || {getNumber (_config >> "explosive") > 0};
private _gravity = if (isNumber (_config >> "coefGravity")) then {getNumber (_config >> "coefGravity")} else {1};
private _previous = _start;
private _impact = _start;
private _blocked = false;
for "_step" from 1 to 20 do {
    private _seconds = 0.2 * _step;
    private _point = _start vectorAdd (_velocity vectorMultiply _seconds);
    _point set [2,(_point select 2) - 4.905 * _gravity * _seconds * _seconds];
    private _hits = lineIntersectsSurfaces [_previous,_point,_unit,_projectile,true,1,"FIRE","GEOM"];
    if (_hits isNotEqualTo []) exitWith {
        _impact = _hits select 0 select 0;
        private _obstacle = _hits select 0 select 3;
        if (isNull _obstacle) then {_obstacle = _hits select 0 select 2};
        _blocked = !isNull _obstacle;
    };
    private _ground = getTerrainHeightASL _point;
    if ((_point select 2) <= _ground + 0.1) exitWith {_point set [2,_ground + 0.05]; _impact = _point};
    _impact = _point;
    _previous = _point;
};
if (_blocked) exitWith {[false,_impact,"trajectory-obstruction"]};
if (_lethal && {!([side group _unit,ASLToATL _impact,VCM_GRENADEFRIENDLY] call VCM_fnc_ArtillerySafe)}) exitWith {
    [false,_impact,"friendly-blast-area"]
};
[true,_impact,"clear"]
