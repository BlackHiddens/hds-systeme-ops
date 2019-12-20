params ["_position_base","_ratio","_faction","_taille","_camps"];

//installation d'une compagnie
[(_this select 0),(_this select 1),(_this select 2),(_this select 3)] call fnc_hds_occupations;

//installation d'équipements d'appuis
switch ((_this select 2)) do {
    case 0: {
        [
        ([(_this select 0),1,(_this select 3),10,0,5] call BIS_fnc_findSafePos),0,
        "O_Heli_Attack_02_dynamicLoadout_F",(_this select 4)
        ] call bis_fnc_spawnvehicle;
            };
    case 1: {
      [
      ([(_this select 0),1,(_this select 3),10,0,5] call BIS_fnc_findSafePos),0,
      "I_Heli_light_03_dynamicLoadout_F",(_this select 4)
      ] call bis_fnc_spawnvehicle;
    };
    case 2: {
      [
      ([(_this select 0),1,(_this select 3),10,0,5] call BIS_fnc_findSafePos),0,
      "B_Heli_Attack_01_dynamicLoadout_F",(_this select 4)
      ] call bis_fnc_spawnvehicle;
    };
    case 3: {
      [
      ([(_this select 0),1,(_this select 3),10,0,5] call BIS_fnc_findSafePos),0,
      "C_Heli_Light_01_civil_F",(_this select 4)
      ] call bis_fnc_spawnvehicle;
    };
    case 4: {
      [
      ([(_this select 0),1,(_this select 3),10,0,5] call BIS_fnc_findSafePos),0,
      "LOP_BH_Truck",(_this select 4)
      ] call bis_fnc_spawnvehicle;
    };
    case 5: {
      [
      ([(_this select 0),1,(_this select 3),10,0,5] call BIS_fnc_findSafePos),0,
      "RHS_Mi24P_vdv",(_this select 4)
      ] call bis_fnc_spawnvehicle;
    };
    case 6: {
      [
      ([(_this select 0),1,(_this select 3),10,0,5] call BIS_fnc_findSafePos),0,
      "LOP_AM_OPF_Truck",(_this select 4)
      ] call bis_fnc_spawnvehicle;
    };
};

//installation d'un hélicoptere de combat
