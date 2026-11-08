/* Mission orders and existing committed tasks take precedence over autonomous tactics. */
params ["_group"];
[_group] call VCM_fnc_GroupEnabled && {simulationEnabled leader _group} &&
{!(_group getVariable ["VCM_NOFLANK",false])} && {!(_group getVariable ["VCM_GarrisonBusy",false])} &&
{!(_group getVariable ["VCM_MOVE2SUP",false])} && {_group getVariable ["VCM_Task",[]] isEqualTo []} &&
{_group getVariable ["VCM_BoundState",[]] isEqualTo []} &&
{(units _group) findIf {[_x] call VCM_fnc_HumanControlled} < 0} && {(waypoints _group) findIf {(_x select 1) > 0} < 0}
