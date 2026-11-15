/* RPC entry: sender zero is never a curator, even when HC traffic reports local execution. */
if (!isServer) exitWith {false};
params [["_identity",objNull,[objNull]]];
if (isNull _identity || {!isPlayer _identity} || {remoteExecutedOwner <= 0} ||
    {owner _identity != remoteExecutedOwner}) exitWith {false};
_this call VCM_fnc_CommanderOrder
