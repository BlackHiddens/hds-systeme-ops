params ["_Centre","_Ratio","_Faction","_Taille","_Visible"];

//------------Appeles des fonctions d'accupation lié à la faction demandé------------

switch (_this select 2) do {


  case 0: {
    /*
      -Garnisons
      -Patrouilles
      -Vehicules
    */
    //opfor csat
    [(_this select 0),(_this select 3),(_this select 1),(configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "UInfantry" >> "OIA_GuardSquad"),0,east] call fnc_occupations_init;
    [(_this select 0),(_this select 3),(_this select 1),(configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "UInfantry" >> "OIA_GuardTeam"),1,east] call fnc_occupations_init;
    [(_this select 0),(_this select 3),(_this select 1),hds_liste_vehicule_csat,2,east] call fnc_occupations_init;
  };
  //Independant aaf
  case 1: {
    [(_this select 0),(_this select 3),(_this select 1),(configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "I_InfTeam_Light"),0,independent] call fnc_occupations_init;
    [(_this select 0),(_this select 3),(_this select 1),(configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfSquad"),1,independent] call fnc_occupations_init;
    [(_this select 0),(_this select 3),(_this select 1),hds_liste_vehicule_aaf,2,independent] call fnc_occupations_init;
  };
  //blufor americain
  case 2: {
    [(_this select 0),(_this select 3),(_this select 1),(configfile >> "CfgGroups" >> "West" >> "BLU_F" >> "Infantry" >> "BUS_InfAssault"),0,west] call fnc_occupations_init;
    [(_this select 0),(_this select 3),(_this select 1),(configfile >> "CfgGroups" >> "West" >> "BLU_F" >> "Infantry" >> "BUS_ReconPatrol"),1,west] call fnc_occupations_init;
    [(_this select 0),(_this select 3),(_this select 1),hds_liste_vehicule_blu,2,west] call fnc_occupations_init;
  };
  //opfor fia
  case 3: {
    [(_this select 0),(_this select 3),(_this select 1),(configfile >> "CfgGroups" >> "East" >> "OPF_G_F" >> "Infantry" >> "O_G_InfSquad_Assault"),0,east] call fnc_occupations_init;
    [(_this select 0),(_this select 3),(_this select 1),(configfile >> "CfgGroups" >> "East" >> "OPF_G_F" >> "Infantry" >> "O_G_InfTeam_Light"),1,east] call fnc_occupations_init;
    [(_this select 0),(_this select 3),(_this select 1),hds_liste_vehicule_fia_opfor,2,east] call fnc_occupations_init;
  };
  //opfor bokoharam
  if (opforactive) then {
  case 4: {
      [(_this select 0),(_this select 3),(_this select 1),(configfile >> "CfgGroups" >> "East" >> "LOP_BH" >> "Infantry" >> "LOP_BH_Fireteam"),0,east] call fnc_occupations_init;
      [(_this select 0),(_this select 3),(_this select 1),(configfile >> "CfgGroups" >> "East" >> "LOP_BH" >> "Infantry" >> "LOP_BH_WeaponSquad"),1,east] call fnc_occupations_init;
      [(_this select 0),(_this select 3),(_this select 1),hds_liste_vehicule_bokoharam,2,east] call fnc_occupations_init;
    };
  };
  //opfor rhs_afrf russe
  if(afrfactive)then{
  case 5: {
    [(_this select 0),(_this select 3),(_this select 1),(configfile >> "CfgGroups" >> "East" >> "rhs_faction_msv" >> "rhs_group_rus_msv_infantry_emr" >> "rhs_group_rus_msv_infantry_emr_fireteam"),0,east] call fnc_occupations_init;
    [(_this select 0),(_this select 3),(_this select 1),(configfile >> "CfgGroups" >> "East" >> "rhs_faction_msv" >> "rhs_group_rus_msv_infantry_emr" >> "rhs_group_rus_msv_infantry_emr_squad"),1,east] call fnc_occupations_init;
    [(_this select 0),(_this select 3),(_this select 1),hds_liste_vehicule_rhs_russe,2,east] call fnc_occupations_init;
  };
  };
  //opfor afghan
  if (opforactive) then {
    case 6: {
      [(_this select 0),(_this select 3),(_this select 1),(configfile >> "CfgGroups" >> "East" >> "LOP_AM_OPF" >> "Infantry" >> "LOP_AM_OPF_Fireteam"),0,east] call fnc_occupations_init;
      [(_this select 0),(_this select 3),(_this select 1),(configfile >> "CfgGroups" >> "East" >> "LOP_AM_OPF" >> "Infantry" >> "LOP_AM_OPF_Support_section"),1,east] call fnc_occupations_init;
      [(_this select 0),(_this select 3),(_this select 1),hds_liste_vehicule_afghan,2,east] call fnc_occupations_init;
      };
    };
  //opfor etat islamique
    if (opforactive) then {
      case 7: {
        [(_this select 0),(_this select 3),(_this select 1),(configfile >> "CfgGroups" >> "East" >> "LOP_ISTS_OPF" >> "Infantry" >> "PO_ISTS_OPF_inf_MG_ft"),0,east] call fnc_occupations_init;
        [(_this select 0),(_this select 3),(_this select 1),(configfile >> "CfgGroups" >> "East" >> "LOP_ISTS_OPF" >> "Infantry" >> "PO_ISTS_OPF_inf_WEAP_SEC"),1,east] call fnc_occupations_init;
        [(_this select 0),(_this select 3),(_this select 1),hds_liste_vehicule_islamique,2,east] call fnc_occupations_init;
        };
      };
  default {
    [(_this select 0),(_this select 3),(_this select 1),(configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "UInfantry" >> "OIA_GuardSquad"),0,east] call fnc_occupations_init;
    [(_this select 0),(_this select 3),(_this select 1),(configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "UInfantry" >> "OIA_GuardTeam"),1,east] call fnc_occupations_init;
    [(_this select 0),(_this select 3),(_this select 1),hds_liste_vehicule_csat,2,east] call fnc_occupations_init;
  };
};


//-----------------------------------------------------------------------------------
