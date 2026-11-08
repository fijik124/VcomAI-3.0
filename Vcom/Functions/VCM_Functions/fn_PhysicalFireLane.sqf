/* Physical geometry, independently of visibility through glass or foliage. Positions are ASL. */
params ["_start", "_end", ["_ignore", objNull], ["_target", objNull]];
if (_start distance _end < 0.1) exitWith {true};
!terrainIntersectASL [_start, _end] && {
    (lineIntersectsSurfaces [_start, _end, _ignore, _target, true, 1, "FIRE", "NONE"]) isEqualTo []
}
