/* Bounded flight away from heard shots, or a brief prone freeze followed by another escape attempt. */
params ["_unit"];
if (!local _unit) exitWith {};
private _state = _unit getVariable ["VCM_CivilianState",[]];
private _threat = _unit getVariable ["VCM_CivilianThreat",[]];
if (!([_unit] call VCM_fnc_CivilianEligible) || {_threat isEqualTo []} || {time >= (_threat select 1)} ||
    {_state isNotEqualTo [] && {group _unit != _state select 0}}) exitWith {[_unit] call VCM_fnc_CivilianRelease};
if (_state isEqualTo []) then {
    private _features = ["TARGET","AUTOTARGET","AUTOCOMBAT","FSM","PATH"] apply {[_x,_unit checkAIFeature _x]};
    _state = [group _unit,_features,unitPos _unit,getForcedSpeed _unit,behaviour _unit,"",0,[],getPosATL _unit,time,clientOwner];
    {if (_x select 1 && {_x select 0 != "PATH"}) then {_unit disableAI (_x select 0)}} forEach _features;
    _unit doTarget objNull;
    _unit doWatch objNull;
    _unit setCombatBehaviour "CARELESS";
    VCM_ReactionUnits pushBackUnique _unit;
};
private _mode = _state select 5;
private _destination = _state select 7;
// The engine resets local AI flags and forced speed during an ownership transfer.
if ((_state param [10,-1]) != clientOwner) then {
    _state set [10,clientOwner];
    {_unit disableAI _x} forEach ["TARGET","AUTOTARGET","AUTOCOMBAT","FSM"];
    _unit setCombatBehaviour "CARELESS";
    if (_mode == "freeze") then {
        _unit disableAI "PATH";
        _unit setUnitPos "DOWN";
        _unit forceSpeed 0;
        doStop _unit;
    };
    if (_mode == "flee") then {
        _unit enableAI "PATH";
        _unit setUnitPos "UP";
        _unit forceSpeed (if (_state select 3 < 0) then {6} else {6 min (_state select 3)});
        _unit doMove _destination;
    };
};
private _stuck = false;
if (_mode == "flee") then {
    if (_unit distance2D (_state select 8) > 1) then {_state set [8,getPosATL _unit]; _state set [9,time]};
    _stuck = time - (_state select 9) >= 6;
};
if (time >= (_state select 6) || {_mode == "flee" && {_stuck || {_unit distance2D _destination < 4}}}) then {
    // Do not freeze repeatedly while an escape route is available.
    private _freeze = _mode == "" && {random 1 < VCM_CIVILIANFREEZE};
    _destination = [];
    if (!_freeze) then {
        private _away = (_threat select 0) getDir _unit;
        for "_attempt" from 0 to 5 do {
            private _angle = _away + ([-55,-30,0,30,55,0] select _attempt);
            private _candidate = (_unit getPos [VCM_CIVILIANESCAPE * (0.7 + random 0.3),_angle]) findEmptyPosition [0,5,typeOf _unit];
            if (_candidate isNotEqualTo [] && {!surfaceIsWater _candidate} &&
                {_candidate distance2D (_threat select 0) > (_unit distance2D (_threat select 0)) + 5}) exitWith {_destination = _candidate};
        };
        _freeze = _destination isEqualTo [];
    };
    if (_freeze) then {
        _state set [5,"freeze"];
        _state set [6,time + 4 + random 4];
        doStop _unit;
        _unit setUnitPos "DOWN";
        _unit forceSpeed 0;
        _unit disableAI "PATH";
    } else {
        _state set [5,"flee"];
        _state set [6,time + 12];
        _unit enableAI "PATH";
        _unit setUnitPos "UP";
        private _speed = if (_state select 3 < 0) then {6} else {6 min (_state select 3)};
        _unit forceSpeed _speed;
        _unit doMove _destination;
    };
    _state set [7,_destination];
    _state set [8,getPosATL _unit]; _state set [9,time];
};
_unit setVariable ["VCM_CivilianState",_state,true];
