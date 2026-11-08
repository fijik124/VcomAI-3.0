params ["_unit", "_group", "_run"];
[_unit, _group, _run] call VCM_fnc_ActionValid && {simulationEnabled _unit} &&
{isNull objectParent _unit} && {lifeState _unit != "INCAPACITATED"} && {canMove _unit} &&
{damage _unit < 0.4} && {!(_unit getUnitTrait "Medic")} && {_unit checkAIFeature "PATH"} &&
{unitCombatMode _unit in ["YELLOW", "RED"]} && {getSuppression _unit < 0.7} &&
{primaryWeapon _unit != ""} && {_unit ammo primaryWeapon _unit > 0} &&
{!(_unit getVariable ["VCM_MBUSY", false])} && {!(_unit getVariable ["VCM_PatientBusy", false])} &&
{!(_unit getVariable ["VCM_DeployBusy", false])}
&& {_unit getVariable ["VCM_MoveKey", []] isEqualTo []}
&& {_unit getVariable ["VCM_TaskKey", []] isEqualTo []}
&& {((_unit getVariable ["VCM_Handlers",[[],[]]]) select 0) isEqualTo _run}
