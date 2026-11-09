/* Return [feet ATL, roofed]. A walkable floor and body clearance are required. */
params ["_building","_point",["_requireRoof",true]];
private _start = ATLToASL (_point vectorAdd [0,0,1]);
private _end = ATLToASL (_point vectorAdd [0,0,-1.5]);
private _hits = (lineIntersectsSurfaces [_start,_end,objNull,objNull,true,12,"ROADWAY","GEOM",false]) select {
    private _object = _x select 3;
    if (isNull _object) then {_object = _x select 2};
    !(_object isKindOf "Man") && {!(_object isKindOf "LandVehicle")}
};
if (_hits isEqualTo [] || {((_hits select 0 select 1) select 2) < 0.7}) exitWith {[]};
private _floor = ASLToATL ((_hits select 0 select 0) vectorAdd [0,0,0.05]);
if (abs ((_floor select 2) - (_point select 2)) > 1.3) exitWith {[]};
private _foot = ATLToASL _floor;
private _roofHits = (lineIntersectsSurfaces [_foot vectorAdd [0,0,0.15],_foot vectorAdd [0,0,5],objNull,objNull,true,12,"GEOM","NONE",false]) select {
    private _object = _x select 3;
    if (isNull _object) then {_object = _x select 2};
    !(_object isKindOf "Man") && {!(_object isKindOf "LandVehicle")}
};
private _roofed = _roofHits isNotEqualTo [] && {(_roofHits select 0 select 3) == _building || {(_roofHits select 0 select 2) == _building}};
if (_roofHits isNotEqualTo [] && {(_roofHits select 0 select 0) distance _foot < 1.7}) exitWith {[]};
if (_requireRoof && {!_roofed}) exitWith {[]};
private _queries = [];
{
    private _center = _foot vectorAdd [0,0,1];
    _queries pushBack [_center,_center vectorAdd _x,objNull,objNull,true,12,"GEOM","NONE",false];
} forEach [[0.3,0,0],[-0.3,0,0],[0,0.3,0],[0,-0.3,0]];
if ((lineIntersectsSurfaces [_queries]) findIf {_x findIf {
    private _object = _x select 3;
    if (isNull _object) then {_object = _x select 2};
    !(_object isKindOf "Man") && {!(_object isKindOf "LandVehicle")}
} >= 0} >= 0) exitWith {[]};
[_floor,_roofed]
