params ["_pos","_nbgroupeinf","_nbvehicule","_distanceapproche","_camps","_ciblemarqueur"];
if(hdssysteme)then{[format["%1 : Mission rechercher et détruire donnée à des groupes d'enfanterie",hdstactiqueversion]] remoteexeccall ['systemChat',0]};
_custom_distance_approche = (_this select 3)*2;
switch (_this select 4) do {
  case 0:{
    [
      ([(_this select 0),_custom_distance_approche,(_custom_distance_approche+150),1,0,60] call BIS_fnc_findSafePos),
      (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "UInfantry" >> "OIA_GuardTeam"),
      _custom_distance_approche,
      east,
      (_this select 1),
      hds_liste_vehicule_csat,
      (_this select 2)
    ] spawn fnc_tactique_groupedecombat;
  };
  case 1:{
    //independant aaf troupes
    [
      ([(_this select 0),_custom_distance_approche,(_custom_distance_approche+150),1,0,60] call BIS_fnc_findSafePos),
      (configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfSquad"),
      _custom_distance_approche,
      independent,
      (_this select 1),
      hds_liste_vehicule_aaf,
      (_this select 2)
    ] spawn fnc_tactique_groupedecombat;
  };
  case 2:{
    //blufor troupes
    [
      ([(_this select 0),_custom_distance_approche,(_custom_distance_approche+150),1,0,60] call BIS_fnc_findSafePos),
      (configfile >> "CfgGroups" >> "West" >> "BLU_F" >> "Infantry" >> "BUS_ReconPatrol"),
      _custom_distance_approche,
      west,
      (_this select 1),
      hds_liste_vehicule_blu,
      (_this select 2)
    ] spawn fnc_tactique_groupedecombat;
  };
  case 3:{
    //east rebelle fia
    [
      ([(_this select 0),_custom_distance_approche,(_custom_distance_approche+150),1,0,60] call BIS_fnc_findSafePos),
      (configfile >> "CfgGroups" >> "East" >> "OPF_G_F" >> "Infantry" >> "O_G_InfTeam_Light"),
      _custom_distance_approche,
      east,
      (_this select 1),
      hds_liste_vehicule_fia_opfor,
      (_this select 2)
    ] spawn fnc_tactique_groupedecombat;
  };
  case 4:{
    //opfor : boko haram
    [
      ([(_this select 0),_custom_distance_approche,(_custom_distance_approche+150),1,0,60] call BIS_fnc_findSafePos),
      (configfile >> "CfgGroups" >> "East" >> "LOP_BH" >> "Infantry" >> "LOP_BH_WeaponSquad"),
      _custom_distance_approche,
      east,
      (_this select 1),
      hds_liste_vehicule_bokoharam,
      (_this select 2)
    ] spawn fnc_tactique_groupedecombat;
  };
    case 5:{
      //opfor rhs_afrf russe
      [
        ([(_this select 0),_custom_distance_approche,(_custom_distance_approche+150),1,0,60] call BIS_fnc_findSafePos),
        (configfile >> "CfgGroups" >> "East" >> "rhs_faction_msv" >> "rhs_group_rus_msv_infantry_emr" >> "rhs_group_rus_msv_infantry_emr_squad"),
        _custom_distance_approche,
        east,
        (_this select 1),
        hds_liste_vehicule_rhs_russe,
        (_this select 2)
      ] spawn fnc_tactique_groupedecombat;
    };
    case 6:{
      //opfor afghan
      [
        ([(_this select 0),_custom_distance_approche,(_custom_distance_approche+150),1,0,60] call BIS_fnc_findSafePos),
        (configfile >> "CfgGroups" >> "East" >> "LOP_AM_OPF" >> "Infantry" >> "LOP_AM_OPF_Support_section"),
        _custom_distance_approche,
        east,
        (_this select 1),
        hds_liste_vehicule_afghan,
        (_this select 2)
      ] spawn fnc_tactique_groupedecombat;
    };
    case 7:{
      //opfor islamique
      [
        ([(_this select 0),_custom_distance_approche,(_custom_distance_approche+150),1,0,60] call BIS_fnc_findSafePos),
        (configfile >> "CfgGroups" >> "East" >> "LOP_ISTS_OPF" >> "Infantry" >> "PO_ISTS_OPF_inf_WEAP_SEC"),
        _custom_distance_approche,
        east,
        (_this select 1),
        hds_liste_vehicule_islamique,
        (_this select 2)
      ] spawn fnc_tactique_groupedecombat;
    };
  default{
    //east rebelle fia
    [
      ([(_this select 0),_custom_distance_approche,(_custom_distance_approche+150),1,0,60] call BIS_fnc_findSafePos),
      (configfile >> "CfgGroups" >> "East" >> "OPF_G_F" >> "Infantry" >> "O_G_InfTeam_Light"),
      _custom_distance_approche,
      east,
      (_this select 1),
      hds_liste_vehicule_fia_opfor,
      (_this select 2)
    ] spawn fnc_tactique_groupedecombat;
  };
};
