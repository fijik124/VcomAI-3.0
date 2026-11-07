if (missionNamespace getVariable ["VCM_Started", false]) exitWith {};
VCM_Started = true;
[] call VCM_fnc_InitSettings;
waitUntil {sleep 0.05; VCM_CBAReady};
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
[] spawn {while {true} do {[] call VCM_fnc_MineMonitor; sleep 0.1}};
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
    {
        if ([_x] call VCM_fnc_GroupEnabled && {simulationEnabled leader _x} &&
            {!(_x in VcmAI_ActiveList)} && {leader _x isKindOf "Man"}) then {
            _x call VCM_fnc_SquadExc;
        };
    } forEach allGroups;
    sleep 2;
};
