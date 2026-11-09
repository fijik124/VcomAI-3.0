/* Internal fixed operations for phased tasks. This function is not remotely executable. */
params ["_group","_key","_operation"];
_operation params ["_kind",["_rescuer",objNull],["_patient",objNull]];
switch (_kind) do {
    case "clearRooms": {
        _operation params ["","_building","_entry","_layout","_contact"];
        [_group,_key,_building,_entry,_layout,_contact] call VCM_fnc_ClearRooms
    };
    case "attach": {[_group,_key,_rescuer,_patient] call VCM_fnc_EvacAttach};
    case "detach": {[_group,_key] call VCM_fnc_EvacRelease; true};
    default {false};
}
