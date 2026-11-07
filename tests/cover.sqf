/* Native geometry and movement checks; called in regression.sqf's scheduled context. */
private _saved = [VCM_COVERSEARCH, VCM_FIREMOVEMENT, VCM_ADVANCEDMOVEMENT];
VCM_COVERSEARCH = true;
VCM_FIREMOVEMENT = false;
VCM_ADVANCEDMOVEMENT = false;
private _group = createGroup [west, true];
_group setVariable ["VCM_Skilldisable", true];
private _unit = _group createUnit ["B_Soldier_F", [7000,7000,0], [], 0, "NONE"];
_unit setPosATL [7000,7000,0];
_unit enableSimulationGlobal false;
_unit allowDamage false;
private _threat = [7200,7000,0];
private _coveredPoint = [7010,7004,0];
private _exposedPoint = [7010,7000,0];
private _features = [_unit checkAIFeature "PATH", _unit checkAIFeature "TARGET", _unit checkAIFeature "AUTOCOMBAT"];
private _snapshot = call VCM_fnc_SettingsSnapshot;
[(_snapshot findIf {(_x select 0) == "VCM_COVERSEARCH" && {(_x select 1) isEqualTo true}}) >= 0,
    "cover setting is included in the typed settings snapshot"] call _assert;
private _open = [_unit, _threat, 10] call VCM_fnc_BoundPosition;
[count _open == 3 && {_open distance2D _exposedPoint < 1}, "open ground retains the direct advance"] call _assert;
[([_unit, _exposedPoint, _threat] call VCM_fnc_CoverProtection) == 0, "open ground has no physical cover score"] call _assert;
[([objNull, _threat, 10] call VCM_fnc_BoundPosition) isEqualTo [], "cover search rejects a null soldier"] call _assert;
[([_unit, [7045,7000,0], 40] call VCM_fnc_BoundPosition) isEqualTo [], "cover search does not advance inside the assault exclusion distance"] call _assert;

private _wall = createVehicle ["Land_CncWall4_F", [7013,7004,0], [], 0, "CAN_COLLIDE"];
_wall setDir 90;
_wall setPosATL [7013,7004,0];
sleep 0.2;
private _protectedScore = [_unit, _coveredPoint, _threat] call VCM_fnc_CoverProtection;
private _openScore = [_unit, _exposedPoint, _threat] call VCM_fnc_CoverProtection;
[_protectedScore > _openScore, "concrete geometry protects a flank position against the remembered threat"] call _assert;
[([_unit, _coveredPoint, [6800,7004,0]] call VCM_fnc_CoverProtection) == 0,
    "the same wall gives no cover against a threat on the opposite side"] call _assert;
private _selected = [_unit, _threat, 10] call VCM_fnc_BoundPosition;
[count _selected == 3 && {([_unit, _selected, _threat] call VCM_fnc_CoverProtection) > _openScore},
    "team advance chooses physical cover over exposed direct ground"] call _assert;
[count _selected == 3 && {_unit distance2D _selected <= 18} && {_selected distance2D _threat >= 50},
    "cover choice stays within the movement and contact-distance limits"] call _assert;
VCM_COVERSEARCH = false;
private _disabled = [_unit, _threat, 10] call VCM_fnc_BoundPosition;
[count _disabled == 3 && {_disabled distance2D _open < 0.1}, "disabling cover preference restores the direct choice"] call _assert;
VCM_COVERSEARCH = true;
private _second = [_unit, _threat, 10, [_selected]] call VCM_fnc_BoundPosition;
[count _second == 3 && {_second distance2D _selected >= 3}, "reserved destinations keep teammates at least three meters apart"] call _assert;
private _blocked = [[7010,7000,0], [7010,6996,0], [7010,7004,0], [7010,6992,0], [7010,7008,0],
    [7006,7000,0], [7006,6996,0], [7006,7004,0]];
[([_unit, _threat, 10, _blocked] call VCM_fnc_BoundPosition) isEqualTo [],
    "fully reserved search area returns no route instead of stacking soldiers"] call _assert;

// Exercise the chosen position through native pathfinding, rather than teleporting the soldier there.
_unit enableSimulationGlobal true;
_unit setBehaviour "AWARE";
_group call VCM_fnc_SquadExc;
sleep 0.5;
private _arrived = false;
if (_selected isNotEqualTo []) then {_arrived = [_unit, _selected, 20] call VCM_fnc_MoveTo};
[_arrived && {_unit distance2D [7000,7000,0] > 5}, "native pathfinding physically reaches the selected cover destination"] call _assert;
[_features isEqualTo [_unit checkAIFeature "PATH", _unit checkAIFeature "TARGET", _unit checkAIFeature "AUTOCOMBAT"],
    "cover search and movement preserve native AI features"] call _assert;
_unit enableSimulationGlobal false;
_unit setPosATL [7000,7000,0];

_wall setPosATL [7035,7004,0];
sleep 0.2;
[([_unit, _coveredPoint, _threat] call VCM_fnc_CoverProtection) == 0,
    "distant obstruction does not count as nearby cover"] call _assert;
deleteVehicle _wall;
private _vehicle = createVehicle ["B_MRAP_01_F", [7014,7004,0], [], 0, "CAN_COLLIDE"];
_vehicle setPosATL [7014,7004,0];
sleep 0.2;
[([_unit, _coveredPoint, _threat] call VCM_fnc_CoverProtection) == 0,
    "vehicles do not count as dependable static cover"] call _assert;
deleteVehicle _vehicle;
sleep 0.2;
private _started = diag_tickTime;
for "_i" from 1 to 20 do {[_unit, _threat, 10] call VCM_fnc_BoundPosition};
diag_log format ["VCM_COVER_RESULT: covered=%1; exposed=%2; selected=%3; 20 searches=%4 ms",
    _protectedScore, _openScore, _selected, 1000 * (diag_tickTime - _started)];
_group setVariable ["Vcm_Disable", true];
sleep 0.5;
deleteVehicle _unit;
deleteGroup _group;
_saved params ["_cover", "_fire", "_advanced"];
VCM_COVERSEARCH = _cover;
VCM_FIREMOVEMENT = _fire;
VCM_ADVANCEDMOVEMENT = _advanced;
