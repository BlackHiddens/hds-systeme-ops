params ["_joueur"];

_action = ["soinentorce","Fracture","hdssystem\images\bandage_fracture_small.paa", {
  [10,[_target,_caller],{hint "Attelle installée";_args select 0 setdammage 0},{},"Installation de l'attelle"] call ace_common_fnc_progressBar;
  },{true}] call ace_interact_menu_fnc_createAction;
  //Application de l'action sur les autres hommes de arma 3
  ["Man",0,["ACE_MainActions"], _action, true] call ace_interact_menu_fnc_addActionToClass;
  //Application de l'action sur le propre Chirurgien
  [(_this select 0),1,["ACE_SelfActions"], _action] call ace_interact_menu_fnc_addActionToObject;
