params ["_paragraphe"];

{
  [(_x select 0),(_x select 1)] spawn bis_fnc_infotext;
  sleep 5;
} foreach (_this select 0);
