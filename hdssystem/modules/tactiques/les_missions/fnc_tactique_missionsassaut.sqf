params ["_centre","_distanceApproche","_groupedecombat"];
(_this select 2) move (_this select 0);
if(hdssysteme)then{[format["%1 : %2 fait mouvement vers point d'insertion",hdstactiqueversion,_groupedecombat]] remoteexeccall ['systemChat',0]};
//Le groupe de combat passe en mode recherche
waituntil {(selectrandom units (_this select 2)) inarea [(_this select 0),100,100,0,false,-1]};
if(hdssysteme)then{[format["%1 : %2 exécute recherche et détruire sur point attack",hdstactiqueversion,_groupedecombat]] remoteexeccall ['systemChat',0]};
[(_this select 2),(_this select 0)] call BIS_fnc_taskAttack;
waituntil {((leader (_this select 2)) inarea [(_this select 0),10,10,0,false,-1])
or
((count (units (_this select 2)))isequalto 0)
or
stopped (leader (_this select 2))
};
//Si il ne sont pas mort il patrouille dans le secteur
if((count (units (_this select 2))) > 0) then {
  [(_this select 2),(_this select 0)] call bis_fnc_taskDefend;
  if(hdssysteme)then{[format["%1 : %2 exécute défendre le point attack",hdstactiqueversion,_groupedecombat]] remoteexeccall ['systemChat',0]};
};

true
