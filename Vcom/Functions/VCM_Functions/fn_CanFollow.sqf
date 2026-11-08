/* A delayed legacy action must not overwrite a newer coordinated order. */
params ["_unit","_group","_run"];
[_unit,_group,_run] call VCM_fnc_ActionValid && {_unit != leader _group} &&
{_unit getVariable ["VCM_TaskKey",[]] isEqualTo []} && {_unit getVariable ["VCM_BoundKey",[]] isEqualTo []} &&
{_unit getVariable ["VCM_MoveKey",[]] isEqualTo []}
