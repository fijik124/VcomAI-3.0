private _group = _this;
if (!([_group] call VCM_fnc_GroupEnabled) || {_group in VcmAI_ActiveList}) exitWith {};
[_group] call VCM_fnc_RestoreCombat;
VCM_RunSerial = VCM_RunSerial + 1;
private _run = [clientOwner, VCM_RunSerial];
_group setVariable ["VCM_RunId", _run];
_group setVariable ["VCM_BoundUnits", []];
VcmAI_ActiveList pushBackUnique _group;
private _fsm = _group execFSM "Vcom\FSMS\fn_SQUADBEH.fsm";
[_group, _run, _fsm] spawn {
    params ["_group", "_run", "_fsm"];
    private _units = [];
    waitUntil {
        sleep 0.25;
        if (_run isEqualTo (_group getVariable ["VCM_RunId", []])) then {_units = +(_group getVariable ["VCM_BoundUnits", []])};
        completedFSM _fsm || {!([_group] call VCM_fnc_GroupEnabled)} ||
        {!(_run isEqualTo (_group getVariable ["VCM_RunId", []]))}
    };
    [_group, _run, _units] call VCM_fnc_CleanupGroup;
};
