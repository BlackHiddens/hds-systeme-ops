params ["_Centre","_Ratio","_Taille","_Visible"];

_Ratio = _this select 1;
_Taille = _this select 2;
_Visible = _this select 3;

//--------------------Création du marqueur de mission------------------------

_MarkerZone = createMarker [(format ["Occup_%1",str(round (random 9999))]),(_this select 0)];
_MarkerZone setMarkerShape "Ellipse";
_MarkerZone setMarkerSize [_Taille,_Taille];
_MarkerZone setMarkerColor "colorCIV";
_MarkerZone setMarkerBrush "Border";
//----------------------------------------------------------------------------------

//Rend visible ou invisible selon le paramètre _Visible le Marqueur afficher sur la carte
if (_Visible isEqualto true) then {_MarkerZone setMarkerAlpha 0.15} else {_MarkerZone setMarkerAlpha 0.0};

//----------------------Stabilisation du ratio de personnels et autres variables---------------
//Cela évite qu'un fort ratio ne face apparaitre des groupes de trop grande taille
_NbPersonnels = 1;  //Nombre de personnel par groupe
_NbGarnison = ((count ((_this select 0) nearObjects ["House",_Taille])) / 5) * _ratio;
_NbGarnison = round (_NbGarnison/2);
if (_NbGarnison > 30) then {_NbGarnison = 30};
if (_NbGarnison < 1) then {_NbGarnison = 1};
//----------------------Recherche des position de toutes les maisons dans le secteur -------------
_ListeBatiments = nearestObjects [(_this select 0),["House"],_Taille,false];
//----------------------Création d'infanterie dans les batiments dans le secteur-----------------------------------------------
for "_i" from 1 to ((count _ListeBatiments)/10) do {
  _Groupes = creategroup civilian;
  _Homme = _Groupes createUnit [SelectRandom HlisteUniteCivilsArabes,(_this select 0),[],0,"NONE"];
  [_Centre,(units _Groupes),_Taille+100,true] spawn fnc_ace_garnir;
  {[_x,"SIT_LOW_U","NONE"] call BIS_fnc_ambientAnim} foreach units _groupes;
  _Groupes enableDynamicSimulation true;
}

//---------------------------------------------------------------------------------------------------------
