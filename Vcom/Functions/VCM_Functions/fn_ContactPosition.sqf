/* nearTargets supplies the observer's estimated position, not the target's live position. */
params ["_observer", "_target"];
if (isNull _observer || {isNull _target}) exitWith {[]};
private _cached = _observer getVariable ["VCM_ContactPositionFrame",[-1,objNull,[]]];
if (_cached select 0 == diag_frameNo && {(_cached select 1) isEqualTo _target}) exitWith {+(_cached select 2)};
private _contacts = [_observer] call VCM_fnc_KnownContacts;
private _index = _contacts findIf {(_x select 4) isEqualTo _target};
private _position = [];
if (_index >= 0) then {_position = +(_contacts select _index select 0)};
_observer setVariable ["VCM_ContactPositionFrame",[diag_frameNo,_target,_position]];
_position
