/* Server arbitrates fixed support requests across AI owners. No code or client-selected recipients. */
if (!isServer || {!Vcm_ActivateAI}) exitWith {false};
params [["_caller",grpNull,[grpNull]], ["_enemy",objNull,[objNull]], ["_position",[],[[]]],
    ["_kind","",[""]], ["_identity",objNull,[objNull]], ["_quality",0,[0]]];
if (isNull _caller || {!alive leader _caller} || {isNull _enemy} || {!alive _enemy} || {!(_kind in ["reinforcement","artillery"])} ||
    {count _position != 3} || {_position findIf {!(_x isEqualType 0) || {!finite _x}} >= 0} ||
    {!finite _quality} || {leader _caller distance2D _position > 5000} ||
    {isPlayer leader _caller} || {_caller getVariable ["Vcm_Disable",false]} ||
    {!(side _caller in VCM_SIDEENABLED)} || {!([side _caller,side group _enemy] call BIS_fnc_sideIsEnemy)}) exitWith {false};
private _owner = groupOwner _caller;
private _sender = remoteExecutedOwner;
if (_sender > 0 && {_sender != _owner}) exitWith {false};
if (_sender == 0 && {_owner != 2} && {isNull _identity || {!(_identity isKindOf "HeadlessClient_F")} || {owner _identity != _owner}}) exitWith {false};
if (isNil "VCM_SupportTimes") then {VCM_SupportTimes = createHashMap};
if (diag_tickTime > (missionNamespace getVariable ["VCM_SupportSweep",-1])) then {
    {if (VCM_SupportTimes get _x < diag_tickTime) then {VCM_SupportTimes deleteAt _x}} forEach keys VCM_SupportTimes;
    VCM_SupportSweep = diag_tickTime + 60;
};
private _callerKey = format ["caller:%1:%2",netId _caller,_kind];
if (diag_tickTime < (VCM_SupportTimes getOrDefault [_callerKey,-1])) exitWith {false};
VCM_SupportTimes set [_callerKey,diag_tickTime + 3];
private _key = format ["%1:%2",side _caller,_kind];
if (diag_tickTime < (VCM_SupportTimes getOrDefault [_key,-1])) exitWith {false};
private _issued = 0;
if (_kind == "reinforcement" && {VCM_CROSSOWNER_SUPPORT} && {!(_caller getVariable ["VCM_TOUGHSQUAD",false])}) then {
    private _candidates = allGroups select {
        _x != _caller && {side _x in VCM_SIDEENABLED} && {alive leader _x} && {!isPlayer leader _x} &&
        {isNull objectParent leader _x} &&
        {leader _x distance2D leader _caller <= VCM_WARNDIST} &&
        {[side _caller,side _x] call BIS_fnc_sideIsFriendly} &&
        {!(_x getVariable ["Vcm_Disable",false])} && {!(_x getVariable ["VCM_NORESCUE",false])} &&
        {!(_x getVariable ["VCM_NOFLANK",false])} && {!(_x getVariable ["VCM_Committed",false])} &&
        {!(_x getVariable ["VCM_MOVE2SUP",false])} && {(waypoints _x) findIf {(_x select 1) > 0} < 0}
    };
    _candidates = [_candidates,[],{leader _x distance2D leader _caller},"ASCEND"] call BIS_fnc_sortBy;
    {
        if (_issued >= 2) exitWith {};
        private _request = [diag_tickTime,netId _caller,_issued];
        if (local _x) then {[_x,_position,_request] spawn VCM_fnc_SupportAssign} else {
            [_x,_position,_request] remoteExecCall ["VCM_fnc_SupportAssign",groupOwner _x];
        };
        _issued = _issued + 1;
    } forEach _candidates;
};
if (_kind == "artillery" && {VCM_ARTYENABLE} && {side _caller in VCM_ARTYSIDES}) then {
    private _dispersion = 25 + (4 - ((_quality max 0) min 4)) * 35;
    private _rounds = 1 + floor (((_quality max 0) min 4) / 2);
    {
        if (_issued >= 2) exitWith {};
        private _gun = _x;
        if (alive _gun && {getNumber (configFile >> "CfgVehicles" >> typeOf _gun >> "artilleryScanner") == 1} &&
            {alive gunner _gun} && {!isPlayer gunner _gun} &&
            {[side _caller,side _gun] call BIS_fnc_sideIsFriendly} &&
            {(getArtilleryAmmo [_gun]) findIf {([_x] call VCM_fnc_ArtilleryAmmo) == "HE" && {_position inRangeOfArtillery [[_gun],_x]}} >= 0} &&
            {!(group gunner _gun getVariable ["Vcm_Disable",false])}) then {
            private _impact = _position getPos [random _dispersion,random 360];
            if (local _gun) then {[_gun,_impact,side _caller,_rounds] spawn VCM_fnc_ArtilleryFire} else {
                [_gun,_impact,side _caller,_rounds] remoteExecCall ["VCM_fnc_ArtilleryFire",owner _gun];
            };
            _issued = _issued + 1;
        };
    } forEach vehicles;
};
if (_issued > 0) then {VCM_SupportTimes set [_key,diag_tickTime + (VCM_ARTYDELAY max 10)]};
_issued > 0
