params ["_group", "_key", ["_reason", "cancelled"]];
private _state = _group getVariable ["VCM_BoundState", []];
if (_state isEqualTo [] || {!((_state select 0) isEqualTo _key)}) exitWith {};
{[_x, _key] call VCM_fnc_ReleaseBoundUnit} forEach (_state select 1);
_group setVariable ["VCM_LastBound", [_reason, +(_state select 6)]];
_group setVariable ["VCM_BoundState", []];
