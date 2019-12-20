params ["_Position","_Cibles","_NomCible","_Description","_Taille","_Visible"];

_Position = _this select 0; // Position de la mission
_Cibles = _this select 1; // Cible de la mission
_NomCible = _this select 2; // Nom de la cible
_Description = _this select 3; // Description de la mission
_Taille = _this select 4;
_Visible = _this select 5; // True ou false visibilité du marqueur sur carte

_rnum = str(round (random 999)); // Génération d'un nombre aléatoire

_Position =  _Position;

//Création du marqueur de mission
_NomMarquer = format ["Detruire_%1",_rnum];
_MarkerZoneMarquer = createMarker [_NomMarquer,_Position];
_MarkerZoneMarquer setMarkerShape "Ellipse";
_MarkerZoneMarquer setMarkerSize [_Taille,_Taille];
_MarkerZoneMarquer setMarkerColor "colorOPFOR";
_MarkerZoneMarquer setMarkerBrush "SolidBorder";
if (_Visible isEqualTo false) then {_MarkerZoneMarquer setMarkerAlpha 0} else {_MarkerZoneMarquer setMarkerAlpha 0.3};

//Création de la tache
_Tache = format ["DetruireCible%1",_rnum];
_TitreTache = format ["Detruire|%1",_NomCible];
//Affiche ou non la tache sur carte selon la paramètre _Visible
if (_Visible isEqualTo false) then {
  [true,[_Tache],[_Description,_TitreTache],objNull,0,2,true,"target"] call BIS_fnc_taskCreate;
} else {
  [true,[_Tache],[_Description,_TitreTache],(_NomMarquer call BIS_fnc_randomPosTrigger),0,2,true,"target"] call BIS_fnc_taskCreate;
};

//Vérifie si tous les objets ont été détruit
_TousMorts = false;
while {_TousMorts isEqualTo false} do {
    _Reponse = 0;
    {
      if (!alive _x) then {_Reponse = _Reponse + 1};
      } forEach _Cibles;
      if (_Reponse == count _Cibles) then {_TousMorts = true};
};


//Attendre que la cible soit détruite
//waitUntil {!alive _Cibles};
//Mission reussite
[_Tache,'SUCCEEDED',true] call BIS_fnc_taskSetState;
waitUntil{[_Tache] call BIS_fnc_taskCompleted};

//Mode nettoyage activé
deleteMarker _NomMarquer;
sleep 10;
//[_tache] call BIS_fnc_deleteTask;
tache_scenario = tache_scenario + 1;
