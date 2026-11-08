/* Run the full casualty approach/attach/move/detach task against real cover geometry. */
private _group = createGroup [west,true];
_group setVariable ["VCM_Skilldisable",true];
_group setVariable ["VCM_NOAUTOTACTICS",true];
private _actors = [];
{
    private _actor = _group createUnit ["B_Soldier_F",_x,[],0,"NONE"];
    _actor setPosATL _x;
    _actor allowDamage false;
    _actors pushBack _actor;
} forEach [[12601,12600,0],[12600,12600,0],[12600,12608,0]];
private _patient = _actors select 1;
private _enemyGroup = createGroup [east,true];
_enemyGroup setVariable ["Vcm_Disable",true];
private _enemy = _enemyGroup createUnit ["O_Soldier_F",[12800,12600,0],[],0,"NONE"];
_enemy disableAI "ALL";
_enemy allowDamage false;
private _wall = createVehicle ["Land_CncWall4_F",[12594,12600,0],[],0,"CAN_COLLIDE"];
_wall setDir 90;
_group setCombatMode "GREEN";
_group reveal [_enemy,4];
_group call VCM_fnc_SquadExc;
private _aceOpt = VCM_ACECASEVAC;
VCM_ACECASEVAC = true;
sleep 1.5;
_group reveal [_enemy,4];
private _readyUntil = diag_tickTime + 6;
waitUntil {sleep 0.1;
    count ([_group] call VCM_fnc_TacticalUnits) >= 2 &&
    {([leader _group,_enemy] call VCM_fnc_ContactPosition) isNotEqualTo []} || {diag_tickTime >= _readyUntil}
};
_patient setUnconscious true;
sleep 0.2;
private _plan = [_group] call VCM_fnc_EvacPlan;
diag_log format ["VCM_EVAC_PLAN: plan=%1 ready=%2 actors=%3 contact=%4 medical=%5 optIn=%6",
    _plan,[_group] call VCM_fnc_TacticalReady,
    _actors apply {[local _x,lifeState _x,_x getVariable ["ACE_isUnconscious",false],_x getVariable ["VCM_PatientBusy",false],_x getVariable ["VCM_Handlers",[]],getPosATL _x]},
    [leader _group,_enemy] call VCM_fnc_ContactPosition,VCM_MEDICALACTIVE,VCM_ACECASEVAC];
[_plan isNotEqualTo [] && {_plan select 1 == _patient},"casualty planner selects an unconscious squadmate and nearby physical cover"] call _assert;
if (_plan isNotEqualTo []) then {
    private _point = _plan select 2;
    private _contact = _plan select 4;
    [([_plan select 0,_point,_contact] call VCM_fnc_CoverProtection) >
        ([_plan select 0,getPosATL _patient,_contact] call VCM_fnc_CoverProtection),"evacuation destination improves physical protection against the known threat"] call _assert;
    private _start = getPosATL _patient;
    private _job = [_group,_plan] spawn VCM_fnc_Evacuate;
    private _deadline = diag_tickTime + 75;
    waitUntil {sleep 0.25; scriptDone _job || {diag_tickTime > _deadline}};
    private _last = _group getVariable ["VCM_LastTask",[]];
    diag_log format ["VCM_EVAC_RESULT: last=%1 patient=%2 destination=%3 attached=%4 detail=%5",_last,getPosATL _patient,_point,attachedTo _patient,_group getVariable ["VCM_LastTaskDetail",[]]];
    [_last param [1,""] == "completed" && {_patient distance2D _point < 4} && {_patient distance2D _start > 3},"full evacuation task physically delivers the casualty toward selected cover"] call _assert;
    [isNull attachedTo _patient && {lifeState _patient == "INCAPACITATED"} &&
        {_group getVariable ["VCM_Evacuation",[]] isEqualTo []},"completed evacuation releases attachments without healing or waking the patient"] call _assert;
};
VCM_ACECASEVAC = _aceOpt;
_group setVariable ["Vcm_Disable",true];
sleep 0.5;
{deleteVehicle _x} forEach (_actors + [_enemy,_wall]);
deleteGroup _group;
deleteGroup _enemyGroup;
