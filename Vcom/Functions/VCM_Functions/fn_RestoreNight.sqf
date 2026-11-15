/* Restore observed attachment states and the LIGHTS feature owned by night discipline. */
params ["_unit",["_restoreIR",false]];
if (!local _unit) exitWith {};
private _saved = _unit getVariable ["VCM_NightState",[]];
if (_saved isEqualTo []) exitWith {};
_saved params ["_enabled","_weapon","_flash","_laser","_lastFlash","_lastLaser"];
if (primaryWeapon _unit == _weapon) then {
    if ((_unit isFlashlightOn _weapon) isEqualTo _lastFlash) then {
        _unit action [["GunLightOff","GunLightOn"] select _flash,_unit];
    };
    if (_restoreIR || {(_unit isIRLaserOn _weapon) isEqualTo _lastLaser}) then {
        _unit action [["IRLaserOff","IRLaserOn"] select _laser,_unit];
    };
};
if (_enabled) then {_unit enableAI "LIGHTS"};
_unit setVariable ["VCM_NightState",nil,true];
