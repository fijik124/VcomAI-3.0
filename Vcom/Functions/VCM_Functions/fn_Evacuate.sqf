params ["_group","_plan"];
if (_plan isEqualTo [] || {!([_group] call VCM_fnc_TacticalReady)}) exitWith {false};
_plan params ["_rescuer","_patient","_cover","_enemy","_contact"];
private _support = ([_group] call VCM_fnc_TacticalUnits) - [_rescuer];
_support = _support select {!(_x getUnitTrait "Medic")};
_support = _support select [0,2];
_group setVariable ["VCM_EvacAfter",diag_tickTime + 60];
_patient setVariable ["VCM_PatientBusy",true,true];
private _key = [_group getVariable ["VCM_RunId",[]],1 + (_group getVariable ["VCM_TaskSerial",0])];
private _speed = getForcedSpeed _rescuer;
_group setVariable ["VCM_Evacuation",[_key,_rescuer,_patient,_speed],true];
_patient setVariable ["VCM_EvacPatient",[_group,_key,_rescuer,_speed],true];
_rescuer setVariable ["VCM_EvacRescuer",[_group,_key,_patient,_speed],true];
private _result = [_group,"evac",[
    [_support,[_rescuer],[getPosATL _patient],25,_contact],
    [_support,[_rescuer],[_cover],45,_contact,["attach",_rescuer,_patient]],
    [_support + [_rescuer],[],[],2,_contact,["detach",_rescuer,_patient]]
],_enemy,_contact] call VCM_fnc_RunTactical;
[_group,_key] call VCM_fnc_EvacRelease;
_result
