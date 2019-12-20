params ["_centre","_nomclassgroupe","_distanceApproche","_camps","_vehiculeTT","_nombredegroupe"];

//véhicule
_custom_distance_approche = (_this select 2);
if((_this select 4) iskindof "Air")then{
  _custom_distance_approche = _custom_distance_approche*3;
}else{
  _custom_distance_approche = _custom_distance_approche*1.5;
};
_PositionDeDepart = ([(_this select 0),_custom_distance_approche,(_custom_distance_approche*1.5),5,0,20] call BIS_fnc_findSafePos);
_Listederoute = _PositionDeDepart nearroads 200;
_tentative = 0;

while  {(isnil "_Listederoute") and (_tentative < 6)} do {
  _PositionDeDepart = ([(_this select 0),(_this select 2),((_this select 2)*2),5,0,20] call BIS_fnc_findSafePos);
  _Listederoute = _PositionDeDepart nearroads 200;
  _tentative = _tentative + 1;
};

if(_tentative isequalto 6)then{
  _PositionDeDepart = selectrandom getpos _Listederoute;
};

_vehicule = [
  _PositionDeDepart,
  0,
  (_this select 4),
  (_this select 3)
  ] call bis_fnc_spawnvehicle;

//le groupe de combat
_liste_groupes = [];

for '_i' from 1 to (_this select 5) do {
  _groupedecombat = [
  ([(_this select 0),_custom_distance_approche,(_custom_distance_approche*1.5),1,0,60] call BIS_fnc_findSafePos),
  (_this select 3),
  (_this select 1)
  ] call bis_fnc_spawngroup;
  _liste_groupes append [_groupedecombat];
  //monter dans le vehicule
  {_x moveInCargo (_vehicule select 0)} foreach Units _groupedecombat;
  //suprimer le personnels non embarqué
  {
    if!(_x in (_vehicule select 0))then{
      deleteVehicle _x
    };
  } foreach Units _groupedecombat;
};

[(_this select 0),_vehicule,_liste_groupes] spawn fnc_tactique_missionrenforcer;
