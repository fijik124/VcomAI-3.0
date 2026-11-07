params ["_group"];
private _run = _group getVariable ["VCM_RunId", []];
private _bound = _group getVariable ["VCM_BoundUnits", []];
// Units can leave a living group; detach only handlers owned by this run.
{
    private _unit = _x;
    private _saved = _unit getVariable ["VCM_Handlers", [[], []]];
    if ((_saved select 0) isEqualTo _run) then {
        {_unit removeEventHandler _x} forEach (_saved select 1);
        _unit setVariable ["VCM_Handlers", nil];
    };
} forEach (_bound select {group _x != _group || {isPlayer _x} || {!local _x} || {!alive _x}});
_bound = _bound select {group _x == _group && {!isPlayer _x} && {local _x} && {alive _x}};
{
    private _unit = _x;
    if (local _unit && {alive _unit} && {!isPlayer _unit} && {!(_unit in _bound)}) then {
        // A joined unit may still carry this machine's previous group's handlers.
        private _previous = _unit getVariable ["VCM_Handlers", [[], []]];
        {_unit removeEventHandler _x} forEach (_previous select 1);
        _unit setVariable ["VCM_MoveKey", nil];
        private _boundKey = _unit getVariable ["VCM_BoundKey", []];
        if (_boundKey isNotEqualTo []) then {[_unit, _boundKey] call VCM_fnc_ReleaseBoundUnit};
        private _stance = _unit getVariable ["VCM_HitStance", ""];
        if (_stance != "") then {
            _unit setUnitPos _stance;
            _unit setVariable ["VCM_HitStance", nil, true];
        };
        private _handlers = [];
        _handlers pushBack ["Killed", _unit addEventHandler ["Killed", {_this spawn VCM_fnc_ClstWarn}]];
        _handlers pushBack ["Fired", _unit addEventHandler ["Fired", {_this call VCM_fnc_HearingAids}]];
        _handlers pushBack ["Hit", _unit addEventHandler ["Hit", {_this call VCM_fnc_AIHIT}]];
        _unit setVariable ["VCM_Handlers", [_run, _handlers]];
        _bound pushBack _unit;
    };
} forEach units _group;
_group setVariable ["VCM_BoundUnits", _bound];
