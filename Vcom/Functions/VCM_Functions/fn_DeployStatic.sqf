/* Author: Genesis. Deploy a carried static only while the originating run owns the unit. */
params ["_unit", "_backpack", "_run"];
private _group = group _unit;
if (_group getVariable ["VCM_BoundState", []] isNotEqualTo []) exitWith {};
if (!([_unit, _group, _run] call VCM_fnc_ActionValid) || {!isNull objectParent _unit} ||
    {backpack _unit != _backpack} || {_unit getVariable ["VCM_DeployBusy", false]}) exitWith {};
private _assembled = getText (configFile >> "CfgVehicles" >> _backpack >> "assembleInfo" >> "assembleTo");
if (_assembled == "" || {!(_assembled isKindOf "StaticWeapon")}) exitWith {};
private _position = getPosATL _unit;
if (lineIntersects [eyePos _unit, (eyePos _unit) vectorAdd [0,0,10], _unit]) exitWith {};
private _enemy = _unit call VCM_fnc_ClstEmy;
if (isNull _enemy) exitWith {};
private _contact = [_unit, _enemy] call VCM_fnc_ContactPosition;
if (_contact isEqualTo []) exitWith {};
_unit setVariable ["VCM_DeployBusy", true];
private _weapon = createVehicle [_assembled, _position, [], 0, "CAN_COLLIDE"];
[_unit, "AinvPknlMstpSnonWnonDnon_Putdown_AmovPknlMstpSnonWnonDnon"] remoteExecCall ["VCM_fnc_PlayAnimation", 0];
sleep 3.5;
if (!([_unit, _group, _run] call VCM_fnc_ActionValid) || {backpack _unit != _backpack} || {!isNull objectParent _unit}) exitWith {
    if (count crew _weapon == 0) then {deleteVehicle _weapon};
    if (_run isEqualTo (_group getVariable ["VCM_RunId", []])) then {_unit setVariable ["VCM_DeployBusy", false]};
};
_weapon setDir (_weapon getDir _contact);
_unit assignAsGunner _weapon;
_unit moveInGunner _weapon;
if (gunner _weapon isEqualTo _unit) then {
    removeBackpackGlobal _unit;
    [_unit, _backpack, _weapon, _run] spawn VCM_fnc_PackStatic;
} else {
    if (count crew _weapon == 0) then {deleteVehicle _weapon};
};
_unit setVariable ["VCM_DeployBusy", false];
