// ─────────────────────────────────────────────────────────────
// TA MISSION — ce fichier n'appartient qu'à toi.
// Tu peux remplacer tout son contenu par ce que sort le générateur
// hds-ops : il ne contient aucun code du système. Celui-ci est dans
// hdssystem\init-systeme.sqf, qui est appelé avant et qui compile
// toutes les fonctions utilisées ici.
// Tourne côté serveur, dans un contexte ordonnancé (spawn/sleep ok).
// ─────────────────────────────────────────────────────────────

// Mission générée avec le générateur hds-ops.

// ----- Contexte -----
[3, west] call fnc_renfort_init;
[0, 0, 10] call fnc_scenario_init;

// Vie civile : trafic sur les routes et habitants dans les
// agglomérations, entretenus autour des joueurs et supprimés dès qu'ils
// s'éloignent. Tout se règle ici, dans l'ordre :
//   véhicules en circulation, habitants par agglomération, poser
//   l'ambiance, rayon d'ambiance (m), portée du trafic (m), oubli (m).
// -1 : laisser le curseur du menu CBA décider.
[8, -1, true, 300, 500, 1200] spawn fnc_hds_vie_civile;

// ----- Déroulé -----

// Étape 1 - Occuper une zone
[[4349,3809,0], 3, "rhs_faction_vdv", 300, false] spawn fnc_hds_occupations;

// Étape 2 - Surveiller une zone
[[4349,3809,0], 500, "rhs_faction_vdv", 4, 7] spawn fnc_tactique_plannification;

// Étape 3 - Renforts alliés en plus
[3] spawn fnc_scenario_renfort;

// Étape 4 - Sécuriser une zone
[[4349,3809,0], "Air station Mike-26", 150] spawn fnc_scenario_securiser;
