/* Internal fixed operations for phased tasks. This function is not remotely executable. */
params ["_group","_key","_operation"];
_operation params ["_kind",["_rescuer",objNull],["_patient",objNull]];
switch (_kind) do {
    case "attach": {[_group,_key,_rescuer,_patient] call VCM_fnc_EvacAttach};
    case "detach": {[_group,_key] call VCM_fnc_EvacRelease; true};
    default {false};
}
