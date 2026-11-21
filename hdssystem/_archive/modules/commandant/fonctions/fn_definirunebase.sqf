/*
description ; selectionne le meilleur emplacement que possible sur un carte inconnu
retourne : <position> position de la base sélectionnée
*/

params [];

_listebasesideale = nearestlocations [[(worldSize/2),(worldSize/2),0],["NameLocal"],worldSize];
_listebasepotentielle = nearestlocations [[(worldSize/2),(worldSize/2),0],["NameVillage","NameCity"],worldSize];
_baseselectionner = objnull;
_listebaseideale_filtre = [];

if(count _listebasesideale > 0)then{
  {
    if((count (nearestobjects [(position _x),["house"],250]) > 1) and (surfaceIsWater [300,300]) isequalto false) then {
      _listebaseideale_filtre append [(position _x)];
    };
  } foreach _listebasesideale;
  if(count _listebaseideale_filtre > 0)then{
  _baseselectionner = selectRandom _listebaseideale_filtre;
  }else{
  _baseselectionner = position (selectrandom _listebasesideale);
  };
}else{
  _baseselectionner = position (selectrandom _listebasepotentielle);
};

_baseselectionner
