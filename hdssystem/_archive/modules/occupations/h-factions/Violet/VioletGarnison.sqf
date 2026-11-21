params ["_Centre","_Ratio","_Taille","_Visible"];

_PosCentre = _this select 0;
_Ratio = _this select 1;
_Taille = _this select 2;
_Visible = _this select 3;

//--------------------Création du marqueur de mission------------------------
//Coordonnée du marqueur
_PosCentre = getMarkerpos _PosCentre;

_rnum = str(round (random 999));
_NomMarqueur = format ["OccupationH_%1",_rnum];
_MarkerZone = createMarker [_NomMarqueur,_PosCentre];
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
_NbGarnison = ((count (_PosCentre nearObjects ["House",_Taille])) / 5) * _ratio;
_NbGarnison = round (_NbGarnison/2);
if (_NbGarnison > 30) then {_NbGarnison = 30};
if (_NbGarnison < 1) then {_NbGarnison = 1};
//----------------------Recherche des position de toutes les maisons dans le secteur -------------
_ListeBatiments = nearestObjects [_PosCentre,["House"],_Taille,false];
//----------------------Création d'infanterie dans les batiments dans le secteur-----------------------------------------------
{
  _ListePlaces = (_x call BIS_fnc_buildingPositions);

    for "_i" from 1 to (round (random 1)) + _Ratio do {
        _Groupes = creategroup civilian;
        _HommeCivil = _Groupes createUnit [SelectRandom HListeUniteCivils,SelectRandom _ListePlaces,[],5,"FORM"];
        {
          _x setPos SelectRandom _ListePlaces;
          [_x,"SIT_LOW_U","NONE"] call BIS_fnc_ambientAnim;
        } forEach units _Groupes;
        sleep 0.5;
        _Groupes enableDynamicSimulation true;
    };

} forEach _ListeBatiments;
//---------------------------------------------------------------------------------------------------------
