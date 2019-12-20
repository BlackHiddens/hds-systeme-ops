params ["_Objet"];

   openMap true;
   ModeAppelRenfort = true;
   publicVariable "ModeAppelRenfort";
   hint "Où avez-vous besoin d'un appui Monsieur";
   onMapSingleClick {
    if (ModeAppelRenfort isEqualTo true and NbRenfortDispo > 0) then {
      _WestAllie = [([_pos,450,650,1,0,60,0] call BIS_fnc_findSafePos),CampsRenfortAllie,8] call BIS_fnc_spawnGroup;
      {[_x] spawn fnc_americain_polyvalent} foreach units _WestAllie; //Type de personnel généré
      _WestAllie addWaypoint [_pos,0];openMap false;
      _MessageWest = format ["Reçu nous arrivons dès que possible à la positon %1. Nous arriverons par l'azimute %2 ",_pos,leader player getDir leader _WestAllie];
      [West,"Base"] sideChat _MessageWest;
      systemChat "Les troupes sont actuellement en mouvement";
      NbRenfortDispo = (NbRenfortDispo - 1);
      publicVariable "NbRenfortDispo";
      hint format ["Il vous reste %1 renfort(s)",NbRenfortDispo];
      };
    if (NbRenfortDispo == 0 and ModeAppelRenfort isEqualTo true) then {[West,"Base"] sideChat "Nous n'avons plus de garnison Monsieur !";};
    ModeAppelRenfort = false;
    publicVariable "ModeAppelRenfort";
  }

/*
  fnc_roscontractors_desert  //contrators desert
  fnc_nationuni_assaut       //nation uni assaut
  fnc_afgan_classique        //Soldat afgan
*/
