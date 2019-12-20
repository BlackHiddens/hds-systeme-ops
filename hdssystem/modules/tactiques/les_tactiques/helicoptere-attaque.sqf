/*
Description : Fait apparaitre un hélico d'attaque qui patrouillera autour d'un joueur selectionné aléatoirement.

Exemple :
["Nom_marker",800,3] spawn fnc_tactique_appuihelico;
Spawn un hélico dans les air entre 800+1000 et 800+2000 mètres, qui aura pour mission de patrouiller dans la zone autour d'un joueur

_position = <string> est le nom d'un marqueur
_distanceproche = <integer>
_camps = <integer>

*/
params ["_position","_distanceproche","_camps"];
if(hdssysteme)then{[format["%1 : Mise en place d'un appui dans le secteur",hdstactiqueversion]] remoteexeccall ['systemChat',0]};

switch ((_this select 2)) do {
    //east opfor
    case 0: {[(_this select 0),"O_Heli_Attack_02_dynamicLoadout_F",(_this select 1),east] spawn fnc_tactique_helicocombat};
    //aaf independent
    case 1:{[(_this select 0),"I_Heli_light_03_dynamicLoadout_F",(_this select 1),independent] spawn fnc_tactique_helicocombat};
    //blufor west
    case 2:{[(_this select 0),"B_Heli_Attack_01_dynamicLoadout_F",(_this select 1),west] spawn fnc_tactique_helicocombat};
    //opfor fia
    case 3:{[(_this select 0),"C_Heli_Light_01_civil_F",(_this select 1),east] spawn fnc_tactique_helicocombat};
    //east boko haram
    case 4:{
      [(_this select 0),(configfile >> "CfgGroups" >> "East" >> "LOP_BH" >> "Infantry" >> "LOP_BH_Fireteam"),
      (_this select 1),east,"LOP_BH_Truck",2] spawn fnc_tactique_renfortvehiculer;
    };
    //east russe (rhs_afrf)
    case 5:{[(_this select 0),"RHS_Mi24P_vdv",(_this select 1),east] spawn fnc_tactique_helicocombat};
    //east afghan - taliban
    case 6:{
      [(_this select 0),(configfile >> "CfgGroups" >> "East" >> "LOP_AM_OPF" >> "Infantry" >> "LOP_AM_OPF_Fireteam"),
      (_this select 1),east,"LOP_AM_OPF_Truck",2] spawn fnc_tactique_renfortvehiculer;
    };
    case 7:{
      [(_this select 0),(configfile >> "CfgGroups" >> "East" >> "LOP_ISTS_OPF" >> "Infantry" >> "PO_ISTS_OPF_inf_WEAP_SEC"),
      (_this select 1),east,"LOP_ISTS_OPF_Landrover",2] spawn fnc_tactique_renfortvehiculer;
    };
    //par defaut
    default {[(_this select 0),"C_Heli_Light_01_civil_F",(_this select 1),east] spawn fnc_tactique_helicocombat};
};
