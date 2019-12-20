params ["_Centre","_Ratio","_Taille","_Visible"];


_Ratio = _this select 1;
_Taille = _this select 2;
_Visible = _this select 3;
//--------------------Création du marqueur de mission------------------------


_rnum = str(round (random 999));
_NomMarqueur = format ["pieton_%1",_rnum];
_MarkerZone = createMarker [_NomMarqueur,(_this select 0)];
_MarkerZone setMarkerShape "Ellipse";
_MarkerZone setMarkerSize [(_Taille + 100),(_Taille + 100)];
_MarkerZone setMarkerColor "colorCIV";
_MarkerZone setMarkerBrush "Border";
//----------------------------------------------------------------------------------

//Rend visible ou invisible selon le paramètre _Visible le Marqueur afficher sur la carte
if (_Visible isEqualto true) then {_MarkerZone setMarkerAlpha 0.15} else {_MarkerZone setMarkerAlpha 0.0};
//----------------------Stabilisation du ratio de personnels et autres variables---------------
//Cela évite qu'un fort ratio ne face apparaitre des groupes de trop grande taille
_NbPersonnels = round (_Taille / 130);
if (_NbPersonnels > 2) then {_NbPersonnels = 2};
if (_NbPersonnels < 1) then {_NbPersonnels = 1};
//----------------------Création d'infanterie------------------------
for "_i" from 1 to round _Ratio * (round (_Taille/50)) + 3 do {
  _Groupes = creategroup civilian;
  _HommeCivil = _Groupes createUnit [SelectRandom HlisteUniteCivils,_NomMarqueur call bis_fnc_randomPosTrigger,[],5,"Form"];
  [_Groupes,(_this select 0),_Taille] call bis_fnc_taskpatrol;
  _Groupes enableDynamicSimulation true;
};
