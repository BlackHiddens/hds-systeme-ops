params ["_objetpositions"];

{
  [
  (_x select 0),
  "commander un véhicule",
  "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_hack_ca.paa",
  "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_hack_ca.paa",
  "_this distance _target < 2",
  "_this distance _target < 2",
  {},
  {},
  {
    BIS_fnc_garage_center = createVehicle["Land_HelipadEmpty_F",(_arguments select 0),[],0,"CAN_COLLIDE"];
    ["Open", true ] call BIS_fnc_garage;
  },
  {},
  [(_x select 1)],
  0.5,
  1,
  false,
  false
  ] call BIS_fnc_holdActionAdd;
} foreach (_this select 0);


/* BIS_fnc_garage_data = [
	[
		'\a3\soft_f\mrap_01\mrap_01_unarmed_f',
		[ ( configFile >> 'cfgVehicles' >> 'B_MRAP_01_F' ) ]
	]
]; */
