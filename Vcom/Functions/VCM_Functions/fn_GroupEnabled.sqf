/* Whether this machine may issue VCOM orders to a group. */
params [["_group", grpNull, [grpNull]]];
!isNull _group && {local _group} && {missionNamespace getVariable ["Vcm_ActivateAI", false]} &&
{!(_group getVariable ["Vcm_Disable", false])} && {side _group in VCM_SIDEENABLED} &&
{!isPlayer leader _group} && {(units _group) findIf {alive _x} >= 0}
