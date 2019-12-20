params ["_Centre","_Ratio","_Taille","_Visible"];


_Ratio = _this select 1;
_Taille = _this select 2;
_Visible = _this select 3;

//--------------------Création du marqueur de mission------------------------


_rnum = str(round (random 9999));
_NomMarqueur = format ["voiture_%1",_rnum];
_MarkerZone = createMarker [_NomMarqueur,(_this select 0)];
_MarkerZone setMarkerShape "Ellipse";
_MarkerZone setMarkerSize [(_Taille + 150),(_Taille + 150)];
_MarkerZone setMarkerColor "colorUNKNOWN";
_MarkerZone setMarkerBrush "Border";
//----------------------------------------------------------------------------------

//Rend visible ou invisible selon le paramètre _Visible le Marqueur afficher sur la carte
if (_Visible isEqualto true) then {_MarkerZone setMarkerAlpha 1} else {_MarkerZone setMarkerAlpha 0.0};

//----------------------Stabilisation du ratio de personnels et autres variables---------------
//Cela évite qu'un fort ratio ne face apparaitre des groupes de trop grande taille
if (_Ratio > 4) then {_Ratio = 4};

//------------------------------------------------------------------------------------------------
for "_i" from 1 to round (_Ratio + (_Taille/350)) do {
  _ListeRoutes = ((_this select 0) nearRoads _Taille + 500);
  if(count _ListeRoutes isequalto 0)exitwith{};
  _ListeRoutes = getpos (selectRandom _ListeRoutes);

  _VehiculeCree = [_ListeRoutes,180,(SelectRandom HlisteVehiculeCivils),civilian] call bis_fnc_spawnvehicle;
  createVehicleCrew (_VehiculeCree select 0);

  (_VehiculeCree select 2 )setSpeedMode "limited";
  (_VehiculeCree select 2) setCombatMode "green";
  _Route1 = (_VehiculeCree select 2) addWaypoint [getpos (_VehiculeCree select 0),0];
  _Route1 setWaypointType "Move";
  _Route4 = (_VehiculeCree select 2) addWaypoint [getpos (selectRandom _ListeRoutes),0];
  _Route4 setWaypointType "Cycle";

  (_VehiculeCree select 2) enableDynamicSimulation true;
  //(_VehiculeCree select 0) enableDynamicSimulation true;

  sleep 0.5;
};
