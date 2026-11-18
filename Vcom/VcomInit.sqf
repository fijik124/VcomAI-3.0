if (missionNamespace getVariable ["VCM_Started", false]) exitWith {};
if (!([] call VCM_fnc_InitSettings)) exitWith {};
VCM_Started = true;
// Addon preInit can run before CBA recreates its event namespace. Poll readiness so
// startup also works after the initialized event has already fired on a joining client.
waitUntil {sleep 0.05; missionNamespace getVariable ["cba_settings_ready",false]};
[] call VCM_fnc_CBASettings;
if (isServer) then {VCM_ServerReady = true; [] spawn VCM_fnc_IRCHECK};
if (hasInterface) then {
    // Keep the local panel and human-state cleanup alive while a client awaits server settings.
    [] spawn {
        while {true} do {
            {
                if (!isNull _x && {local _x}) then {
                    [_x] call VCM_fnc_ReleaseUnitState;
                    if (_x == leader group _x) then {[group _x] call VCM_fnc_AttackControl};
                };
            } forEach ([player,remoteControlled player] arrayIntersect [player,remoteControlled player]);
            [] call VCM_fnc_DebugUI;
            [] call VCM_fnc_CuratorUI;
            sleep 0.5;
        };
    };
};
if (!isServer) then {
    private _nextRequest = -1;
    waitUntil {
        if (diag_tickTime > _nextRequest) then {
            [player] remoteExecCall ["VCM_fnc_RequestSettings", 2];
            _nextRequest = diag_tickTime + 5;
        };
        sleep 0.1;
        VCM_SettingsReady
    };
};
VCOM_MINEARRAY = [];
VCM_RunSerial = 0;
VCM_ReactionUnits = [];
// Cover shooters outside VCOM combat groups too. Existing hearing handlers share the same rate limit.
["CAManBase","Fired",{
    if (missionNamespace getVariable ["VCM_CIVILIANS",false]) then {_this call VCM_fnc_HearingAids};
}] call CBA_fnc_addClassEventHandler;
if (isServer) then {
    [] spawn {
        private _previous = [];
        while {true} do {
            private _settings = call VCM_fnc_SettingsSnapshot;
            if !(_settings isEqualTo _previous) then {
                [_settings] remoteExecCall ["VCM_fnc_ApplySettings", -2, "VCM_Settings"];
                _previous = _settings;
            };
            sleep 1;
        };
    };
};
// A fixed update rate prevents frame rate from multiplying mine scans.
[] spawn {while {true} do {[] call VCM_fnc_MineMonitor; sleep 1}};
if (hasInterface) then {
    [] spawn {
        waitUntil {sleep 0.1; !isNull player};
        player addEventHandler ["Fired", {_this call VCM_fnc_HearingAids}];
        player addEventHandler ["Respawn", {
            (_this select 0) addEventHandler ["Fired", {_this call VCM_fnc_HearingAids}];
        }];
    };
};
while {true} do {
    // Include previous participants after death or side/group changes, so owned locks are released.
    private _reactions = +VCM_ReactionUnits;
    {
        if (local _x) then {
            if (side group _x == civilian || {_x getVariable ["VCM_SurrenderState",[]] isNotEqualTo []} ||
                {_x getVariable ["VCM_CivilianState",[]] isNotEqualTo []}) then {_reactions pushBackUnique _x};
        };
    } forEach allUnits;
    {
        [_x] call VCM_fnc_CivilianTick;
        [_x] call VCM_fnc_SurrenderTick;
    } forEach _reactions;
    VCM_ReactionUnits = _reactions select {!isNull _x && {local _x} && {
        _x getVariable ["VCM_CivilianState",[]] isNotEqualTo [] || {_x getVariable ["VCM_SurrenderState",[]] isNotEqualTo []}
    }};
    {
        if (local _x) then {
            if (_x getVariable ["VCM_Surrendered",false] && {
                (units _x) findIf {_x getVariable ["VCM_SurrenderState",[]] isNotEqualTo []} < 0
            }) then {_x setVariable ["VCM_Surrendered",false,true]};
            if (VCM_SURRENDERCHANCE > 0 && {time >= (_x getVariable ["VCM_NextMorale",-1])}) then {
                _x setVariable ["VCM_NextMorale",time + 5];
                private _plan = [_x] call VCM_fnc_SurrenderPlan;
                if (_plan isNotEqualTo []) then {
                    // Start checks on a fresh plan, then throttle retries even when the random roll fails.
                    if (random 1 < VCM_SURRENDERCHANCE) then {[_x] call VCM_fnc_Surrender};
                    _x setVariable ["VCM_SurrenderAfter",time + 30,true];
                };
            };
        };
        if ([_x] call VCM_fnc_GroupEnabled && {simulationEnabled leader _x} &&
            {_x getVariable ["VCM_RunId",[]] isEqualTo []} && {leader _x isKindOf "Man"}) then {
            _x call VCM_fnc_SquadExc;
        };
    } forEach allGroups;
    sleep 2;
};
