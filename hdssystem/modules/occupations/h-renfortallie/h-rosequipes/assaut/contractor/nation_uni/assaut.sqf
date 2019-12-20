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
for "_i" from 1 to 2 do {(_this select 0) addItemToUniform "rhs_30Rnd_545x39_AK";};
(_this select 0) addItemToUniform "rhs_VOG25";
(_this select 0) addVest "LOP_V_6B23_6Sh92_UN";
for "_i" from 1 to 4 do {(_this select 0) addItemToVest "rhs_30Rnd_545x39_AK";};
(_this select 0) addItemToVest "rhs_VOG25";
(_this select 0) addItemToVest "rhs_mag_rdg2_white";
(_this select 0) addItemToVest "rhs_mag_rgd5";
(_this select 0) addHeadgear "LOP_H_6B27M_ess_UN";

comment "Add weapons";
(_this select 0) addWeapon "rhs_weap_ak74m_gp25";
(_this select 0) addPrimaryWeaponItem "rhs_acc_dtk";
(_this select 0) addWeapon "Binocular";

comment "Add items";
(_this select 0) linkItem "ItemMap";
(_this select 0) linkItem "ItemCompass";
(_this select 0) linkItem "ItemWatch";
(_this select 0) linkItem "ItemRadio";

comment "Set identity";
(_this select 0) setFace "WhiteHead_15";
(_this select 0) setSpeaker "rhs_male03rus";
