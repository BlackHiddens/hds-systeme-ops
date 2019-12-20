params ["_Centre","_Ratio","_Taille","_Visible"];


_Ratio = _this select 1;
_Taille = _this select 2;
_Visible = _this select 3;

//--------------------Création du marqueur de mission------------------------


_rnum = str(round (random 999));
_NomMarqueur = format ["OccupationH_%1",_rnum];
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

//Liste de véhicules opfor
_ListeVehicule = ["I_MRAP_03_F","I_MRAP_03_gmg_F","I_MRAP_03_hmg_F","I_APC_tracked_03_cannon_F",
"I_UGV_01_rcws_F","I_APC_Wheeled_03_cannon_F","I_LT_01_AT_F","I_LT_01_scout_F","I_LT_01_cannon_F","I_MBT_03_cannon_F"];
//------------------------------------------------------------------------------------------------
for "_i" from 1 to _Ratio + (round (_Taille/400)) do {
  _ListeRoutes = ((_this select 0) nearRoads _Taille);
  if(count _ListeRoutes isequalto 0)exitwith{};
  _ListeRoutes = getpos (selectRandom _ListeRoutes);

  _VehiculeCree = [_ListeRoutes,180,(SelectRandom _ListeVehicule),INDEPENDENT] call bis_fnc_spawnvehicle;
  createVehicleCrew (_VehiculeCree select 0);

  [_VehiculeCree select 2,_NomMarqueur call bis_fnc_randomPosTrigger,_Taille] call bis_fnc_taskpatrol;
  sleep 0.5;
};
