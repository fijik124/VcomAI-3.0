params ["_group", "_run", ["_units", []]];
private _current = _run isEqualTo (_group getVariable ["VCM_RunId", []]);
private _task = _group getVariable ["VCM_Task",[]];
if (_task isNotEqualTo [] && {(_task select 0 select 0) isEqualTo _run}) then {[_group,_task select 0] call VCM_fnc_EndTactical};
private _bound = _group getVariable ["VCM_BoundState", []];
if (_bound isNotEqualTo [] && {(_bound select 0 select 0) isEqualTo _run}) then {
    [_group, _bound select 0, "cancelled"] call VCM_fnc_EndFireMove;
};
if (_units isEqualTo []) then {_units = _group getVariable ["VCM_BoundUnits", []]};
{
    private _unit = _x;
    private _saved = _unit getVariable ["VCM_Handlers", [[], []]];
    if ((_saved select 0) isEqualTo _run) then {
        [_unit] call VCM_fnc_ReleaseUnitState;
        {_unit removeEventHandler _x} forEach (_saved select 1);
        _unit setVariable ["VCM_Handlers", nil];
    };
    if (local _unit && {_current} && {group _unit isEqualTo _group} && {(_saved select 0) isEqualTo _run}) then {
        private _stance = _unit getVariable ["VCM_HitStance", ""];
        if (_stance != "") then {
            _unit setUnitPos _stance;
            _unit setVariable ["VCM_HitStance", nil, true];
        };
        _unit setVariable ["VCM_MBUSY", false];
        _unit setVariable ["VCM_PatientBusy", false];
        _unit setVariable ["VCM_DeployBusy", false];
        _unit setVariable ["VCM_MoveKey", nil];
        if (alive _unit && {!isPlayer _unit} && {_unit != leader _group}) then {_unit doFollow leader _group};
    };
} forEach _units;
if (!_current) exitWith {
    if (isNull _group) then {VcmAI_ActiveList = VcmAI_ActiveList - [_group]};
};
[_group] call VCM_fnc_RestoreCombat;
_group setVariable ["VCM_BoundUnits", []];
_group setVariable ["VCM_GarrisonBusy", false];
if (local _group) then {
    _group setVariable ["VCM_MOVE2SUP",false,true];
    _group setVariable ["VCM_Committed",false,true];
};
_group setVariable ["VCM_RunId", []];
VcmAI_ActiveList = VcmAI_ActiveList - [_group];
