params ["_Position","_Cible","_NomCible","_Description"];

_Position = _this select 0;     // position de la mission complète
_Cible = _this select 1;        // Nom de la variable de la cible posé sur carte
_NomCible = _this select 2;     // Nom donné à la cible
_Description = _this select 3;  //Description de la tache

_rnum = str(round (random 999));
_coord =  _Position;

_Condition = format ["[ThisTrigger,%1] call bis_fnc_intrigger",_Cible];
_QuandActiver = format [""];

_NomMarqueurLiveraison = format ["MLivrerPerso%1",_rnum];
_MarqueurLiveraison = createMarker [_NomMarqueurLiveraison,_coord];
_MarqueurLiveraison setMarkerShape "Ellipse";
_MarqueurLiveraison setMarkerSize [15,15];
_MarqueurLiveraison setMarkerColor "colorWEST";
_MarqueurLiveraison setMarkerBrush "Horizontal";

_DeclencheurVoler = createTrigger ["EmptyDetector", _coord];
_DeclencheurVoler setTriggerArea [15, 15, 0, false];
_DeclencheurVoler setTriggerActivation ["ANYPLAYER", "PRESENT", true];
_DeclencheurVoler setTriggerStatements [_Condition,_QuandActiver,""];

//Création du marqueur traqueur
_Tracker = createMarker ["TrackerCamionArme",(getpos _Cible)];
_Tracker setmarkerType "o_inf";
//creation de la tache
_tache = "TacheVolerPerso" + _rnum + str(_Position);
_tachetitre = format ["Voler|%1", _NomCible];
[true,[_tache],[_Description,_tachetitre],_coord,0,2,true,"car"] call BIS_fnc_taskCreate;

//Création du traqueur
_Capturer = 0;
while {alive _Cible && Side (Driver _Cible) != west} do {
_Tracker setmarkerPos (getpos _Cible);
sleep 2;
};
deleteMarker _Tracker;
waitUntil {[_DeclencheurVoler,_Cible] call bis_fnc_intrigger || !alive _Cible || [_tache] call BIS_fnc_taskCompleted};

if (!alive _Cible) then {
  [_tache,'FAILED',true] call BIS_fnc_taskSetState;
};

if ([_DeclencheurVoler,_Cible] call bis_fnc_intrigger) then {
  [_tache,'SUCCEEDED',true] call BIS_fnc_taskSetState;
};

waitUntil{[_tache] call BIS_fnc_taskCompleted}; // Nettoage de la tache

deleteMarker _NomMarqueurLiveraison;
sleep 5;
//[_tache] call BIS_fnc_deleteTask;
tache_scenario = tache_scenario + 1;
