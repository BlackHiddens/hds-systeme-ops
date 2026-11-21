params ["_Centre","_Ratio","_Taille","_Visible"];


_Ratio = _this select 1;
_Taille = _this select 2;
_Visible = _this select 3;
//--------------------Création du marqueur de mission------------------------


_rnum = str(round (random 999));
_NomMarqueur = format ["OccupationH_%1",_rnum];
_MarkerZone = createMarker [_NomMarqueur,(_this select 0)];
_MarkerZone setMarkerShape "Ellipse";
_MarkerZone setMarkerSize [(_Taille + 100),(_Taille + 100)];
_MarkerZone setMarkerColor "colorOPFOR";
_MarkerZone setMarkerBrush "Border";
//----------------------------------------------------------------------------------

//Rend visible ou invisible selon le paramètre _Visible le Marqueur afficher sur la carte
if (_Visible isEqualto true) then {_MarkerZone setMarkerAlpha 0.15} else {_MarkerZone setMarkerAlpha 0.0};
//----------------------Stabilisation du ratio de personnels et autres variables---------------
//Cela évite qu'un fort ratio ne face apparaitre des groupes de trop grande taille
_NbPersonnels = round (_Taille / 130);
if (_NbPersonnels > 5) then {_NbPersonnels = 5};
if (_NbPersonnels < 3) then {_NbPersonnels = 3};
//----------------------Création d'infanterie opfor------------------------
if(hdssysteme)then{["hds-système : Création des patrouilles en cours"] remoteexeccall ["systemChat",0]};
for "_i" from 1 to round (_Ratio + (round random _Ratio)) do {
  _SpawnPosition = _NomMarqueur call bis_fnc_randomPosTrigger;
  if(surfaceIsWater _SpawnPosition) then {
    _Groupes= [_NomMarqueur call bis_fnc_randomPosTrigger,west,(configfile >>  "CfgGroups" >> "west" >> "BLU_F" >> "SpecOps" >> "BUS_DiverTeam_Boat")] call BIS_fnc_spawnGroup;
    [_Groupes,(_this select 0),_Taille] call bis_fnc_taskpatrol;
    _Groupes enableDynamicSimulation true;
  }else{
    _Groupes = [_NomMarqueur call bis_fnc_randomPosTrigger,west,_NbPersonnels] call BIS_fnc_spawnGroup;
    [_Groupes,(_this select 0),_Taille] call bis_fnc_taskpatrol;
    _Groupes enableDynamicSimulation true;
  };
  sleep 0.5;
};
if(hdssysteme)then{["hds-système : Création des patrouilles terminée"] remoteexeccall ["systemChat",0]};
