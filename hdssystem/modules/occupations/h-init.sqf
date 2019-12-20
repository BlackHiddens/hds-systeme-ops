//------------------------------------------Occupations----------------------------------------
/*
Description : Les tableau ci-dessous sont utilisés par les scripts de hds.systeme
*/

//Tableau des civils à pied------------------------------
hds_liste_civil_europeens = ["C_man_polo_1_F_afro",
"C_man_1_3_F",
"C_man_polo_2_F_euro",
"C_man_polo_4_F_euro",
"C_man_polo_5_F_afro",
"C_man_polo_6_F_asia",
"C_man_p_beggar_F",
"C_man_hunter_1_F",
"C_Orestes","C_Nikos",
"C_Nikos_aged",
"C_man_sport_2_F",
"C_Man_casual_1_F_asia",
"C_Man_ConstructionWorker_01_Vrana_F"];
//tableau des véhicules civils
hds_liste_vehicule_civil_europeens = ["C_Offroad_01_F",
"C_Offroad_default_F",
"C_Quadbike_01_F",
"C_Truck_02_covered_F",
"C_Hatchback_01_sport_F",
"C_SUV_01_F","C_Truck_02_fuel_F",
"C_Truck_02_box_F","C_Van_01_fuel_F",
"C_Offroad_02_unarmed_F"];

//Unités africaines de l'addon opfor----------------------
if (opforactive isEqualTo true) then {

    hds_liste_vehicule_bokoharam =
    [
    "LOP_AFR_OPF_Offroad_M2",
    "LOP_AFR_OPF_Offroad",
    "LOP_AFR_OPF_Nissan_PKM",
    "LOP_AFR_OPF_Landrover_SPG9",
    "LOP_AFR_OPF_Landrover_M2",
    "LOP_AFR_OPF_Landrover"
    ];

  //Liste des véhicules d'Ainkada
    hds_liste_vehicule_afghan = [
    "LOP_AM_OPF_UAZ_AGS",
    "LOP_AM_OPF_UAZ_DshKM",
    "LOP_AM_OPF_UAZ_SPG",
    "LOP_AM_OPF_BM21",
    "LOP_AM_OPF_Landrover_M2",
    "LOP_AM_OPF_BTR60"
    ];

    //Liste d'unités civils arabes
    hds_liste_civil_arabes = [
    "LOP_Tak_Civ_Random"
    ];
    //Liste des véhicules civils arabes
    hds_liste_vehicule_civil_arabes = [
    "LOP_TAK_Civ_Ural",
    "LOP_TAK_Civ_Ural_open",
    "LOP_TAK_Civ_UAZ_Open",
    "LOP_TAK_Civ_UAZ",
    "LOP_TAK_Civ_Hatchback",
    "LOP_TAK_Civ_Landrover",
    "LOP_TAK_Civ_Offroad"
    ];
    //liste de véhicules civils africain
    hds_liste_vehicule_civil_africain = [
    "LOP_AFR_Civ_Landrover",
    "LOP_AFR_Civ_UAZ",
    "LOP_AFR_Civ_UAZ_Open",
    "LOP_AFR_Civ_Ural",
    "LOP_AFR_Civ_Ural_open"
    ];
    //liste de personnel civils africain
    hds_liste_civil_africain = [
    "LOP_AFR_Civ_Man_01",
    "LOP_AFR_Civ_Man_01_S",
    "LOP_AFR_Civ_Man_02",
    "LOP_AFR_Civ_Man_02_S",
    "LOP_AFR_Civ_Man_05",
    "LOP_AFR_Civ_Man_05",
    "LOP_AFR_Civ_Man_06",
    "LOP_AFR_Civ_Man_06_S"
    ];
    //Liste de véhicules militaire de l'état islamique
    hds_liste_vehicule_islamique = [
    "LOP_ISTS_OPF_T34",
    "LOP_ISTS_OPF_Landrover_M2",
    "LOP_ISTS_OPF_Landrover_SPG9",
    "LOP_ISTS_OPF_M1025_W_Mk19",
    "LOP_ISTS_OPF_M998_D_4DR",
    "LOP_ISTS_OPF_Nissan_PKM",
    "LOP_ISTS_OPF_Offroad_M2",
    "LOP_ISTS_OPF_Offroad_AT",
    "LOP_ISTS_OPF_BMP2",
    "LOP_ISTS_OPF_BMP1",
    "LOP_ISTS_OPF_ZSU234",
    "LOP_ISTS_OPF_Static_ZU23",
    "LOP_ISTS_OPF_Kord_High"
    ];
};

