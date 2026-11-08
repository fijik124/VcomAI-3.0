/* Return owned magazines without changing wounds, equipment selection or unrelated safety locks. */
params ["_unit","_magazines"];
if (!local _unit) exitWith {};
private _holder = objNull;
{
    _x params ["_magazine","_rounds"];
    if (_unit canAdd _magazine) then {_unit addMagazine [_magazine,_rounds]} else {
        if (isNull _holder) then {_holder = createVehicle ["GroundWeaponHolder_Scripted",getPosATL _unit,[],0,"CAN_COLLIDE"]};
        _holder addMagazineAmmoCargo [_magazine,1,_rounds];
    };
} forEach _magazines;
