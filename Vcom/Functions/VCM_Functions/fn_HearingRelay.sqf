/* Client reports are bounded to its own shooter. Only the server distributes knowledge. */
if (!isServer || {!Vcm_ActivateAI}) exitWith {};
params [["_unit", objNull, [objNull]], ["_weapon", "", [""]]];
if (isNull _unit || {!alive _unit}) exitWith {};
if (isRemoteExecuted && {remoteExecutedOwner != owner _unit}) exitWith {};
if (_weapon in ["", "Put", "Throw"] || {!(_weapon in weapons _unit)}) exitWith {};
if (time < (_unit getVariable ["VCM_ServerHearing", -10]) + 10) exitWith {};
_unit setVariable ["VCM_ServerHearing", time];
private _accessory = (_unit weaponAccessories _weapon) param [0, ""];
if (_accessory != "" && {getNumber (configFile >> "CfgWeapons" >> _accessory >> "ItemInfo" >> "AmmoCoef" >> "audibleFire") < 1}) exitWith {};
private _listeners = [];
{
    private _group = group _x;
    if (!isPlayer _x && {alive _x} && {side _group in VCM_SIDEENABLED} &&
        {!(_group getVariable ["Vcm_Disable", false])} &&
        {[side group _unit, side _group] call BIS_fnc_sideIsEnemy}) then {
        _listeners pushBackUnique leader _group;
    };
} forEach (_unit nearEntities ["Man", VCM_HEARINGDISTANCE]);
private _owners = [];
{_owners pushBackUnique owner _x} forEach _listeners;
{
    private _owner = _x;
    private _localListeners = _listeners select {owner _x == _owner};
    [_localListeners, _unit, 0.1] remoteExecCall ["VCM_fnc_KnowAbout", _owner];
} forEach _owners;
