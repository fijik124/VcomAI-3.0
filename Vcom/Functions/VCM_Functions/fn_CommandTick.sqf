/* Runs in the existing owner utility tick. Revisions cancel stale tasks without transferring group ownership. */
params ["_group"];
private _revision = _group getVariable ["VCM_CommandRevision",0];
private _seen = _group getVariable ["VCM_AppliedCommand",[]];
if (_seen isEqualTo [] || {_seen select 0 != _revision}) then {
    if (_seen isNotEqualTo [] || {_revision > 0}) then {
        private _task = _group getVariable ["VCM_Task",[]];
        if (_task isNotEqualTo []) then {[_group,_task select 0,"commander-reset"] call VCM_fnc_EndTactical};
        private _bound = _group getVariable ["VCM_BoundState",[]];
        if (_bound isNotEqualTo []) then {[_group,_bound select 0,"commander-reset"] call VCM_fnc_EndFireMove};
        [_group] call VCM_fnc_ClearWaypoints;
        _group setVariable ["VCM_ObjectiveAfter",-1];
        _group setVariable ["VCM_FlankAfter",-1];
        _group setVariable ["VCM_NextTactic",0];
        {_x setVariable ["VCM_MoveKey",nil]} forEach ((units _group) select {local _x});
    };
    _group setVariable ["VCM_AppliedCommand",[_revision]];
};
private _reset = _group getVariable ["VCM_MemoryReset",[]];
if (_reset isNotEqualTo [] && {_reset select 0 != (_group getVariable ["VCM_AppliedMemoryReset",-1])}) then {
    _reset params ["_serial","_center","_radius"];
    private _memory = if (_center isEqualTo []) then {[]} else {
        (_group getVariable ["VCM_DangerMemory",[]]) select {(_x select 0) distance2D _center > _radius}
    };
    _group setVariable ["VCM_DangerMemory",_memory,true];
    _group setVariable ["VCM_AppliedMemoryReset",_serial];
};
private _profile = [_group] call VCM_fnc_Doctrine;
private _objective = if (VCM_COMMANDPOINTS) then {_group getVariable ["VCM_Objective",[]]} else {[]};
private _mission = (waypoints _group) findIf {(_x select 1) > 0} >= 0;
private _recon = VCM_RECON && {!_mission} && {!(_group getVariable ["VCM_NOFLANK",false])} &&
    {!(_group getVariable ["VCM_NOAUTOTACTICS",false])} &&
    {_profile == "recon" || {_objective isNotEqualTo [] && {_objective select 1 == "recon"}}} &&
    {time - (_group getVariable ["VCM_LastIncoming",-100]) >= 15} &&
    {(units _group) findIf {getSuppression _x >= 0.35} < 0};
if (_recon || {_group getVariable ["VCM_ReconPolicyActive",false]}) then {
{
    if (_recon && {local _x} && {alive _x} && {!([_x] call VCM_fnc_HumanControlled)}) then {
        if (_x getVariable ["VCM_ReconROE",[]] isEqualTo [] && {unitCombatMode _x in ["YELLOW","RED"]}) then {
            _x setVariable ["VCM_ReconROE",[unitCombatMode _x],true]; _x setUnitCombatMode "GREEN";
        };
    } else {[_x] call VCM_fnc_ReconRelease};
} forEach units _group;
};
if (_recon isNotEqualTo (_group getVariable ["VCM_ReconPolicyActive",false])) then {
    _group setVariable ["VCM_ReconPolicyActive",_recon,true];
};
private _formationState = _group getVariable ["VCM_DoctrineFormation",[]];
private _apply = _profile != "default" && {!_mission} && {!(_group getVariable ["VCM_DisableForm",false])};
if (_formationState isNotEqualTo [] && {!_apply || {_formationState select 2 != _profile}}) then {
    if (formation _group == _formationState select 1) then {_group setFormation (_formationState select 0)};
    _group setVariable ["VCM_DoctrineFormation",nil,true]; _formationState = [];
};
if (_apply && {_formationState isEqualTo []}) then {
    private _next = switch (_profile) do {case "recon": {"DIAMOND"}; case "defend": {"LINE"}; case "convoy": {"FILE"}; default {"WEDGE"}};
    _group setVariable ["VCM_DoctrineFormation",[formation _group,_next,_profile],true];
    _group setFormation _next;
};
if (_recon && {time >= (_group getVariable ["VCM_ReconAfter",-1])}) then {
    _group setVariable ["VCM_ReconAfter",time + VCM_RECONREPORT];
    private _reports = (([leader _group] call VCM_fnc_KnownContacts) select {
        private _target = _x select 4;
        !isNull _target && {alive _target} && {_group knowsAbout _target >= 1} &&
        {[side _group,_x select 2] call BIS_fnc_sideIsEnemy}
    }) apply {[_x select 4,+(_x select 0)]};
    _reports = _reports select [0,4];
    if (_reports isNotEqualTo []) then {
        private _request = [_group,_reports,player];
        if (isServer) then {_request call VCM_fnc_ReconPublish} else {_request remoteExecCall ["VCM_fnc_ReconReport",2]};
    };
};
[_group] call VCM_fnc_NightTick;
