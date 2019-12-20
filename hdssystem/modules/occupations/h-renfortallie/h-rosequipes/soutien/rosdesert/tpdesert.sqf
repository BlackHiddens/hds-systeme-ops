
params ["_soldat"];

removeAllWeapons (_this select 0);
removeAllItems (_this select 0);
removeAllAssignedItems (_this select 0);
removeUniform (_this select 0);
removeVest (_this select 0);
removeBackpack (_this select 0);
removeHeadgear (_this select 0);
removeGoggles (_this select 0);


(_this select 0) forceAddUniform "NatoU_USD_rs";
for "_i" from 1 to 2 do {(_this select 0) addItemToUniform "ACE_IR_Strobe_Item";};
for "_i" from 1 to 10 do {(_this select 0) addItemToUniform "ACE_elasticBandage";};
for "_i" from 1 to 10 do {(_this select 0) addItemToUniform "ACE_packingBandage";};
for "_i" from 1 to 4 do {(_this select 0) addItemToUniform "ACE_tourniquet";};
(_this select 0) addItemToUniform "ACE_microDAGR";
(_this select 0) addItemToUniform "ACE_Flashlight_XL50";
(_this select 0) addItemToUniform "ACE_Fortify";
(_this select 0) addItemToUniform "ACE_EarPlugs";
(_this select 0) addVest "rhsusf_mbav_rifleman";
for "_i" from 1 to 2 do {(_this select 0) addItemToVest "SmokeShellGreen";};
for "_i" from 1 to 2 do {(_this select 0) addItemToVest "rhsusf_mag_15Rnd_9x19_JHP";};
for "_i" from 1 to 10 do {(_this select 0) addItemToVest "20Rnd_762x51_Mag";};
(_this select 0) addHeadgear "BoonieH_USD";
(_this select 0) addGoggles "G_Tactical_Clear";


(_this select 0) addWeapon "srifle_DMR_06_camo_F";
(_this select 0) addPrimaryWeaponItem "optic_AMS_snd";
(_this select 0) addPrimaryWeaponItem "bipod_02_F_tan";
(_this select 0) addWeapon "rhsusf_weap_m9";
(_this select 0) addWeapon "Laserdesignator_01_khk_F";


(_this select 0) linkItem "ItemMap";
(_this select 0) linkItem "ItemCompass";
(_this select 0) linkItem "tf_microdagr";
(_this select 0) linkItem "tf_anprc152_3";
(_this select 0) linkItem "NVGoggles";


(_this select 0) setFace "WhiteHead_08";
(_this select 0) setSpeaker "ace_novoice";
