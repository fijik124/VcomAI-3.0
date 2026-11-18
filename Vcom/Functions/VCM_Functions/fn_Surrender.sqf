/* End combat controllers before taking ownership of a squad's surrender state. */
params ["_group"];
private _started = false;
// Do not expose a partially started surrender to another scheduled controller or a settings change.
isNil {
    private _plan = [_group] call VCM_fnc_SurrenderPlan;
    if (_plan isEqualTo []) exitWith {};
    private _run = _group getVariable ["VCM_RunId",[]];
    _group setVariable ["VCM_Surrendered",true,true];
    if (_run isNotEqualTo []) then {[_group,_run] call VCM_fnc_CleanupGroup};
    {
        private _unit = _x;
        if (alive _unit) then {
            private _features = ["PATH","TARGET","AUTOTARGET","AUTOCOMBAT","FSM","FIREWEAPON"] apply {[_x,_unit checkAIFeature _x]};
            private _ace = !isNil "ace_captives_fnc_setSurrendered" && {missionNamespace getVariable ["ace_captives_captivityEnabled",false]};
            private _state = [group _unit,_features,unitPos _unit,getForcedSpeed _unit,behaviour _unit,captive _unit,_ace,clientOwner,false];
            _unit setVariable ["VCM_SurrenderState",_state,true];
            {if (_x select 1) then {_unit disableAI (_x select 0)}} forEach _features;
            _unit setUnitPos "UP";
            _unit forceSpeed 0;
            _unit doTarget objNull;
            _unit doWatch objNull;
            doStop _unit;
            if (VCM_SURRENDERDROP) then {
                private _holder = [_unit] call VCM_fnc_DropWeapons;
                _state set [8,!isNull _holder || {[primaryWeapon _unit,handgunWeapon _unit,secondaryWeapon _unit] isEqualTo ["","",""]}];
                _unit setVariable ["VCM_SurrenderState",_state,true];
            };
            if (_ace) then {[_unit,true] call ace_captives_fnc_setSurrendered} else {
                _unit setCaptive true;
                _unit switchMove "AmovPercMstpSsurWnonDnon";
            };
            VCM_ReactionUnits pushBackUnique _unit;
        };
    } forEach units _group;
    [_group,"surrender",_plan select 0,[],_plan select 1] call VCM_fnc_DebugDecision;
    _started = true;
};
_started
