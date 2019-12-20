comment "Exported from Arsenal by Defconleader"
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


(_this select 0) forceAddUniform "CamoU_CCE_U";
for "_i" from 1 to 2 do {(_this select 0) addItemToUniform "ACE_IR_Strobe_Item";};
for "_i" from 1 to 10 do {(_this select 0) addItemToUniform "ACE_elasticBandage";};
for "_i" from 1 to 10 do {(_this select 0) addItemToUniform "ACE_packingBandage";};
for "_i" from 1 to 4 do {(_this select 0) addItemToUniform "ACE_tourniquet";};
(_this select 0) addItemToUniform "ACE_microDAGR";
(_this select 0) addItemToUniform "ACE_Flashlight_XL50";
(_this select 0) addItemToUniform "ACE_Fortify";
(_this select 0) addItemToUniform "ACE_EarPlugs";
(_this select 0) addVest "AAFVest01_l_black";
for "_i" from 1 to 3 do {(_this select 0) addItemToVest "SmokeShellGreen";};
for "_i" from 1 to 3 do {(_this select 0) addItemToVest "rhsusf_mag_15Rnd_9x19_JHP";};
(_this select 0) addItemToVest "HandGrenade";
for "_i" from 1 to 7 do {(_this select 0) addItemToVest "rhs_mag_30Rnd_556x45_M855_Stanag";};
(_this select 0) addBackpack "B_AssaultPack_blk";
for "_i" from 1 to 2 do {(_this select 0) addItemToBackpack "MRAWS_HEAT_F";};
(_this select 0) addItemToBackpack "MRAWS_HE_F";
(_this select 0) addHeadgear "CamoH_CCE_U";
(_this select 0) addGoggles "rhs_googles_black";


(_this select 0) addWeapon "rhs_weap_m4a1_carryhandle";
(_this select 0) addPrimaryWeaponItem "rhsusf_acc_anpeq15_bk_light";
(_this select 0) addPrimaryWeaponItem "rhsusf_acc_eotech_552";
(_this select 0) addPrimaryWeaponItem "rhsusf_acc_grip3";
(_this select 0) addWeapon "launch_MRAWS_green_rail_F";
(_this select 0) addSecondaryWeaponItem "rhsusf_acc_anpeq15side_bk";
(_this select 0) addWeapon "rhsusf_weap_m9";
(_this select 0) addWeapon "Laserdesignator_01_khk_F";


(_this select 0) linkItem "ItemMap";
(_this select 0) linkItem "ItemCompass";
(_this select 0) linkItem "tf_microdagr";
(_this select 0) linkItem "tf_anprc152_3";
(_this select 0) linkItem "NVGoggles_OPFOR";


(_this select 0) setFace "WhiteHead_08";
(_this select 0) setSpeaker "ace_novoice";
