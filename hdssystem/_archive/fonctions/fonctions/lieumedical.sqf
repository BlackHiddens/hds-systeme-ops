params ["_sujet"];

while {true} do {
if(aceestactive and lelieuestunvehicule) then {

      if (player inArea [getPos (_this select 0),6,6,0,false]) then {
        [objNull,player] call ace_medical_treatment_fnc_fullHeal;
        [hds_txt_fonctions_medical_santeStable] remoteExeccall ["hint",player];
      };
    };

if (aceestactive and lelieuestunvehicule isequalto false) then {
    if (player inArea [getPos (_this select 0),6,6,0,false]) then {
      [objNull,player] call ace_medical_treatment_fnc_fullHeal;
      [hds_txt_fonctions_medical_santeStable] remoteExeccall ["hint",player];
    };
};

if(aceestactive isequalto false and lelieuestunvehicule) then {
      if (player in (_this select 0) and getdammage player > 0) then {
        player setdammage 0;
        [hds_txt_fonctions_medical_santeStable] remoteExeccall ["hint",player];
      };
  };
if(aceestactive isEqualTo false and lelieuestunvehicule isequalto false) then {
        if (player inArea [getPos (_this select 0),6,6,6,false] and getdammage player > 0) then {
          player setdammage 0;
          [hds_txt_fonctions_medical_santeStable] remoteExeccall ["hint",player];
        };
};
sleep 5;
};