if (afrfactive)then{
  hds_liste_vehicule_rhs_russe = [
  "rhs_btr80a_msv",
  "rhs_btr80_msv",
  "rhs_btr60_msv",
  "RHS_BM21_MSV_01",
  "rhs_t80um",
  "rhs_bmp1d_tv",
  "rhs_bmp2d_tv"
  ];
};
if (rdsactive)then{
  //liste des véhicules russe civil
  hds_liste_vehicule_civil_russe = [
  "RDS_Gaz24_Civ_03",
  "RDS_Gaz24_Civ_01",
  "RDS_Gaz24_Civ_02",
  "RDS_Golf4_Civ_01",
  "RDS_Ikarus_Civ_02",
  "RDS_S1203_Civ_01",
  "RDS_Zetor6945_Base",
  "RDS_Lada_Civ_01",
  "RDS_Lada_Civ_03",
  "RDS_Lada_Civ_02",
  "RDS_tt650_Civ_01",
  "RDS_MMT_Civ_01",
  "RDS_Ikarus_Civ_01",
  "RDS_Gaz24_Civ_02",
  "RDS_tt650_Civ_01",
  "RDS_MMT_Civ_01"
  ];
  //liste de personnel civil russe
  hds_liste_civil_russe = [
  "RDS_Rocker2",
  "RDS_Worker3",
  "RDS_Citizen1",
  "RDS_Citizen3",
  "RDS_Woodlander4",
  "RDS_Woodlander3",
  "RDS_Profiteer3"
  ];

};
  hds_liste_vehicule_csat = [
  "O_MRAP_02_hmg_F",
  "O_APC_Wheeled_02_rcws_F",
  "O_UGV_01_rcws_F",
  "O_MBT_04_command_F",
  "O_MBT_04_cannon_F",
  "O_MBT_02_cannon_F",
  "O_APC_Tracked_02_cannon_F",
  "O_MRAP_gmg_F",
  "O_Mortar_01_F",
  "O_HMG_01_high_F"];

  hds_liste_vehicule_aaf = [
  "I_MRAP_03_F","I_MRAP_03_gmg_F",
  "I_MRAP_03_hmg_F",
  "I_APC_tracked_03_cannon_F",
  "I_UGV_01_rcws_F",
  "I_APC_Wheeled_03_cannon_F",
  "I_LT_01_AT_F",
  "I_LT_01_scout_F",
  "I_LT_01_cannon_F",
  "I_MBT_03_cannon_F"
  ];

  hds_liste_vehicule_blu = [
  "B_MBT_01_arty_F",
  "B_MBT_01_cannon_F",
  "B_MBT_01_mlrs_F",
  "B_APC_Tracked_01_AA_F",
  "B_APC_Tracked_01_CRV_F",
  "B_APC_Tracked_01_rcws_F",
  "B_APC_Wheeled_01_cannon_F",
  "B_MBT_02_cannon_F",
  "B_Truck_01_covered_F",
  "B_Truck_01_transport_F",
  "B_MRAP_01_F",
  "B_MRAP_01_gmg_F","B_MRAP_01_hmg_F",
  "B_Truck_01_medical_F",
  "B_UGV_01_rcws_F"];

  hds_liste_vehicule_fia_opfor = [
  "O_G_Offroad_01_armed_F",
  "O_G_Offroad_01_AT_F",
  "O_G_Mortar_01_F"];

  if(opforactive and rdsactive)then{hds_liste_vehicule_civil_africain append hds_liste_vehicule_civil_russe};

  HFactionennemi = [0,1,3,4,5,6];
  HFactionalliee = [2];

