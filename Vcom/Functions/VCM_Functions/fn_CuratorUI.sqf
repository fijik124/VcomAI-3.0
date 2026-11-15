/* Local curator-only markers; tactical assignments and remembered danger never leak onto player maps. */
if (!hasInterface) exitWith {};
private _active = VCM_COMMANDPOINTS && {!isNull findDisplay 312} && {!isNull getAssignedCuratorLogic player};
private _markers = missionNamespace getVariable ["VCM_CuratorMarkers",[]];
if (!_active) exitWith {
    {deleteMarkerLocal _x} forEach _markers;
    VCM_CuratorMarkers = [];
};
private _selected = curatorSelected;
private _groups = +(_selected param [1,[]]);
{if (_x isKindOf "Man") then {_groups pushBack group _x}} forEach (_selected param [0,[]]);
_groups = (_groups arrayIntersect _groups) select {side _x in [west,east,resistance]};
if (_groups isNotEqualTo []) then {VCM_ZeusSelection = [diag_tickTime,_groups]};
private _points = +(missionNamespace getVariable ["VCM_CommandPointRegistry",[]]);
private _editable = curatorEditableObjects getAssignedCuratorLogic player;
_points = _points select {(_x select 5) findIf {leader _x in _editable} >= 0};
private _desired = [];
{
    _x params ["_id","_kind","_position","_direction","_radius","_assigned"];
    private _name = "VCM_CURATOR_" + _id;
    _desired pushBack _name;
    if (!(_name in _markers)) then {createMarkerLocal [_name,_position]};
    _name setMarkerPosLocal _position;
    _name setMarkerTypeLocal (switch (_kind) do {case "recon": {"mil_unknown"}; case "defend": {"mil_objective"}; case "fallback": {"mil_end"}; default {"mil_warning"}});
    _name setMarkerColorLocal (if (_kind == "danger") then {"ColorRed"} else {"ColorYellow"});
    _name setMarkerDirLocal _direction;
    _name setMarkerTextLocal format ["VCOM %1: %2 (%3 m)",_kind,(_assigned apply {groupId _x}) joinString ", ",round _radius];
} forEach (_points select [0,64]);
private _inspect = (missionNamespace getVariable ["VCM_ZeusSelection",[0,[]]]) select 1;
{
    private _group = _x;
    if (leader _group in _editable) then {
        {
            if (_x select 2 > time) then {
                private _name = format ["VCM_CURATOR_MEMORY_%1_%2",netId _group,_forEachIndex];
                _desired pushBack _name;
                if (!(_name in _markers)) then {createMarkerLocal [_name,_x select 0]};
                _name setMarkerPosLocal (_x select 0); _name setMarkerTypeLocal "mil_warning";
                _name setMarkerColorLocal "ColorOrange";
                _name setMarkerTextLocal format ["VCOM %1: %2 (%3 s)",groupId _group,_x select 3,ceil ((_x select 2) - time)];
            };
        } forEach (_group getVariable ["VCM_DangerMemory",[]]);
    };
} forEach (_inspect select [0,4]);
{deleteMarkerLocal _x} forEach (_markers - _desired);
VCM_CuratorMarkers = _desired;
