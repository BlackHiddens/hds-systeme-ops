params ["_rayon","_faction","_probabiliter","_difficulter","_typelocalisation"];

if((_this select 2)isequalto true)then{
{
  [(locationposition _x),(_this select 3),(_this select 1),(_this select 0),false] spawn fnc_hds_occupations;
  [(locationposition _x),(_this select 0),(_this select 1),1,1] spawn fnc_tactique_plannification;
} foreach (nearestLocations [[0,0,0],(_this select 4),50000]);
}else{
  {
    if(selectrandom [0,1,2,3] isequalto 1)then{
      [(locationposition _x),(_this select 3),(_this select 1),(_this select 0),false] spawn fnc_hds_occupations;
      [(locationposition _x),(_this select 0),(_this select 1),1,1] spawn fnc_tactique_plannification;
    };
  } foreach (nearestLocations [[0,0,0],(_this select 4),50000]);
};
