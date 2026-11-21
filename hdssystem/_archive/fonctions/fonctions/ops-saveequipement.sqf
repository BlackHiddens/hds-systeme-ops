params ["_NbSeconde"];

while {hasInterface} do {
  sleep (_this select 0);
  [player,[ProfileNameSpace,"hdssystem|456987"]] call BIS_fnc_saveInventory;
  if(hdssysteme)then{["Equipement sauvegardé"] remoteexeccall ["systemChat",player]};
};
