
params ["_soldat"];
//Supprimer les objets existants
removeAllWeapons (_this select 0);
removeAllItems (_this select 0);
removeAllAssignedItems (_this select 0);
removeUniform (_this select 0);
removeVest (_this select 0);
removeBackpack (_this select 0);
removeHeadgear (_this select 0);
removeGoggles (_this select 0);


(_this select 0) forceAddUniform "NatoU_TigerJ_rs";
for "_i" from 1 to 2 do {(_this select 0) addItemToUniform "ACE_IR_Strobe_Item";};
for "_i" from 1 to 10 do {(_this select 0) addItemToUniform "ACE_elasticBandage";};
for "_i" from 1 to 10 do {(_this select 0) addItemToUniform "ACE_packingBandage";};
for "_i" from 1 to 4 do {(_this select 0) addItemToUniform "ACE_tourniquet";};
(_this select 0) addItemToUniform "ACE_microDAGR";
(_this select 0) addItemToUniform "ACE_Flashlight_XL50";
(_this select 0) addItemToUniform "ACE_Fortify";
(_this select 0) addItemToUniform "ACE_EarPlugs";
(_this select 0) addVest "rhsusf_mbav_mg";
for "_i" from 1 to 3 do {(_this select 0) addItemToVest "SmokeShellGreen";};
for "_i" from 1 to 3 do {(_this select 0) addItemToVest "rhsusf_mag_15Rnd_9x19_JHP";};
for "_i" from 1 to 2 do {(_this select 0) addItemToVest "rhs_200rnd_556x45_M_SAW";};
for "_i" from 1 to 4 do {(_this select 0) addItemToVest "rhs_mag_30Rnd_556x45_Mk318_Stanag";};
(_this select 0) addItemToVest "MiniGrenade";
(_this select 0) addBackpack "B_Kitbag_rgr";
for "_i" from 1 to 6 do {(_this select 0) addItemToBackpack "rhs_200rnd_556x45_M_SAW";};
(_this select 0) addHeadgear "CamoH_TigerJ";
(_this select 0) addGoggles "rhsusf_oakley_goggles_blk";


(_this select 0) addWeapon "rhs_weap_m249_pip_S_para";
(_this select 0) addPrimaryWeaponItem "SMA_ANPEQ15_TAN";
(_this select 0) addPrimaryWeaponItem "SMA_ELCAN_SPECTER_RDS";
(_this select 0) addWeapon "rhsusf_weap_m9";
(_this select 0) addWeapon "Laserdesignator_01_khk_F";


(_this select 0) linkItem "ItemMap";
(_this select 0) linkItem "ItemCompass";
(_this select 0) linkItem "tf_microdagr";
(_this select 0) linkItem "tf_anprc152_3";
(_this select 0) linkItem "NVGoggles";


(_this select 0) setFace "WhiteHead_08";
(_this select 0) setSpeaker "ace_novoice";
