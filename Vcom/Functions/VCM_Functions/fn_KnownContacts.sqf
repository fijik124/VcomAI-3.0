/* Reuse a native contact query within one simulation frame; never carry stale reveal state across frames. */
params ["_observer"];
if (isNull _observer) exitWith {[]};
// Passengers use their platform's native sensor picture; share that query across its crew this frame.
_observer = vehicle _observer;
private _cached = _observer getVariable ["VCM_ContactFrame",[-1,[]]];
if (_cached select 0 == diag_frameNo) exitWith {_cached select 1};
private _contacts = _observer nearTargets 5000;
_observer setVariable ["VCM_ContactFrame",[diag_frameNo,_contacts]];
_contacts
