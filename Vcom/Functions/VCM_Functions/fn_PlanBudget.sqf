/* Soft owner/frame budget applies to planning only; cleanup, safety and binding never wait for it. */
params ["_group"];
private _interval = VCM_NEARTICK;
if (VCM_ADAPTIVEBUDGET) then {
    private _budget = missionNamespace getVariable ["VCM_FrameBudget",[-1,0]];
    if (_budget select 0 != diag_frameNo) then {_budget = [diag_frameNo,0]; VCM_FrameBudget = _budget};
    if (_budget select 1 >= VCM_BUDGETMS) exitWith {_interval = -1};
    private _leader = leader _group;
    private _enemy = _leader call VCM_fnc_ClstEmy;
    private _contact = [_leader,_enemy] call VCM_fnc_ContactPosition;
    if (diag_tickTime >= (missionNamespace getVariable ["VCM_PlayerCacheAfter",-1])) then {
        VCM_PlanningPlayers = allPlayers select {!(_x isKindOf "HeadlessClient_F")};
        VCM_PlayerCacheAfter = diag_tickTime + 0.5;
    };
    private _players = missionNamespace getVariable ["VCM_PlanningPlayers",[]];
    private _active = _players findIf {_x distance2D _leader < VCM_ACTIVEDISTANCE} >= 0 ||
        {_contact isNotEqualTo [] && {_leader distance2D _contact < 800}} ||
        {_group getVariable ["VCM_Committed",false]};
    if (!_active) then {_interval = VCM_FARTICK};
};
if (_interval >= 0) then {_group setVariable ["VCM_PlanInterval",_interval]};
_interval
