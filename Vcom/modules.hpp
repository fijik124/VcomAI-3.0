class CfgFactionClasses
{
    class NO_CATEGORY;
    class VCM_Tactics: NO_CATEGORY { displayName = "VCOM Tactics"; };
};
class CfgVehicles
{
    class Logic;
    class Module_F: Logic
    {
        class AttributesBase { class Edit; class Units; };
        class ModuleDescription {};
    };
    class VCM_ModuleBase: Module_F
    {
        scope = 1;
        scopeCurator = 1;
        category = "VCM_Tactics";
        function = "VCM_fnc_ZeusModule";
        functionPriority = 10;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 1;
        curatorCanAttach = 1;
        vcmCommand = "point";
        vcmKind = "";
        class Attributes: AttributesBase
        {
            class Units: Units {};
            class Radius: Edit
            {
                property = "VCM_Radius";
                displayName = "Point radius (meters)";
                tooltip = "5 to 150 meters. In Zeus, the CBA default point radius is used.";
                typeName = "NUMBER";
                defaultValue = "30";
            };
        };
        class ModuleDescription: ModuleDescription
        {
            description = "Eden: synchronize AI soldiers. Zeus: select AI squads, then place within 30 seconds, or drop on a soldier. Placing another recon/defense/fallback point for the same squad moves its assignment. Mission waypoints take priority.";
        };
    };
    class VCM_ModuleReconPoint: VCM_ModuleBase
    { scope = 2; scopeCurator = 2; displayName = "Recon observation point"; vcmKind = "recon"; };
    class VCM_ModuleDefensePoint: VCM_ModuleBase
    { scope = 2; scopeCurator = 2; displayName = "Defend position"; vcmKind = "defend"; };
    class VCM_ModuleFallbackPoint: VCM_ModuleBase
    { scope = 2; scopeCurator = 2; displayName = "Fallback position"; vcmKind = "fallback"; };
    class VCM_ModuleDangerPoint: VCM_ModuleBase
    { scope = 2; scopeCurator = 2; displayName = "Mark danger area"; vcmKind = "danger"; };
    class VCM_ModuleResetPoint: VCM_ModuleBase
    { scope = 2; scopeCurator = 2; displayName = "Remove nearest VCOM point (50 m)"; vcmCommand = "resetPoint"; };
    class VCM_ModuleRestartPoint: VCM_ModuleBase
    { scope = 2; scopeCurator = 2; displayName = "Restart nearest VCOM point (50 m)"; vcmCommand = "restartPoint"; };
    class VCM_ModuleForgetDanger: VCM_ModuleBase
    { scope = 2; scopeCurator = 2; displayName = "Forget danger near this point"; vcmCommand = "resetDanger"; };
    class VCM_ModuleResetGroup: VCM_ModuleBase
    { scope = 2; scopeCurator = 2; displayName = "Reset squad tactics and points"; vcmCommand = "resetGroup"; };
    class VCM_ModuleDoctrineAuto: VCM_ModuleBase
    { scope = 2; scopeCurator = 0; displayName = "Doctrine override: return to automatic"; vcmCommand = "doctrine"; vcmKind = "auto"; };
    class VCM_ModuleDoctrineRecon: VCM_ModuleBase
    { scope = 2; scopeCurator = 0; displayName = "Doctrine override: cautious reconnaissance"; vcmCommand = "doctrine"; vcmKind = "recon"; };
    class VCM_ModuleDoctrineAssault: VCM_ModuleBase
    { scope = 2; scopeCurator = 0; displayName = "Doctrine override: assault"; vcmCommand = "doctrine"; vcmKind = "assault"; };
    class VCM_ModuleDoctrineDefend: VCM_ModuleBase
    { scope = 2; scopeCurator = 0; displayName = "Doctrine override: static defense"; vcmCommand = "doctrine"; vcmKind = "defend"; };
    class VCM_ModuleDoctrineConvoy: VCM_ModuleBase
    { scope = 2; scopeCurator = 0; displayName = "Doctrine override: convoy escort"; vcmCommand = "doctrine"; vcmKind = "convoy"; };
};
