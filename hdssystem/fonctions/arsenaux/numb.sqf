params ["_objet"];
//initialise un tableau de tableau qui sera le contenu globale de l'arsenal
_tous_les_equipements = [];
//Activer les équipement de RHSUSAF et RHSAFRF

  _tous_les_equipements append
  [
  "rhs_weap_m249_pip_S",
  "rhsusf_acc_nt4_black",
  "rhsusf_acc_M2A1",
  "rhsusf_200Rnd_556x45_box",
  "rhs_weap_M136_hp",
  "rhs_m136_hp_mag",
  "rhs_m72a7_mag",
  "rhs_acc_dtk4long",
  "rhs_weap_m72a7",
  "rhs_weap_ak104_zenitco01_b33",
  "rhs_acc_dtk",
  "rhsusf_acc_su230_mrds",
  "rhs_30Rnd_762x39mm_polymer",
  "rhs_acc_grip_ffg2",
  "rhsusf_weap_m9",
  "rhsusf_mag_15Rnd_9x19_JHP",
  "rhs_30Rnd_762x39mm_polymer_tracer",
  "rhs_acc_dtk4long",
  "rhsusf_mag_15Rnd_9x19_FMJ",
  "rhs_30Rnd_762x39mm",
  "rhs_weap_hk416d10_m320",
  "rhsusf_acc_nt4_black",
  "rhs_mag_30Rnd_556x45_M855A1_Stanag",
  "rhs_weap_M136_hedp",
  "rhs_m136_hedp_mag",
  "rhsusf_weap_glock17g4",
  "rhsusf_mag_17Rnd_9x19_JHP",
  "rhs_mag_30Rnd_556x45_M855A1_Stanag",
  "rhs_m72a7_mag",
  "rhs_m136_hedp_mag",
  "rhsusf_mag_17Rnd_9x19_JHP",
  "rhs_weap_hk416d10_LMT",
  "rhsusf_acc_SF3P556",
  "rhsusf_acc_anpeq15_bk_light",
  "rhs_mag_30Rnd_556x45_M855A1_Stanag",
  "rhsusf_acc_rvg_blk"
  ];

//Activer les équipement du mods ACE

  _tous_les_equipements append
  [
  "ACE_CableTie",
  "ACE_Flashlight_XL50",
  "ACE_Clacker",
  "ACE_EarPlugs",
  "ACE_microDAGR",
  "ACE_elasticBandage",
  "ACE_packingBandage",
  "ACE_fieldDressing",
  "ACE_tourniquet",
  "ACE_morphine",
  "ACE_adenosine",
  "ACE_atropine",
  "ACE_epinephrine",
  "ACE_elasticBandage",
  "ACE_packingBandage",
  "ACE_tourniquet",
  "ACE_morphine",
  "ACE_epinephrine",
  "ACE_IR_Strobe_Item",
  "ACE_Kestrel4500",
  "ACE_surgicalKit",
  "ACE_quikclot",
  "ACE_Flashlight_XL50",
  "ACE_CableTie",
  "ACE_M84",
  "ACE_Altimeter",
  "ACE_acc_pointer_green",
  "ACE_NVG_Gen4"
  ];

//Activer les équipement du mods Project numb 3

  _tous_les_equipements append
  [
  "Cheast_1",
  "Paac6k13",
  "Numb_3_Glasses_4",
  "tf_anprc152",
  "Vasquez_Camos_M1",
  "Vasquez_Vest_LBT3",
  "Vasquez_Camos_M13",
  "tf_anprc152_1",
  "Vasquez_Headgear_Ops_1",
  "Paac6k09",
  "Vasquez_Camos_M3",
  "Vasquez_Headgear_Ops_4",
  "FAPC_MC_1",
  "Vasquez_Camos_M25",
  "Vasquez_Vest_LBT11",
  "Paac6k12"
  ];

//Activer le reste des objets ArmA3 vanilla
_tous_les_equipements append
[
"ItemMap",
"ItemGPS",
"ItemCompass",
"hgun_Pistol_heavy_01_F",
"muzzle_snds_acp",
"acc_flashlight_pistol",
"optic_MRD",
"11Rnd_45ACP_Mag",
"H_Booniehat_khk_hs",
"HandGrenade",
"SmokeShell",
"SmokeShellOrange",
"DemoCharge_Remote_Mag",
"Binocular",
"G_Combat",
"Laserdesignator_01_khk_F",
"Laserbatteries",
"optic_holosight_blk_f",
"1Rnd_HE_Grenade_shell",
"optic_Hamr",
"hgun_Pistol_heavy_02_F",
"6Rnd_45ACP_Cylinder",
"Laserdesignator",
"Laserbatteries",
"B_UavTerminal"
];

//Activation de l'arsenal avec le contenu adequat
[(_this select 0),_tous_les_equipements] call ace_arsenal_fnc_initBox;

true
