params ["_tache_scenario","_renumeration","_pointdevehicule"];

tache_scenario = _this select 0;
renumeration = _this select 1;publicvariable "renumeration";
pointdevehicule = _this select 2;publicVariable "pointdevehicule";

waituntil{count allplayers > 0};
