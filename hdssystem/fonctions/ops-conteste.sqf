params ["_campsennemi","_difficulte","_rayon"];
_Localiter = nearestLocations [[0,0,0],["NameVillage","NameCity","NameLocal","Name"],40000];

{

  if((selectrandom[1,2,3]) isequalto 2)then{
    [([5000,5000,0] call bis_fnc_randomPosTrigger),0,(_this select 0),5000,false] call fnc_occupations_init;
    [(locationposition _x),((_this select 2)*2),(_this select 0),2,5] spawn fnc_tactique_plannification;
  }
} foreach _Localiter;

[([5000,5000,0] call bis_fnc_randomPosTrigger),1,(_this select 0),5000,false] call fnc_occupations_init;
