/* A VCOM-owned control on the current gameplay/Zeus display; never consume mission hints. */
if (!hasInterface) exitWith {controlNull};
disableSerialization;
params [["_message","",[""]]];
private _panel = uiNamespace getVariable ["VCM_DebugPanel",controlNull];
if (_message == "") exitWith {
    if (!isNull _panel) then {ctrlDelete _panel};
    uiNamespace setVariable ["VCM_DebugPanel",controlNull];
    controlNull
};
private _display = findDisplay 312;
private _curator = !isNull _display;
if (!_curator) then {_display = findDisplay 46};
if (isNull _display) exitWith {controlNull};
if (!isNull _panel && {ctrlParent _panel != _display}) then {ctrlDelete _panel; _panel = controlNull};
if (isNull _panel) then {
    _panel = _display ctrlCreate ["RscStructuredText",-1];
    _panel ctrlSetBackgroundColor [0.015,0.025,0.04,0.88];
    _panel ctrlSetTextColor [1,1,1,1];
    _panel ctrlShow true;
    _panel ctrlSetFade 0;
    uiNamespace setVariable ["VCM_DebugPanel",_panel];
};
private _width = safeZoneW * 0.28;
private _left = safeZoneX + safeZoneW * (if (_curator) then {0.51} else {0.71});
private _top = safeZoneY + safeZoneH * 0.12;
_panel ctrlSetPosition [_left,_top,_width,safeZoneH * 0.72];
_panel ctrlCommit 0;
_panel ctrlSetStructuredText parseText ("<t size='0.85'>" + _message + "</t>");
_panel ctrlSetPosition [_left,_top,_width,((ctrlTextHeight _panel) + 0.015) min (safeZoneH * 0.72)];
_panel ctrlCommit 0;
_panel
