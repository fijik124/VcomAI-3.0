/* Client reports are bounded to its own shooter. Only the server distributes knowledge. */
if (!isServer || {!Vcm_ActivateAI}) exitWith {};
params [["_unit", objNull, [objNull]], ["_weapon", "", [""]], ["_identity",objNull,[objNull]]];
if (isNull _unit || {!alive _unit}) exitWith {};
private _sender = remoteExecutedOwner;
if (_sender > 0 && {_sender != owner _unit}) exitWith {};
// HC-originated calls report sender zero. Resolve those only through their connected HC identity.
if (_sender == 0 && {!local _unit} && {isNull _identity || {!(_identity isKindOf "HeadlessClient_F")} ||
    {owner _identity != owner _unit} || {owner _unit <= 2}}) exitWith {};
if (_weapon in ["", "Put", "Throw"] || {!(_weapon in weapons _unit)}) exitWith {};
if (time < (_unit getVariable ["VCM_ServerHearing", -10]) + 10) exitWith {};
_unit setVariable ["VCM_ServerHearing", time];
// Civilian fear also responds to nearby suppressed fire; it does not reveal the shooter as an enemy.
if (VCM_CIVILIANS) then {
    private _owners = [];
    {
        if (side group _x == civilian) then {_owners pushBackUnique owner _x};
    } forEach (_unit nearEntities ["CAManBase",VCM_CIVILIANRANGE]);
    // Route the server's own civilians through the same authenticated receiver as remote owners.
    {[_unit] remoteExecCall ["VCM_fnc_CivilianDanger",_x]} forEach _owners;
};
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
