/* nearTargets supplies the observer's estimated position, not the target's live position. */
params ["_observer", "_target"];
if (isNull _observer || {isNull _target}) exitWith {[]};
private _contacts = (_observer nearTargets 5000) select {(_x select 4) isEqualTo _target};
if (_contacts isEqualTo []) exitWith {[]};
+(_contacts select 0 select 0)
