params ["_typeEquipe","_camouflage","_legroupe"];

switch (_this select 0) do {
  //-----------------------------------------------
  //Génération d'une équipe d'assaut de 4 personnes
  //-----------------------------------------------
    case 0: {
      //Equipe d'assaut en camo desert --------------------
      if ((_this select 1) isequalto 0) then {
        hint format ["%1,|%2",Units (_this select 2),_TypeEquipe];
        //Equiper les fantassins
        [(Units (_this select 2)) select 0] spawn fnc_rosfantassinassaut_desert;
        [(Units (_this select 2)) select 1] spawn fnc_rosfantassinassaut_desert;
        //Equiper les grenadiers
        [(Units (_this select 2)) select 2] spawn fnc_rosgrenadierassaut_desert;
        [(Units (_this select 2)) select 3] spawn fnc_rosgrenadierassaut_desert;
      };
      //Equipe d'assaut en camo tiger ---------------------
      if ((_this select 1) isequalto 1) then {
        //Equiper les fantassins
        [((Units (_this select 2)) select 0)] spawn fnc_rosfantassinassaut_tiger;
        [((Units (_this select 2)) select 1)] spawn fnc_rosfantassinassaut_tiger;
        //Equiper les grenadiers
        [((Units (_this select 2)) select 2)] spawn fnc_rosgrenadierassaut_tiger;
        [((Units (_this select 2)) select 3)] spawn fnc_rosgrenadierassaut_tiger;
      };
      //Equipe d'assaut en camo urbain -----------------------
      if ((_this select 1) isequalto 2) then {
        //Equiper les fantassins
        [((Units (_this select 2)) select 0)] spawn fnc_rosfantassinassaut_tiger;
        [((Units (_this select 2)) select 1)] spawn fnc_rosfantassinassaut_tiger;
        //Equiper les grenadiers
        [((Units (_this select 2)) select 2)] spawn fnc_rosgrenadierassaut_tiger;
        [((Units (_this select 2)) select 3)] spawn fnc_rosgrenadierassaut_tiger;
      };
    };
  //---------------------------------------------------------------------------------------
  //Génération d'une équipe de soutien
  //--------------------------------------------------------------------------------------------
  case 1: {
    //Equipe de soutien en camo desert --------------------
    if ((_this select 1) isequalto 0) then {
      //Equiper les fantassins
      [((Units (_this select 2)) select 0)] spawn fnc_rosfantassinsoutien_desert;
      //Equiper les mitrailleur
      [((Units (_this select 2)) select 1)] spawn fnc_rosmitrailleursoutien_desert;
      //Equiper les tireur de précision
      [((Units (_this select 2)) select 2)] spawn fnc_rostpdesertsoutien_desert;
      //Equiper les anti-char
      [((Units (_this select 2)) select 3)] spawn fnc_rosacdesertsoutien_desert;
    };
    //Equipe de soutien en camo tigre
    if((_this select 1) isequalto 1) then {
      //Equiper les fantassins
      [((Units (_this select 2)) select 0)] spawn fnc_rosfantassinsoutien_tiger;
      //Equiper les mitrailleur
      [((Units (_this select 2)) select 1)] spawn fnc_rosmitrailleursoutien_tiger;
      //Equiper les tireur de précision
      [((Units (_this select 2)) select 2)] spawn fnc_rostpdesertsoutien_tiger;
      //Equiper les anti-char
      [((Units (_this select 2)) select 3)] spawn fnc_rosacdesertsoutien_tiger;
    };
    //Equipe de soutien en camo urbain
    if((_this select 1) isequalto 2) then {
      //Equiper les fantassins
      [((Units (_this select 2)) select 0)] spawn fnc_rosfantassinsoutien_urbain;
      //Equiper les mitrailleur
      [((Units (_this select 2)) select 1)] spawn fnc_rosmitrailleursoutien_urbain;
      //Equiper les tireur de précision
      [((Units (_this select 2)) select 2)] spawn fnc_rostpdesertsoutien_urbain;
      //Equiper les anti-char
      [((Units (_this select 2)) select 3)] spawn fnc_rosacdesertsoutien_urbain;
    };
  };
  case 2:{
    if ((_this select 1) isequalto 0) then {
      //Equiper les fantassins
      [((Units (_this select 2)) select 0)] spawn fnc_roscontractors_desert;
      //Equiper les mitrailleur
      [((Units (_this select 2)) select 1)] spawn fnc_roscontractors_desert;
      //Equiper les tireur de précision
      [((Units (_this select 2)) select 2)] spawn fnc_roscontractors_desert;
      //Equiper les anti-char
      [((Units (_this select 2)) select 3)] spawn fnc_roscontractors_desert;
    };
  };
  case 3:{
    if ((_this select 1) isequalto 0) then {
      //Equiper les fantassins
      [((Units (_this select 2)) select 0)] spawn fnc_roscontractors_desert;
      //Equiper les mitrailleur
      [((Units (_this select 2)) select 1)] spawn fnc_roscontractors_desert;
      //Equiper les tireur de précision
      [((Units (_this select 2)) select 2)] spawn fnc_roscontractors_desert;
      //Equiper les anti-char
      [((Units (_this select 2)) select 3)] spawn fnc_roscontractors_desert;
    };
  };
};
