if (!isServer) exitWith {};
params [["_requester", objNull, [objNull]]];
private _recipient = remoteExecutedOwner;
// Arma deliberately reports HC-originated RPCs as local execution with sender 0.
// Only resolve that case through a connected headless-client identity, never an arbitrary ID.
if (_recipient == 0 && {!isNull _requester} && {_requester isKindOf "HeadlessClient_F"}) then {
    _recipient = owner _requester;
};
if (_recipient <= 2) exitWith {};
// This endpoint returns only the fixed public settings snapshot to one valid client.
if (missionNamespace getVariable ["VCM_ServerReady", false]) then {
    [call VCM_fnc_SettingsSnapshot] remoteExecCall ["VCM_fnc_ApplySettings", _recipient];
};
