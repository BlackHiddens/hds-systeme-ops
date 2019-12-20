
factionactive = [0,1,3];
if(opforactive)then{factionactive append [4,6]};
if(afrfactive)then{factionactive append [5]};

intervalmax = 500;
hdstactiqueversion = "ai-hds-tactiques.bêta";

fnc_tactique_helicocombat = compile preprocessFile "hdssystem\modules\tactiques\les_mises_en_places\fnc_tactique_helicocombat.sqf";
fnc_tactique_groupedecombat = compile preprocessFile "hdssystem\modules\tactiques\les_mises_en_places\fnc_tactique_groupedecombat.sqf";
fnc_tactique_renfortvehiculer = compile preprocessFile "hdssystem\modules\tactiques\les_mises_en_places\fnc_tactique_renfortvehiculer.sqf";

fnc_tactique_missionsassaut = compile preprocessFile "hdssystem\modules\tactiques\les_missions\fnc_tactique_missionsassaut.sqf";
fnc_tactique_missionassautvehicule = compile preprocessFile "hdssystem\modules\tactiques\les_missions\fnc_tactique_missionassautvehicule.sqf";
fnc_tactique_missionrenforcer = compile preprocessFile "hdssystem\modules\tactiques\les_missions\fnc_tactique_missionrenforcer.sqf";

fnc_tactique_renfortterrestre = compile preprocessFile "hdssystem\modules\tactiques\les_tactiques\renfort-terrestre.sqf";
fnc_tactique_contreattaque = compile preprocessFile "hdssystem\modules\tactiques\les_tactiques\contre-attaque.sqf";
fnc_tactique_appuihelico = compile preprocessFile "hdssystem\modules\tactiques\les_tactiques\helicoptere-attaque.sqf";
fnc_tactique_insertion = compile preprocessFile "hdssystem\modules\tactiques\les_tactiques\insertion-defense.sqf";

fnc_tactique_init = compile preprocessFile "hdssystem\modules\tactiques\init-evenements.sqf";
fnc_tactique_plannification = compile preprocessFile "hdssystem\modules\tactiques\init-plannification.sqf";
