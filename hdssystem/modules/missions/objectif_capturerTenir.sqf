params ["_Position","_NomZone","_TempsTenir","_Taille","_faction"];

_rnum = str(round (random 999));

//Positionnement de la cible

_Batiments = [(_this select 2),(_this select 0),['house']] call fnc_objectif_liste_batimentsetplaces;     //Liste des batiments dans le zone
if(count _Batiments isequalto 0)exitWith{
  tache_effectuee = tache_effectuee + 1;publicVariable "tache_effectuee";
  if(hdssysteme)then{[format["%1 : L'une des tâche n'a pas pu être créée",hdsversion]] remoteexeccall ['systemChat',0]};
};
_Batiments_occupable = selectRandom (_Batiments select 0);
if(isnil "_Batiments_occupable")exitWith{
  tache_effectuee = tache_effectuee + 1;publicVariable "tache_effectuee";
  if(hdssysteme)then{[format["%1 : L'une des tâche n'a pas pu être créée",hdsversion]] remoteexeccall ['systemChat',0]};
};

//--------------------------Création de marqueur----------------------------------
_marqueurzonedecombat = [(getpos _Batiments_occupable),(_this select 3),"colorOPFOR"] call fnc_objectif_creermarqueur;
_marqueurdemission = [((_marqueurzonedecombat call bis_fnc_randomPosTrigger)),(_this select 3),"colorOPFOR"] call fnc_objectif_creermarqueur;

_marqueurzonedecombat setMarkerAlpha 0;
_marqueurdemission setMarkerAlpha var_mission_transparance_marqueur;

if(hdssysteme)then{_marqueurzonedecombat setMarkerAlpha 1};
if(hdssysteme)then{_marqueurdemission setMarkerAlpha 1};
//--------------------------------------------------------------------------------

//Créatiion du trigger
_condition = format ["this"];
_quandactiver = "";
_quanddesactiver = "";

_declencheur = createtrigger ["emptydetector",(getpos _Batiments_occupable)];
_declencheur settriggerarea [(_this select 3),(_this select 3),0,false,30];
_declencheur settriggeractivation ["west","present",true];
_declencheur setTriggerStatements [_condition,_quandactiver,_quanddesactiver];

//-------------------------Création de la tache pour les joueurs------------------
_tache = "TacheCapturer" + _rnum + str(_this select 0);
_tachetitre = (_this select 1);
_tacheDesc = format ["%1 doit être capturé et tenu pendant %2 de secondes",_NomZone,(_this select 2)];

if(hdssysteme)then{
  [true,[_tache],[_tacheDesc,_tachetitre],(_marqueurzonedecombat call BIS_fnc_randomPosTrigger),0,2,true,"defend"] call BIS_fnc_taskCreate;
}else{
  [true,[_tache],[_tacheDesc,_tachetitre],objnull,0,2,true,"defend"] call BIS_fnc_taskCreate;
};
//----------------------------------------------------------------------------------

//---------------------------Attente que la zone soit investi par le leader du groupe-------------------
while {(leader group (selectRandom Allplayers)) isequalto Objnull} do {
  sleep 10;
};

waitUntil {[_Declencheur,(getpos leader group (selectRandom allplayers))] call bis_fnc_intrigger};
//--------------------------------------------------------------------------------

//---Création du déclencheur de tenir la position une fois la position contrôlé---
[] spawn {
  ["AmbientTrack04b_F_Tacops"] remoteExec ["PlayMusic",0];
  sleep 75;
  ["EventTrack03a_F_Tacops"] remoteExec ["PlayMusic",0];
};

//-------------Génerer des attaquants supplémentaire--------------------------------
[(getpos _declencheur),3,(selectrandom [0,1,2,3]),250,(_this select 4),true] spawn fnc_tactique_contreattaque;

[[West,"Base"],"Des contacts ennemi sont en progression sur votre position"] remoteExec ["SideChat",0];

_Chrono = 0;
while {(_this select 2) != _Chrono} do {
  [format ["Temps à tenir : %1 sur %2",_Chrono,(_this select 2)]] remoteExec ["hint",0];
  _Chrono = (_Chrono + 1);
  sleep 1;
};

waitUntil {_Chrono == (_this select 2)};
//---------------------------------------------------------------------------------

//------------------Création du trigger de vérification
if ([_marqueurzonedecombat,leader group (selectRandom Allplayers)] call bis_fnc_intrigger) then {
  [_tache,'SUCCEEDED',true] call BIS_fnc_taskSetState;

  ["Félicitation"] remoteExec ["hint",0];
} else {[_tache,'FAILED',true] call BIS_fnc_taskSetState};

//Après la création du délencheur de vérification, le script attend 5 secondes (histoire de d'être sur que le déclencheur s'installer)
//puis accompli la tache si des blufor sont présent sinon c'est raté.

[_tache] call BIS_fnc_taskCompleted;
deleteMarker _marqueurzonedecombat;
deleteVehicle _declencheur;                                          //Supprime le marquer sur carte

tache_effectuee = tache_effectuee + 1;publicVariable "tache_effectuee";
true
