params ["_centre","_distanceApproche","_vehicule"];
if(hdssysteme)then{[format["%1 : Véhicule exécute extraction vers point extrat",hdstactiqueversion]] remoteexeccall ['systemChat',0]};
//le passe ne mode recherche et destruction
(_this select 2) setcombatmode "RED";
[(_this select 2),(_this select 0)] call bis_fnc_taskAttack;
//Une fois proche de la dernier position connu de ses ennemi, il passera en mode patrouille dans le secteur
waituntil {(leader (_this select 2)) inarea [(_this select 0),150,150,0,false,-1]};
[(_this select 2),(_this select 0),(_this select 1)] call CBA_fnc_taskpatrol;
if(hdssysteme)then{[format["%1 : Véhicule exécute patrouiller dans le secteur patrol",hdstactiqueversion]] remoteexeccall ['systemChat',0]};
true
