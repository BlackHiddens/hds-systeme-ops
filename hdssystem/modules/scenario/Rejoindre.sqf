params ["_Position","_NomPosition","_Description","_Taille","_Visible"];

_Position = _this select 0; // Position a rejoindre
_NomCible = _this select 1; // Nom de la position à rejoindre
_Description = _this select 2; // Description de la mission
_Taille = _this select 3; // Taille de la zone à rejoindre
_Visible = _this select 4; //true ou false pour rendre ou non visible la tache sur la carte

_rnum = str(round (random 999)); // Génération d'un nombre aléatoire

_Position =  _Position;

//Création de la tache
_Tache = format ["RejoindrePosition%1",_rnum];
_TitreTache = format ["Rejoindre|%1",_NomPosition];
//Affiche ou non la tache sur carte selon le paramètre <_Visible>
if (_Visible isEqualTo false) then {
  [true,[_Tache],[_Description,_TitreTache],objNull,0,2,true,"Default"] call BIS_fnc_taskCreate;
} else {
  [true,[_Tache],[_Description,_TitreTache],_Position,0,2,true,"Default"] call BIS_fnc_taskCreate;
};
//Création du déclencheur
_DeclencheurArriver = createTrigger ["EmptyDetector", _Position];
_DeclencheurArriver setTriggerArea [_Taille,_Taille,0,false];
_DeclencheurArriver setTriggerActivation ["ANYPLAYER", "PRESENT", true];
_DeclencheurArriver setTriggerStatements ["this", "", ""];

waitUntil {TriggerActivated _DeclencheurArriver};
//waitUntil {SousOff inArea [ "PosFilature",_Taille,_Taille,0,false]};

//Mission reussite
[_Tache,'SUCCEEDED',true] call BIS_fnc_taskSetState;
waitUntil{[_Tache] call BIS_fnc_taskCompleted};

//Mode nettoyage activé
Sleep 10;
/* [_Tache] call BIS_fnc_deleteTask; */
tache_scenario = tache_scenario + 1;
