/*
  fnc_mission_creermarqueur
  <position> : Position centrale du _marqueur
  <entier> : taille du secteur
  <texte> : forme du marqueur Rond - "Ellipse", Carré - "Rectangular"
  <texte> : Couleur du marqueur (colorOPFOR,colorBLUFOR,colorCIVILIAN,colorIndependent)
  <texte> : Style du maruqueur (SolidBorder,Border) voir sur bohemia interactif wiki
*/

params ["_centre","_taille","_couleur"];

_secteur = [
(format ["hds_marqueur_%1",round random 900]),
(_this select 0),
var_mission_forme_marqueur,
[(_this select 1),(_this select 1)],
"BRUSH:",var_mission_style_marqueur,
"COLOR:",(_this select 2)
] call cba_fnc_createmarker;

_secteur
