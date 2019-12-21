params ["_position","_taille"];

while {true} do {
  {
      if (
        (getdammage _x > 0) and
        (!(getAmmoCargo _x isequalto 1) or !(getAmmoCargo _x isequalto -1)) and
        (!(getFuelCargo _x isequalto 1) or !(getFuelCargo _x isequalto -1))
        ) then {

       if (getFuelCargo _x < 1) then{
         if(isengineon _x)then(_x engineon false);
         systemChat format ['Ravitaillement de %1', _x];
         sleep 10;
         _x setFuel 1;
       };

       if (getAmmoCargo _x < 1) then {
         if(isengineon _x)then(_x engineon false);
         systemChat format ['Réarmement de %1', _x];
         sleep 10;
         _x setVehicleAmmo 1;
       };

       if (getDammage _x > 0) then {
         if(isengineon _x)then(_x engineon false);
         systemChat format ['Réparation de %1', _x];
         sleep 10;
         _x setDamage 0;
       };
       systemChat format ['dernières vérifications de %1', _x];
       sleep 10;
       if(isengineon _x)then(_x engineon false);
       systemChat format ['%1 prêt pour utilisation', _x];

      };

  } forEach nearestObjects [(_this select 0),['LandVehicle','Air'],(_this select 1)];
  sleep 10;
};
