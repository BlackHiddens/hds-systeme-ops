params ["_position","_distanceapproche","_camps"];
if(hdssysteme)then{[format["%1 : Déploiement de renfort d'infanterie véhiculé par voie aérienne si possible",hdstactiqueversion]] remoteexeccall ['systemChat',0]};
switch (_this select 2) do {
  //opfor east
    case 0: {
      [
        (_this select 0),
        (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "UInfantry" >> "OIA_GuardTeam"),
        (_this select 1),
        east,
        "O_Heli_Light_02_dynamicLoadout_F",
        2
        ] spawn fnc_tactique_renfortvehiculer;
    };
  case 1:{
    //independant
    [
      (_this select 0),
      (configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "I_InfTeam_Light"),
      (_this select 1),
      independent,
      "I_Heli_Transport_02_F",
      2
      ] spawn fnc_tactique_renfortvehiculer;
  };
 case 2:{
   [
     (_this select 0),
     (configfile >> "CfgGroups" >> "West" >> "BLU_F" >> "Infantry" >> "BUS_InfAssault"),
     (_this select 1),
     west,
     "B_Heli_Transport_03_F",
     2
     ] spawn fnc_tactique_renfortvehiculer;
 };
 case 3:{
   [
     (_this select 0),
     (configfile >> "CfgGroups" >> "East" >> "OPF_G_F" >> "Infantry" >> "O_G_InfSquad_Assault"),
     (_this select 1),
     east,
     "I_Heli_light_03_unarmed_F",
     2
     ] spawn fnc_tactique_renfortvehiculer;
 };
 case 4:{
   [
     (_this select 0),
     (configfile >> "CfgGroups" >> "East" >> "LOP_BH" >> "Infantry" >> "LOP_BH_Fireteam"),
     (_this select 1),
     east,
     "LOP_BH_Truck",
     2
     ] spawn fnc_tactique_renfortvehiculer;
 };
  case 5:{
    [
      (_this select 0),
      (configfile >> "CfgGroups" >> "East" >> "rhs_faction_msv" >> "rhs_group_rus_msv_infantry_emr" >> "rhs_group_rus_msv_infantry_emr_fireteam"),
      (_this select 1),
      east,
      "RHS_Mi8mt_vdv",
      2
      ] spawn fnc_tactique_renfortvehiculer;
  };

  case 6:{
    [
      (_this select 0),
      (configfile >> "CfgGroups" >> "East" >> "LOP_AM_OPF" >> "Infantry" >> "LOP_AM_OPF_Fireteam"),
      (_this select 1),
      east,
      "LOP_AM_OPF_Truck",
      2
      ] spawn fnc_tactique_renfortvehiculer;
  };
  case 7:{
    [
      (_this select 0),
      (configfile >> "CfgGroups" >> "East" >> "LOP_ISTS_OPF" >> "Infantry" >> "PO_ISTS_OPF_inf_WEAP_SEC"),
      (_this select 1),
      east,
      "LOP_ISTS_OPF_Landrover",
      2
      ] spawn fnc_tactique_renfortvehiculer;
  };
 default {
   [
     (_this select 0),
     (configfile >> "CfgGroups" >> "East" >> "OPF_G_F" >> "Infantry" >> "O_G_InfSquad_Assault"),
     (_this select 1),
     east,
     "O_G_Van_02_transport_F",
     2
     ] spawn fnc_tactique_renfortvehiculer;
 };
};
