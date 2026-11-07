params [["_unit", objNull, [objNull]], ["_animation", "", [""]]];
if (isNull _unit) exitWith {};
if (isRemoteExecuted && {remoteExecutedOwner != 2} && {remoteExecutedOwner != owner _unit}) exitWith {};
if (_animation != "AinvPknlMstpSnonWnonDnon_Putdown_AmovPknlMstpSnonWnonDnon") exitWith {};
_unit playMoveNow _animation;
