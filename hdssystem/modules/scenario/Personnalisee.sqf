params ["_Position","_ConditionReussite","_ConditionEchec","_NomTache","_Description","_Taille","_Visible"];

_rnum = str(round (random 999)); // Génération d'un nombre aléatoire
_Position =  (_this select 0);

//Création du marqueur de mission
_NomMarquer = format ["Personnalisee_%1",_rnum];
_MarkerZoneMarquer = createMarker [_NomMarquer,_Position];
_MarkerZoneMarquer setMarkerShape "Ellipse";
_MarkerZoneMarquer setMarkerSize [(_this select 5),(_this select 5)];
_MarkerZoneMarquer setMarkerColor "colorOPFOR";
_MarkerZoneMarquer setMarkerBrush "SolidBorder";
if ((_this select 6) isEqualTo false) then {_MarkerZoneMarquer setMarkerAlpha 0} else {_MarkerZoneMarquer setMarkerAlpha 0.3};

//Création de la tache
_Tache = format ["PersonnaliseeCible%1",_rnum];
_TitreTache = format ["Exécuter|%1",(_this select 3)];
//Affiche ou non la tache sur carte selon la paramètre _Visible
if ((_this select 6) isEqualTo false) then {
  [true,[_Tache],[(_this select 4),_TitreTache],objNull,0,2,true,"whiteboard"] call BIS_fnc_taskCreate;
} else {
  [true,[_Tache],[(_this select 4),_TitreTache],(_NomMarquer call BIS_fnc_randomPosTrigger),0,2,true,"whiteboard"] call BIS_fnc_taskCreate;
};

waituntil {triggeractivated (_this select 1) or triggeractivated (_this select 2)};

if (triggeractivated (_this select 1)) then {[_tache,'SUCCEEDED',true] call BIS_fnc_taskSetState};
if (triggeractivated (_this select 2)) then {[_tache,'FAILED',true] call BIS_fnc_taskSetState};

waitUntil{[_tache] call BIS_fnc_taskCompleted};

deleteMarker _NomMarquer;
sleep 10;
//[_tache] call BIS_fnc_deleteTask;
tache_scenario = tache_scenario + 1;
