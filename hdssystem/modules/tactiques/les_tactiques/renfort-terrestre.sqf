/*
Description : Génére un véhicules de transport remplis de soldat selon
la facontion passé en paramètre.

_position : nom_de_marqueur <string>
_distanceproche : distance d'approche <integer>
_faction : numero de faction <integer> 0,1,2,3,4

exemple : ["pos_vollage",800,3] call fnc_tactique_renfortterrestre;

*/
params ["_position","_distanceproche","_camps"];
if(hdssysteme)then{[format['%1 : Renfort infanterie véhiculé par vois terrestre',hdstactiqueversion]] remoteexeccall ['systemChat',0]};
switch (_camps) do {
  //opfor east
    case 0: {
      [
        (_this select 0),
        (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "UInfantry" >> "OIA_GuardTeam"),
        (_this select 1),
        east,
        "O_Truck_03_Transport_F",
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
      "I_Truck_02_covered_F",
      2
      ] spawn fnc_tactique_renfortvehiculer;
  };
 case 2:{
   [
     (_this select 0),
     (configfile >> "CfgGroups" >> "West" >> "BLU_F" >> "Infantry" >> "BUS_InfAssault"),
     (_this select 1),
     west,
     "B_T_Truck_01_Transport_F",
     2
     ] spawn fnc_tactique_renfortvehiculer;
 };
 case 3:{
   [
     (_this select 0),
     (configfile >> "CfgGroups" >> "East" >> "OPF_G_F" >> "Infantry" >> "O_G_InfSquad_Assault"),
     (_this select 1),
     east,
     "O_G_Van_02_transport_F",
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
      "rhs_gaz66_msv",
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
