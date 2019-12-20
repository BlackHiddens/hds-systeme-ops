/*
Cette fonction permet de scripter un objet
Afin de le transformer en arsenal virtuel

Les paramètres attendu sont : L'objet & Le message qui s'affiche
*/
params ["_Lesarsenales"];
//ajouter un arsenal virtuel standard
{
  //["AmmoboxInit",[_x,true,{(_this distance _target) < 5}]] call BIS_fnc_arsenal;
  //[_x,"ouvrir l'arsenal payant","Hacker",0.5,5,false,"[] spawn fnc_hds_boutique;",0] spawn fnc_hds_ajoutaction;
  if(aceestactive)then{
    if(boutiqueactive)then{
    [_x,hds_txt_fonctions_arsenal_libinteraction,"Hacker",0.5,5,false,format ["[%1] spawn fnc_hds_boutique;",_x],0] spawn fnc_hds_ajoutaction;
    //[_x,true] call ace_arsenal_fnc_initBox;
    }else{
      if(modehardactive)then{
        [_x] call fnc_hds_arsenal_gios;
        //[_x] call fnc_hds_arsenal_prive;
      }else{
        [_x,true]call ace_arsenal_fnc_initBox;
        ["AmmoboxInit",[_x,true,{(_this distance _target) < 5}]] call BIS_fnc_arsenal;
      };
    };
  }else{
    ["AmmoboxInit",[_x,true,{(_this distance _target) < 5}]] call BIS_fnc_arsenal;
  };
} foreach (_this select 0);

//si ace activé alors ajouter aussi le virtuel arsenal
