params ["_rayon","_objet","_tableauTypeClassObjets"];

_liste_tout_les_objets_trouve = nearestObjects [
            (_this select 1),
            (_this select 2),
            (_this select 0)
];

_liste_objets_occupables = [];


//Selectionne uniquement les batiments occupable
{
    if(count ([_x] call BIS_fnc_buildingPositions) > 0)then{
      _liste_objets_occupables append [_x];
    }
} forEach _liste_tout_les_objets_trouve;
//hint format ["%1",_liste_objets_occupables];

//Retour un tableau de 2 tableaux [<tableau>,<tableau>]
[_liste_objets_occupables,_liste_tout_les_objets_trouve]
