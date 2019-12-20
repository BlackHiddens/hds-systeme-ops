params ["_Position","_PositionLiveraison","_Cible","_NomCible","_Description","_Taille","_Visibiliter"];

_Position = _this select 0;           //position de la mission complète
_PositionLiveraison = _this select 1; //Position de l'homme à appréhender
_Cible = _this select 2;              //Nom de la variable de l'otage posé sur carte
_NomCible = _this select 3;           //Nom donné à la cible
_Description = _this select 4;        //Description de la mission
_Taille = _this select 5;             //Taille du rayon de la zone de mission

_rnum = str(round (random 999));
_coord = _Position;
_coordLivrer = _PositionLiveraison;

_NomMarqueurCible = format ["MLivrerPerso%1",_rnum];
_MarqueurCible = createMarker [_NomMarqueurCible,_coordLivrer];
_MarqueurCible setMarkerShape "Ellipse";
_MarqueurCible setMarkerSize [30,30];
_MarqueurCible setMarkerColor "colorWEST";
_MarqueurCible setMarkerBrush "Horizontal";

_NomMarquer = format ["LivrerPerso%1",_rnum];
_MarkerZone = createMarker [_NomMarquer,_coord];
_MarkerZone setMarkerShape "Ellipse";
_MarkerZone setMarkerSize [_Taille,_Taille];
_MarkerZone setMarkerColor "colorOPFOR";
_MarkerZone setMarkerBrush "SolidBorder";

if (_Visibiliter isequalto false) then {_MarkerZone setMarkerAlpha 0}else{_MarkerZone setMarkerAlpha 0.3};



//configuration de la Cible
/*
_groupe = createGroup east;
[_Cible] join _groupe;
 for "_i" from 1 to 4 do {
  _GardeDuCorp = _groupe createUnit ["I_Soldier_lite_F",(getpos _Cible), [],(_Taille), "FORM"]; //Gardes
};
*/

//creation de la tache
_tache = "TacheLivrerPerso" + _rnum + str(_Position);
_tachetitre = format ["Apprehender|%1", _NomCible];
[true,[_tache],[_Description,_tachetitre],(_NomMarquer call BIS_fnc_randomPosTrigger),0,2,true,"interact"] call BIS_fnc_taskCreate;


_Apprehender = 0;
while {alive _Cible && _Apprehender == 0} do {
    if(count units group _Cible < 3) then {
      _Cible setCaptive true;
      [[_Cible,"Acts_CivilInjuredLegs_1"],"SwitchMove"] call bis_fnc_mp;
      //_Cible switchMove "Acts_CivilInjuredLegs_1";
      //Ajout de l'addAction à la cible
      _Icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_unbind_ca.paa";
      [_Cible,"Apprehender",_Icone,_Icone,"_this distance _target < 2","_this distance _target < 2",
        {},
        {},
        {[group _caller,_caller] remoteExec ["selectLeader", groupOwner group _caller];
        _target SwitchMove "";
        [_target] join (group _caller);
        removeAllPrimaryWeaponItems _target;
        },
      {},[],6,0,true,true] remoteExec ["BIS_fnc_holdActionAdd",0,_Cible];
      _Apprehender = 1;
    };
    sleep 2;
};

waitUntil {[_NomMarqueurCible,_Cible] call bis_fnc_intrigger || !alive _Cible || [_tache] call BIS_fnc_taskCompleted};

if (!alive _Cible) then {
  [_tache,'FAILED',true] call BIS_fnc_taskSetState;
};

if ([_NomMarqueurCible,_Cible] call bis_fnc_intrigger) then {
  [_tache,'SUCCEEDED',true] call BIS_fnc_taskSetState;
};

waitUntil{[_tache] call BIS_fnc_taskCompleted}; // Nettoage de la tache

deleteMarker _NomMarquer;
sleep 5;
//[_tache] call BIS_fnc_deleteTask;

tache_scenario = tache_scenario + 1;
