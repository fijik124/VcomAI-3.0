params ["_group"];
private _run = _group getVariable ["VCM_RunId",[]];
(units _group) select {
    alive _x && {local _x} && {!([_x] call VCM_fnc_HumanControlled)} && {simulationEnabled _x} && {isNull objectParent _x} &&
    {canMove _x} && {lifeState _x != "INCAPACITATED"} && {_x checkAIFeature "PATH"} &&
    {!(_x getVariable ["VCM_MBUSY",false])} && {!(_x getVariable ["VCM_PatientBusy",false])} &&
    {!(_x getVariable ["VCM_DeployBusy",false])} && {_x getVariable ["VCM_MoveKey",[]] isEqualTo []} &&
    {_x getVariable ["VCM_TaskKey",[]] isEqualTo []}
    && {((_x getVariable ["VCM_Handlers",[[],[]]]) select 0) isEqualTo _run}
}
