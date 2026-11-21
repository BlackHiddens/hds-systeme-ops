params ["_pos_mission","_NomCible","_Taille","_Faction"];

      _rnum = str(round (random 999));

      _marqueurzonedecombat = [(_this select 0),(_this select 2),"colorOPFOR"] call fnc_objectif_creermarqueur;
      _marqueurzonedecombat setMarkerAlpha var_mission_transparance_marqueur;
      if(hdssysteme)then{_marqueurzonedecombat setMarkerAlpha 1};

      if((_this select 2) < 100)then{_marqueurzonedecombat setMarkerAlpha 0}else{_marqueurzonedecombat setMarkerAlpha 0.3};
      _Vehicule = [([getmarkerpos (_this select 0),(_this select 2),(_this select 2),1,0,30,0] call BIS_fnc_findSafePos),0,(selectrandom ["LOB_IRA_Igla_AA_pob","RHS_ZU23_MSV","rhs_D30_msv"]),east] call bis_fnc_spawnvehicle;
      //creation de la tache
      _tache = "Tache_Detruire" + _rnum + str((_this select 0));
      _tachemarquer = format ["%1"];
      _tachetitre = (_this select 1);
      _tacheDesc = format ["%1 est un élément de logistique prioritaire. détruisez-le",_NomCible];
      missionNamespace setVariable [_tache,_tache];
      publicVariable _tache;

      [true,[_tache],[_tacheDesc,_tachetitre],(_marqueurzonedecombat call BIS_fnc_randomPosTrigger),0,2,true,"destroy"] call BIS_fnc_taskCreate;
      [(_this select 0),0,(_this select 3),30,true] spawn fnc_hds_occupations;
      waitUntil {!alive (_Vehicule select 0) || [_tache] call BIS_fnc_taskCompleted };
      [_tache,'SUCCEEDED',true] call BIS_fnc_taskSetState;

      waitUntil{[_tache] call BIS_fnc_taskCompleted}; // Nettoage de la tache

      deleteMarker _marqueurzonedecombat;                                               //Supprime le marquer sur carte
      deleteMarker _NomZoneAttaque;

      tache_effectuee = tache_effectuee + 1;publicVariable "tache_effectuee";
      true
