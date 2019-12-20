comment "Exported from Arsenal by Hiddens";
params ["_soldat"];
comment "Remove existing items";
removeAllWeapons (_this select 0);
removeAllItems (_this select 0);
removeAllAssignedItems (_this select 0);
removeUniform (_this select 0);
removeVest (_this select 0);
removeBackpack (_this select 0);
removeHeadgear (_this select 0);
removeGoggles (_this select 0);

comment "Add containers";
(_this select 0) forceAddUniform "LOP_U_AM_Fatigue_02_4";
(_this select 0) addItemToUniform "FirstAidKit";
for "_i" from 1 to 4 do {(_this select 0) addItemToUniform "rhs_30Rnd_762x39mm";};
(_this select 0) addItemToUniform "rhs_mag_rdg2_white";
(_this select 0) addItemToUniform "rhs_mag_rgd5";
(_this select 0) addHeadgear "LOP_H_Turban_mask";

comment "Add weapons";
(_this select 0) addWeapon "rhs_weap_akm";
(_this select 0) addPrimaryWeaponItem "rhs_acc_dtkakm";

comment "Add items";
(_this select 0) linkItem "ItemMap";
(_this select 0) linkItem "ItemCompass";
(_this select 0) linkItem "ItemRadio";

comment "Set identity";
(_this select 0) setFace "PersianHead_A3_02";
(_this select 0) setSpeaker "male01per";
