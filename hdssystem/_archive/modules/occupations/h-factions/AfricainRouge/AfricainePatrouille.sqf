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

//----------------------Création d'infanterie opfor------------------------
if(hdssysteme)then{["hds-système : Création des patrouilles en cours"] remoteexeccall ["systemChat",0]};

for "_i" from 1 to round (_Ratio + (round random _Ratio)) do {
  _Groupe = creategroup east;
  for "_y" from 1 to 5 do {
    _HommeAinkada = _Groupe createUnit [SelectRandom HListeUnitesAfricaines,_NomMarqueur call bis_fnc_randomPosTrigger,[],0,"NONE"];
  };

  {_x setpos getpos ((Units _Groupe) select 0);} foreach Units _Groupe;
  [_Groupe,(_this select 0),_Taille] call bis_fnc_taskpatrol;
  _GroupeAinkada enableDynamicSimulation true;
};

if(hdssysteme)then{["hds-système : Création des patrouilles terminée"] remoteexeccall ["systemChat",0]};