//Initialisation des fonctions

  //Fonctions principales pour génération d'un occupation
  fnc_occupations_init = compile preprocessFile "hdssystem\modules\occupations\h-fncsysteme\hds_occupations_init.sqf";
  fnc_hds_occupations = compile preprocessFile "hdssystem\modules\occupations\h-occupation.sqf";
  fnc_occupations_civil_init = compile preprocessFile "hdssystem\modules\occupations\h-fncsysteme\hds_occupations_civil_init.sqf";

  //Ajouter des actions
  fnc_EstUnTerminalRenfort = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-AjouterActionRenfort.sqf";
  if (usafactive isEqualTo true) then {fnc_EstUnTerminalDeGroupeIARHS = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-groupeiarhs.sqf"};
  fnc_EstUnTerminalDeGroupeIA = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-groupeia.sqf";
  fnc_EstUnTerminalDeGroupePERSO = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-groupeiaperso.sqf";

  //initialise les equipes R.O.S
  if (foxforactive isEqualto true) then {
    fnc_rosequipes = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-rosequipes\h-equipersoldat.sqf";
    //fonction d'assaut de la R.O.S
    fnc_rosfantassinassaut_desert = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-rosequipes\assaut\rosdesert\fantassindesert.sqf";
    fnc_rosgrenadierassaut_desert = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-rosequipes\assaut\rosdesert\grenadierdesert.sqf";
    fnc_rosfantassinassaut_tiger = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-rosequipes\assaut\rostiger\fantassintiger.sqf";
    fnc_rosgrenadierassaut_tiger = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-rosequipes\assaut\rostiger\grenadiertiger.sqf";
    fnc_rosgrenadierassaut_urbain = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-rosequipes\assaut\rosurbain\fantassinurbain.sqf";
    fnc_rosgrenadierassaut_urbain = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-rosequipes\assaut\rosurbain\grenadierurbain.sqf";
    //fonction de soutien de la R.O.S
    fnc_rosfantassinsoutien_desert = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-rosequipes\soutien\rosdesert\fantassindesert.sqf";
    fnc_rosmitrailleursoutien_desert = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-rosequipes\soutien\rosdesert\mitrailleurdesert.sqf";
    fnc_rostpdesertsoutien_desert = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-rosequipes\soutien\rosdesert\tpdesert.sqf";
    fnc_rosacdesertsoutien_desert = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-rosequipes\soutien\rosdesert\acdesert.sqf";

    fnc_rosfantassinsoutien_tiger = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-rosequipes\soutien\rostiger\fantassintiger.sqf";
    fnc_rosmitrailleursoutien_tiger = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-rosequipes\soutien\rostiger\mitrailleurtiger.sqf";
    fnc_rostpdesertsoutien_tiger = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-rosequipes\soutien\rostiger\tptiger.sqf";
    fnc_rosacdesertsoutien_tiger = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-rosequipes\soutien\rostiger\actiger.sqf";

    fnc_rosfantassinsoutien_urbain = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-rosequipes\soutien\rosurbain\fantassinurbain.sqf";
    fnc_rosmitrailleursoutien_urbain = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-rosequipes\soutien\rosurbain\mitrailleururbain.sqf";
    fnc_rostpdesertsoutien_urbain = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-rosequipes\soutien\rosurbain\tpurbain.sqf";
    fnc_rosacdesertsoutien_urbain = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-rosequipes\soutien\rosurbain\acurbain.sqf";

    fnc_roscontractors_desert = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-rosequipes\assaut\contractor\mercenaire.sqf";
    fnc_nationuni_assaut = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-rosequipes\assaut\contractor\nation_uni\assaut.sqf";
    fnc_afgan_classique = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-rosequipes\assaut\afghan\afghan.sqf";
    fnc_americain_polyvalent = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-rosequipes\assaut\vanilla\americain_polyvalent.sqf";
  };

  fnc_renfort_allie = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-RenfortAllie.sqf";
  fnc_renfort_init = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-initrenfortallie.sqf";
  fnc_generer_groupe = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\recrueperso.sqf";
  /*
  A placer dans le fichier h-mission\h-init.sqf(Recommandé) ou le retirer comme commentaire ici

  TerminalDeGroupeIAPERSO = true;publicVariable "TerminalDeGroupeIAPERS";
  TerminalDeGroupeIARHS = true;publicVariable "TerminalDeGroupeIARHS";
  TerminalDeGroupeIA = true;publicVariable "TerminalDeGroupeIA";

  if (TerminalDeGroupeIA) then {[hds_terminal,"Groupe:R.O.S"] remoteExecCall ["fnc_EstUnTerminalDeGroupeIA"]};
  if (TerminalDeGroupeIARHS) then {[hds_terminal,"Groupe:R.H.S"] remoteExecCall ["fnc_EstUnTerminalDeGroupeIA"]};
  if (TerminalDeGroupeIAPERSO)then {[hds_terminal,"Groupe:H.D.S"] remoteExecCall ["fnc_EstUnTerminalDeGroupePERSO"]};

  */
