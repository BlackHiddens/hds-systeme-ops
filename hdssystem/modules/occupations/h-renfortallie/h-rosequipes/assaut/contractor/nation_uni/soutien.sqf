comment "Exported from Arsenal by Hiddens";
params ["_objet"];
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
(_this select 0) forceAddUniform "LOP_U_UN_Fatigue_01";
(_this select 0) addItemToUniform "FirstAidKit";
(_this select 0) addItemToUniform "rhs_mag_rdg2_white";
(_this select 0) addItemToUniform "rhs_mag_rgd5";
(_this select 0) addVest "LOP_V_6B23_Rifleman_UN";
(_this select 0) addBackpack "LOP_CDF_Fieldpack_PKM";
for "_i" from 1 to 3 do {(_this select 0) addItemToBackpack "rhs_100Rnd_762x54mmR";};
(_this select 0) addHeadgear "LOP_H_6B27M_ess_UN";

comment "Add weapons";
(_this select 0) addWeapon "rhs_weap_pkm";

comment "Add items";
(_this select 0) linkItem "ItemMap";
(_this select 0) linkItem "ItemCompass";
(_this select 0) linkItem "ItemWatch";
(_this select 0) linkItem "ItemRadio";

comment "Set identity";
(_this select 0) setFace "WhiteHead_01";
(_this select 0) setSpeaker "rhs_male01rus";
