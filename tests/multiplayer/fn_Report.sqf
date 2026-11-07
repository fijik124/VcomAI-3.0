/* Test-only RPC: HC traffic can arrive with remoteExecutedOwner == 0. */
if (!isServer) exitWith {};
params ["_client", "_identity", "_label", "_payload"];
if (_client != 2 && {isNull _identity || {!(_identity isKindOf "HeadlessClient_F")} || {owner _identity != _client}}) exitWith {};
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != _client}) exitWith {};
if (isNil "VCM_MP_Reports") then {VCM_MP_Reports = createHashMap};
VCM_MP_Reports set [format ["%1:%2", _client, _label], _payload];
diag_log format ["VCM_MP_REPORT: %1 %2; remote=%3 sender=%4", _client, _label, isRemoteExecuted, remoteExecutedOwner];
