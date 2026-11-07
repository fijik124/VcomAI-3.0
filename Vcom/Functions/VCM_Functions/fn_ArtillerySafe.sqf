params ["_side", "_position", ["_radius", 100]];
// Include civilians, allies, the requesting group and the firing group's own soldiers.
((_position nearEntities [["Man", "LandVehicle", "Air", "Ship"], _radius]) findIf {
    alive _x && {!([_side, side _x] call BIS_fnc_sideIsEnemy)}
}) < 0
