params ["_orgine","_ratio","_rayon","_localisation"];

_Localiter = nearestLocations [[0,0,0],(_this select 3),40000];
{[(locationposition _x),8,(_this select 2),(_this select 0),false] spawn fnc_hds_populations} foreach _Localiter;
