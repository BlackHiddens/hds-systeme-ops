params ["_Objet"];

  if(boutiqueactive)then{
  [(_this select 0),hds_txt_fonctions_arsenal_libinteraction,"Hacker",0.5,5,false,format ["[%1] spawn fnc_hds_boutique;",_x],0] spawn fnc_hds_ajoutaction;
  //[_x,true] call ace_arsenal_fnc_initBox;
  }else{
      if(aceestactive)then{[(_this select 0),true]call ace_arsenal_fnc_initBox};
      ["AmmoboxInit",[(_this select 0),true,{(_this distance _target) < 5}]] call BIS_fnc_arsenal;
  };
