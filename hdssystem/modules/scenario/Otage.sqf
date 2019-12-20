params ["_Position","_PositionSauver","_Otages","_NomOtage","_Description","_Taille","_Visible"];

_Position = _this select 0;     // position de la mission complète
_PositionSauver = _this select 1; //Position ou l'otage doit être ramené
_Otages = _this select 2;         // Nom de la variable de l'otage posé sur carte
_NomOtage = _this select 3;     // Nom donné à l'otage
_Description = _this select 4;  //Description de la tache
_Taille = _this select 5;       // Taille du rayon de la zone de mission
_Visible = _this select 6;      // True ou false visibilité du marqueur sur carte

_rnum = str(round (random 999));
_coord =  _Position;
_coordSauve =  _PositionSauver;

_NomMarqueurSauver = format ["MSauverPerso%1",_rnum];
_MarqueurSauver = createMarker [_NomMarqueurSauver,_coordSauve];
_MarqueurSauver setMarkerShape "Ellipse";
_MarqueurSauver setMarkerSize [10,10];
_MarqueurSauver setMarkerColor "colorWEST";
_MarqueurSauver setMarkerBrush "Horizontal";
if (_Visible isEqualTo false) then {_MarqueurSauver  setMarkerAlpha 0} else {_MarqueurSauver  setMarkerAlpha 0.3};

_NomMarquer = format ["otaPerso_%1",_rnum];
_MarkerZone = createMarker [_NomMarquer,_coord];
_MarkerZone setMarkerShape "Ellipse";
_MarkerZone setMarkerSize [_Taille,_Taille];
_MarkerZone setMarkerColor "colorOPFOR";
_MarkerZone setMarkerBrush "SolidBorder";
_MarkerZone setMarkerAlpha 0.3;
if (_Visible isEqualTo false) then {_MarkerZone  setMarkerAlpha 0} else {_MarkerZone  setMarkerAlpha 0.3};

{
  //configuration des l'otages
  _x setcaptive true;
  _x switchmove "Acts_ExecutionVictim_Loop";
  _x setVariable ["_OtagePerso",_x,true];

} forEach _Otages;

//creation de la tache
_tache = "TacheOtagePerso" + _rnum + str(_Position);
_tachetitre = format ["Extraire|%1", _NomOtage];

[true,[_tache],[_Description,_tachetitre],(_NomMarquer call BIS_fnc_randomPosTrigger),0,2,true,"help"] call BIS_fnc_taskCreate;
//Affiche ou non la tache sur carte selon la paramètre _Visible
if (_Visible isEqualTo false) then {
  [true,[_tache],[_Description,_tachetitre],objNull,0,2,true,"help"] call BIS_fnc_taskCreate;
} else {
  [true,[_tache],[_Description,_tachetitre],(_NomMarquer call BIS_fnc_randomPosTrigger),0,2,true,"help"] call BIS_fnc_taskCreate;
};

//Ajout de l'addAction sur les l'otages
{
  _Icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_unbind_ca.paa";
  _Icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_unbind_ca.paa";
  [_x,"Libérer",_Icone,_Icone,"_this distance _target < 2","_this distance _target < 2",{},{},
    {[group _caller,_caller] remoteExec ["selectLeader", groupOwner group _caller];
    _target playMove "Acts_ExecutionVictim_Unbow";
    _target setCaptive false;
    [_target] join (group _caller);
    },
  {},[],6,0,true,false] remoteExec ["BIS_fnc_holdActionAdd",0,_x];

} forEach _Otages;
//Variables pour compteur les otages présent dansle tableau passé en paramètre (_Otages)
_NombreOtages = count _Otages;
_CompteurOtages = 0;
_CompteurOtagesMort = 0;

//Création d'un déclencheur de réussite
_Condition = format ["%1 == %2",_CompteurOtages,_NombreOtages];
_QuandActiver = "";

_DeclencheurSauver = createTrigger ["EmptyDetector", _coordSauve];
_DeclencheurSauver setTriggerArea [10, 10, 0, false];
_DeclencheurSauver setTriggerActivation ["ANYPLAYER", "PRESENT", true];
_DeclencheurSauver setTriggerStatements [_Condition,_QuandActiver, ""];


//Vérifie si tous les objets ont été sauvé
_TousSecouru = false;
    while {_TousSecouru isEqualTo false} do {
        _TotalOtages = 0;
        _OtagesSauve = 0;
        _CompteurOtagesMort = 0;
        {
          if (!alive _x) then {_CompteurOtagesMort = _CompteurOtagesMort + 1};
          if ([_DeclencheurSauver,_x] call bis_fnc_intrigger) then {_OtagesSauve = _OtagesSauve + 1};
          } forEach _Otages;
          _TotalOtages = _OtagesSauve + _CompteurOtagesMort;
          if (_TotalOtages == count _Otages) then {_TousSecouru = true};
          sleep 3;
    };

//----------------------------------------------------------------

if (_CompteurOtagesMort >= (round (count _Otages / 2))) then {
  [_tache,'FAILED',true] call BIS_fnc_taskSetState;
}else {
  [_tache,'SUCCEEDED',true] call BIS_fnc_taskSetState;
};

waitUntil{[_tache] call BIS_fnc_taskCompleted}; // Nettoage de la tache

deleteMarker _NomMarquer;
sleep 10;
//[_tache] call BIS_fnc_deleteTask;
tache_scenario = tache_scenario + 1;
