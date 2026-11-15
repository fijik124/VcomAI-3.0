/* Real HC movement, command revision cancellation, handoff recovery and forged-request rejection. */
VCM_COMMANDPOINTS = true; VCM_RECON = true; VCM_DEFENSE = true; VCM_DOCTRINES = true;
VCM_COUNTERFLANK = false; VCM_POINTSCAN = 5;
private _doctrineGroup = createGroup [west,true];
_doctrineGroup setVariable ["VCM_NOAUTOTACTICS",true,true];
_doctrineGroup setVariable ["VCM_Skilldisable",true,true];
private _doctrineUnits = [];
for "_i" from 0 to 3 do {
    private _soldier = _doctrineGroup createUnit ["B_Soldier_F",[7500,7500 + _i * 5,0],[],0,"NONE"];
    _soldier allowDamage false; _doctrineUnits pushBack _soldier;
};
_doctrineGroup setCombatMode "GREEN";
_doctrineGroup call VCM_fnc_SquadExc;
private _position = [7465,7500,0];
private _assigned = [objNull,"point","recon",[_doctrineGroup],_position,0,10] call VCM_fnc_CommanderOrder;
[_assigned,"server assigns a recon point before transferring its squad"] call _assert;
[_doctrineGroup,_first,"recon squad to HC1"] call _transfer;
["doctrinePost",_doctrineGroup,"",[]] remoteExecCall ["VCM_test_fnc_Scenario",_first];
private _started = [{_doctrineGroup getVariable ["VCM_ObjectiveContext",[]] isNotEqualTo []},8] call _await;
[_started,"assigned recon point starts a native task on HC1"] call _assert;
private _moved = [{_doctrineUnits findIf {_x distance2D [7500,7500,0] > 18} >= 0},20] call _await;
[_moved,"HC observation task physically moves soldiers toward its assigned point"] call _assert;
private _pointId = (_doctrineGroup getVariable ["VCM_Objective",[]]) param [0,""];
[objNull,"restartPoint","",[],_position,0,10] call VCM_fnc_CommanderOrder;
private _cancelled = [{_doctrineGroup getVariable ["VCM_ObjectiveContext",[]] isEqualTo [] &&
    {_doctrineUnits findIf {_x getVariable ["VCM_TaskKey",[]] isNotEqualTo []} < 0}},6] call _await;
[_cancelled && {(_doctrineGroup getVariable ["VCM_Objective",[]]) param [0,""] == _pointId},
    "server restarts the HC task while retaining the assigned point"] call _assert;
private _before = _doctrineGroup getVariable ["VCM_Doctrine","default"];
["forgedCommander",_doctrineGroup,"",[]] remoteExecCall ["VCM_test_fnc_Scenario",_first];
sleep 0.6;
[_doctrineGroup getVariable ["VCM_Doctrine","default"] == _before,"headless-client commander request is rejected without an assigned curator"] call _assert;
["forgedCommander",_doctrineGroup,"",[true]] remoteExecCall ["VCM_test_fnc_Scenario",_first];
sleep 0.6;
[_doctrineGroup getVariable ["VCM_Doctrine","default"] == _before,"headless client cannot bypass curator checks with a null identity"] call _assert;
[objNull,"point","defend",[_doctrineGroup],[7450,7500,0],0,10] call VCM_fnc_CommanderOrder;
["doctrinePost",_doctrineGroup,"",[]] remoteExecCall ["VCM_test_fnc_Scenario",_first];
[{_doctrineGroup getVariable ["VCM_ObjectiveContext",[]] isNotEqualTo []},8] call _await;
private _oldKey = (_doctrineGroup getVariable ["VCM_ObjectiveContext",[]]) param [0,[]];
[_doctrineGroup,_second,"defense squad HC1 to HC2"] call _transfer;
private _state = [_second,"doctrine-handoff",[_doctrineGroup]] call _probe;
private _owned = (_state param [3,[]]) param [0,[]];
[count _owned > 6 && {_owned select 2 == 1} && {(_owned select 6 select 1) isNotEqualTo []} &&
    {(_owned select 6 select 2) isEqualTo []},"new HC retains the defense assignment and releases the inherited task context"] call _assert;
[count _owned > 5 && {(_owned select 5) findIf {_x select 9 isEqualTo _oldKey || {!(_x select 4)} || {!(_x select 10)}} < 0},
    "doctrine handoff restores native flags and clears the old task reservations"] call _assert;
["dangerMemory",_doctrineGroup,"",[]] remoteExecCall ["VCM_test_fnc_Scenario",_second];
[{_doctrineGroup getVariable ["VCM_DangerMemory",[]] isNotEqualTo []},4] call _await;
[objNull,"resetDanger","",[_doctrineGroup],getPosATL leader _doctrineGroup,0,50] call VCM_fnc_CommanderOrder;
private _forgot = [{_doctrineGroup getVariable ["VCM_DangerMemory",[]] isEqualTo []},4] call _await;
[_forgot,"server's point-scoped memory reset reaches the HC owner"] call _assert;
private _reportEnemy = _opfor createUnit ["O_Soldier_F",[7600,7500,0],[],0,"NONE"];
_reportEnemy disableAI "ALL"; _reportEnemy allowDamage false;
private _peerGroup = createGroup [west,true];
_peerGroup setVariable ["VCM_NOAUTOTACTICS",true,true];
private _peer = _peerGroup createUnit ["B_Soldier_F",[7400,7600,0],[],0,"NONE"];
_peer allowDamage false;
["reconReport",_doctrineGroup,"",[_reportEnemy,_peerGroup]] remoteExecCall ["VCM_test_fnc_Scenario",_second];
sleep 0.6;
[_peerGroup getVariable ["VCM_LastReconReport",[]] isEqualTo [],"HC cannot submit a radio report claiming another owner's squad"] call _assert;
["reconReport",_doctrineGroup,"",[_reportEnemy,_peerGroup,true]] remoteExecCall ["VCM_test_fnc_Scenario",_second];
sleep 0.6;
[_peerGroup getVariable ["VCM_LastReconReport",[]] isEqualTo [],"HC cannot submit a server-owned squad's report with a null identity"] call _assert;
["reconReport",_doctrineGroup,"",[_reportEnemy]] remoteExecCall ["VCM_test_fnc_Scenario",_second];
private _reported = [{_doctrineGroup getVariable ["VCM_LastReconReport",[]] isNotEqualTo []},6] call _await;
[_reported,"HC radio report is accepted for its actual source squad"] call _assert;
[objNull,"resetGroup","",[_doctrineGroup],getPosATL leader _doctrineGroup,0,10] call VCM_fnc_CommanderOrder;
private _cleared = [{_doctrineGroup getVariable ["VCM_Objective",[]] isEqualTo [] &&
    {_doctrineGroup getVariable ["VCM_ObjectiveContext",[]] isEqualTo []}},5] call _await;
[_cleared && {groupOwner _doctrineGroup == _second},"squad reset clears the remote assignment without transferring ownership"] call _assert;
_doctrineGroup setVariable ["Vcm_Disable",true,true]; sleep 0.5;
_peerGroup setVariable ["Vcm_Disable",true,true];
{deleteVehicle _x} forEach (_doctrineUnits + [_reportEnemy,_peer]);
deleteGroup _doctrineGroup; deleteGroup _peerGroup;
