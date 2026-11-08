/* Server-side eligibility does not assume the group is local. Owners revalidate before acting. */
params ["_group"];
!isNull _group && {alive leader _group} && {side _group in VCM_SIDEENABLED} &&
{!(isPlayer leader _group)} && {!(_group getVariable ["Vcm_Disable",false])} &&
{!(_group getVariable ["VCM_NOFLANK",false])} && {!(_group getVariable ["VCM_NORESCUE",false])} &&
{!(_group getVariable ["VCM_Committed",false])} &&
{time >= ((_group getVariable ["VCM_CoordMission",[]]) param [2,-1])} &&
{(units _group) findIf {isPlayer _x} < 0} &&
{(waypoints _group) findIf {(_x select 1) > 0} < 0}
