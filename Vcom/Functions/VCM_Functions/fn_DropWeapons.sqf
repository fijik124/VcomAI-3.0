/* Transfer equipped firearms once, including attachments and partially used loaded magazines. */
params ["_unit"];
private _holder = objNull;
if (!local _unit || {!alive _unit} || {[_unit] call VCM_fnc_HumanControlled}) exitWith {_holder};
// No scheduler suspension may separate the inventory snapshot from its transfer.
isNil {
    private _weapons = (getUnitLoadout _unit select [0,3]) select {_x isNotEqualTo [] && {(_x select 0) != ""}};
    if (_weapons isNotEqualTo []) then {
        _holder = createVehicle ["GroundWeaponHolder_Scripted",getPosATL _unit,[],0,"CAN_COLLIDE"];
        if (!isNull _holder) then {
            {
                _holder addWeaponWithAttachmentsCargoGlobal [_x,1];
                _unit removeWeaponGlobal (_x select 0);
            } forEach _weapons;
            _unit setVariable ["VCM_DroppedWeapons",_holder,true];
        };
    };
};
_holder
