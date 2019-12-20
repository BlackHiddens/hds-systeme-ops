params ["_soldat"];

switch (selectrandom [0,1,2]) do {
    case 0 : {
      comment "[!] UNIT MUST BE LOCAL [!]";
      if (!local (_this select 0)) exitWith {};

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
      (_this select 0) forceAddUniform "U_B_CombatUniform_mcam";
      (_this select 0) addItemToUniform "FirstAidKit";
      (_this select 0) addVest "V_PlateCarrier2_rgr";
      for "_i" from 1 to 2 do {(_this select 0) addItemToVest "16Rnd_9x21_Mag";};
      (_this select 0) addItemToVest "SmokeShell";
      (_this select 0) addItemToVest "SmokeShellGreen";
      for "_i" from 1 to 2 do {(_this select 0) addItemToVest "Chemlight_green";};
      for "_i" from 1 to 8 do {(_this select 0) addItemToVest "rhs_mag_30Rnd_556x45_M855A1_PMAG";};
      for "_i" from 1 to 4 do {(_this select 0) addItemToVest "HandGrenade";};
      (_this select 0) addBackpack "B_AssaultPack_rgr_LAT2";
      (_this select 0) addHeadgear "H_HelmetB_light_desert";
      (_this select 0) addGoggles "G_Balaclava_blk";

      comment "Add weapons";
      (_this select 0) addWeapon "arifle_SPAR_01_blk_F";
      (_this select 0) addPrimaryWeaponItem "optic_Hamr";
      (_this select 0) addPrimaryWeaponItem "bipod_01_F_blk";
      (_this select 0) addWeapon "hgun_P07_F";

      comment "Add items";
      (_this select 0) linkItem "ItemMap";
      (_this select 0) linkItem "ItemCompass";
      (_this select 0) linkItem "ItemWatch";
      (_this select 0) linkItem "ItemRadio";

      comment "Set identity";
      [(_this select 0),"GreekHead_A3_07","male04eng"] call BIS_fnc_setIdentity;
    };
    case 1: {

      comment "Exported from Arsenal by Hiddens";

      comment "[!] UNIT MUST BE LOCAL [!]";
      if (!local (_this select 0)) exitWith {};

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
      (_this select 0) forceAddUniform "U_B_CombatUniform_mcam";
      (_this select 0) addItemToUniform "FirstAidKit";
      (_this select 0) addVest "V_PlateCarrier2_rgr";
      for "_i" from 1 to 2 do {(_this select 0) addItemToVest "16Rnd_9x21_Mag";};
      (_this select 0) addItemToVest "SmokeShell";
      (_this select 0) addItemToVest "SmokeShellGreen";
      for "_i" from 1 to 2 do {(_this select 0) addItemToVest "Chemlight_green";};
      for "_i" from 1 to 8 do {(_this select 0) addItemToVest "rhs_mag_30Rnd_556x45_M855A1_PMAG";};
      for "_i" from 1 to 4 do {(_this select 0) addItemToVest "HandGrenade";};
      (_this select 0) addBackpack "B_AssaultPack_rgr_LAT2";
      (_this select 0) addHeadgear "H_HelmetB_camo";
      (_this select 0) addGoggles "G_Balaclava_blk";

      comment "Add weapons";
      (_this select 0) addWeapon "arifle_SPAR_01_blk_F";
      (_this select 0) addPrimaryWeaponItem "optic_Hamr";
      (_this select 0) addPrimaryWeaponItem "bipod_01_F_blk";
      (_this select 0) addWeapon "launch_NLAW_F";
      (_this select 0) addWeapon "hgun_P07_F";

      comment "Add items";
      (_this select 0) linkItem "ItemMap";
      (_this select 0) linkItem "ItemCompass";
      (_this select 0) linkItem "ItemWatch";
      (_this select 0) linkItem "ItemRadio";

      comment "Set identity";
      [(_this select 0),"AfricanHead_01","male12eng"] call BIS_fnc_setIdentity;

    };

    case 2: {

        comment "Exported from Arsenal by Hiddens";

        comment "[!] UNIT MUST BE LOCAL [!]";
        if (!local (_this select 0)) exitWith {};

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
        (_this select 0) forceAddUniform "U_B_CombatUniform_mcam";
        (_this select 0) addItemToUniform "FirstAidKit";
        (_this select 0) addVest "V_PlateCarrier2_rgr";
        for "_i" from 1 to 2 do {(_this select 0) addItemToVest "16Rnd_9x21_Mag";};
        (_this select 0) addItemToVest "SmokeShell";
        (_this select 0) addItemToVest "SmokeShellGreen";
        for "_i" from 1 to 2 do {(_this select 0) addItemToVest "Chemlight_green";};
        for "_i" from 1 to 7 do {(_this select 0) addItemToVest "rhs_mag_30Rnd_556x45_M855A1_PMAG";};
        for "_i" from 1 to 4 do {(_this select 0) addItemToVest "HandGrenade";};
        (_this select 0) addItemToVest "1Rnd_HE_Grenade_shell";
        (_this select 0) addBackpack "B_AssaultPack_rgr_LAT2";
        for "_i" from 1 to 4 do {(_this select 0) addItemToBackpack "1Rnd_HE_Grenade_shell";};
        (_this select 0) addGoggles "G_Balaclava_blk";

        comment "Add weapons";
        (_this select 0) addWeapon "arifle_SPAR_01_GL_blk_F";
        (_this select 0) addPrimaryWeaponItem "optic_Hamr";
        (_this select 0) addWeapon "hgun_P07_F";

        comment "Add items";
        (_this select 0) linkItem "ItemMap";
        (_this select 0) linkItem "ItemCompass";
        (_this select 0) linkItem "ItemWatch";
        (_this select 0) linkItem "ItemRadio";

        comment "Set identity";
        [(_this select 0),"WhiteHead_19","male04eng"] call BIS_fnc_setIdentity;

    };
};
