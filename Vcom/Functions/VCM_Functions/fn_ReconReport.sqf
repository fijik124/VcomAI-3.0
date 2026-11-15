/* Validate owner identity independently of isRemoteExecuted: native HC RPCs report sender zero. */
if (!isServer) exitWith {false};
params [["_source",grpNull,[grpNull]],["_reports",[],[[]]],["_identity",objNull,[objNull]]];
if (isNull _source) exitWith {false};
private _owner = groupOwner _source;
private _sender = remoteExecutedOwner;
if (_sender > 0 && {_sender != _owner}) exitWith {false};
if (_sender == 0 && {isNull _identity || {!(_identity isKindOf "HeadlessClient_F")} ||
    {_owner <= 2} || {owner _identity != _owner}}) exitWith {false};
_this call VCM_fnc_ReconPublish
