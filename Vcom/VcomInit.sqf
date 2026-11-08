if (missionNamespace getVariable ["VCM_Started", false]) exitWith {};
VCM_Started = true;
[] call VCM_fnc_InitSettings;
// Addon preInit can run before CBA recreates its event namespace. Poll readiness so
// startup also works after the initialized event has already fired on a joining client.
waitUntil {sleep 0.05; VCM_CBAReady || {missionNamespace getVariable ["cba_settings_ready",false]}};
VCM_CBAReady = true;
if (CBAACT) then {[] call VCM_fnc_CBASettings};
if (isServer) then {VCM_ServerReady = true; [] spawn VCM_fnc_IRCHECK};
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
    // A newly occupied or Zeus-controlled unit may carry state from another owner.
    // Check only the two local human-controlled objects, including when no AI controller starts.
    [] spawn {
        while {true} do {
            {
                if (!isNull _x && {local _x}) then {
                    [_x] call VCM_fnc_ReleaseUnitState;
                    if (_x == leader group _x) then {[group _x] call VCM_fnc_AttackControl};
                };
            } forEach ([player,remoteControlled player] arrayIntersect [player,remoteControlled player]);
            [] call VCM_fnc_DebugUI;
            sleep 0.5;
        };
    };
    [] spawn {
        waitUntil {sleep 0.1; !isNull player};
        player addEventHandler ["Fired", {_this call VCM_fnc_HearingAids}];
        player addEventHandler ["Respawn", {
            (_this select 0) addEventHandler ["Fired", {_this call VCM_fnc_HearingAids}];
        }];
    };
};
while {true} do {
    {
        if ([_x] call VCM_fnc_GroupEnabled && {simulationEnabled leader _x} &&
            {_x getVariable ["VCM_RunId",[]] isEqualTo []} && {leader _x isKindOf "Man"}) then {
            _x call VCM_fnc_SquadExc;
        };
    } forEach allGroups;
    sleep 2;
};
