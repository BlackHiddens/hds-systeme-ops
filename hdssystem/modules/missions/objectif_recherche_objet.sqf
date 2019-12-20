/*
  Recherche tous les types d'objet passé en parametre et retour un tableau de ces derniers.
  0 : <tableau> d'une coordonnée
  1 : <tableau> de type d'objets
*/

params ["_position","_rayon","_tableauTypeClassObjets"];
_liste_position_objets_selectionne = [];
_liste_objets_selectionne = nearestObjects [
            (_this select 0),
            (_this select 2),
            (_this select 1)
];

{
    _liste_position_objets_selectionne append [getpos _x];
} forEach _liste_objets_selectionne;

_liste_position_objets_selectionne
