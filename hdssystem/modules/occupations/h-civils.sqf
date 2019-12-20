params ["_Centre","_Ratio","_Taille","_Nationalite","_Visible"];

switch (_this select 3) do {
    //Civils américain
    case 0: {

    [(_this select 0),_this select 1,_this select 2,_this select 3] spawn fnc_Americaingarnison;
    //[(_this select 0),_this select 1,_this select 2,_this select 4] spawn fnc_Americainvehicules;
    [(_this select 0),_this select 1,_this select 2,_this select 4] spawn fnc_Americainpietons;
    };
    if (opforactive) then {
    case 1: {
    [(_this select 0),_this select 1,_this select 2,_this select 3] spawn fnc_Arabesgarnison;
  //[(_this select 0),_this select 1,_this select 2,_this select 4] spawn fnc_Arabesvehicules;
    [(_this select 0),_this select 1,_this select 2,_this select 4] spawn fnc_Arabespietons;
    };
    };

};
