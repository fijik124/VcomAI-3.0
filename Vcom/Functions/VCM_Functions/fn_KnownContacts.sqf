/* Reuse a native contact query within one simulation frame; never carry stale reveal state across frames. */
params ["_observer"];
if (isNull _observer) exitWith {[]};
// Passengers use their platform's native sensor picture; share that query across its crew this frame.
private _group = group _observer;
_observer = vehicle _observer;
private _cached = _observer getVariable ["VCM_ContactFrame",[-1,[]]];
private _contacts = if (_cached select 0 == diag_frameNo) then {_cached select 1} else {
    private _native = _observer nearTargets 5000;
    _observer setVariable ["VCM_ContactFrame",[diag_frameNo,_native]];
    _native
};
private _reports = _group getVariable ["VCM_ScoutReports",[]];
if (!VCM_RECON || {_reports isEqualTo []}) exitWith {_contacts};
_contacts = +_contacts;
if (VCM_RECON) then {
    {
        _x params ["_target","_position","_stamp","_side","_type"];
        if (time - _stamp < 30 && {!isNull _target} && {alive _target} &&
            {_contacts findIf {_x select 4 == _target} < 0}) then {
            _contacts pushBack [+_position,_type,_side,0,_target,1];
        };
    } forEach _reports;
};
_contacts
