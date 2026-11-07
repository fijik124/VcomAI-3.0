/* Author: Genesis. Server-owned laser observations; no remotely supplied code. */
if (!isServer) exitWith {};
while {true} do {
    if (Vcm_ActivateAI) then {
        {
            private _player = _x;
            if (alive _player && {_player isIRLaserOn currentWeapon _player}) then {
                private _eye = eyePos _player;
                private _end = _eye vectorAdd ((_player weaponDirection currentWeapon _player) vectorMultiply 1000);
                private _hits = lineIntersectsSurfaces [_eye, _end, _player, vehicle _player, true, 1];
                if (count _hits > 0) then {
                    private _spot = _hits select 0 select 0;
                    private _listeners = [];
                    {
                        if (!isPlayer _x && {currentVisionMode _x == 1} &&
                            {[side group _player, side group _x] call BIS_fnc_sideIsEnemy} &&
                            {[_x, "VIEW", vehicle _x] checkVisibility [eyePos _x, _spot] > 0.1}) then {
                            _listeners pushBackUnique leader group _x;
                        };
                    } forEach (_player nearEntities ["Man", 300]);
                    private _owners = [];
                    {_owners pushBackUnique owner _x} forEach _listeners;
                    {
                        private _owner = _x;
                        [_listeners select {owner _x == _owner}, _player, 0.1] remoteExecCall ["VCM_fnc_KnowAbout", _owner];
                    } forEach _owners;
                };
            };
        } forEach allPlayers;
    };
    sleep 1;
};
