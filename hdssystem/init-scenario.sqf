
/* --- Exécution des fonctions d'initialisation du scénario --- */

/*
0 : nombre de tâche effectuée au démarrage de la mission
1 : rénumération accordée à l'exécution d'un tâche si boutique activé
2 : nombre de véhicule achetable via le garage virtuel
*/

/*
0 : nombre d'appel de renfort
1 : faction des renforts
*/


/* --- Exécution des fonctions d'ambiance du scénario --- */
[] spawn fnc_engima_traffic;   // raffic civils sur routes

[5,west] call fnc_renfort_init;
[0,0,99] call fnc_scenario_init; //[nombre tache initial scenario, renumeration, point de vihicule]

/*
[[2513.287,3156.919,0],3,4,150,false]  spawn fnc_hds_occupations;
[[2513.287,3156.919,0],3,150,1,false]  spawn fnc_hds_populations;params ["_Centre","_Ratio","_Taille","_Nationalite","_Visible"];

Ajouter une occupation sans mission sur les positions selectionnées
[<entier-rayon>,<entier-faction>,<booleen-toujourspresent>,<entier-difficulter>,<tableau-typelocation>] spawn fnc_hds_presence_hostile;
exemple : [100,3,false,1["NameVillage","NameCity","NameLocal"]] spawn fnc_hds_presence_hostile;

Pour la location consulter :
https://community.bistudio.com/wiki/Location

*/

//----- Début du scénario -------

[500,6,5,3,["NameVillage","NameCity","NameLocal","Name"],true,true,3] spawn fnc_hds_missions;


/*


[arsenal_afghan] call fnc_hds_arsenal_afghan;
[arsenal_gios] call fnc_hds_arsenal_afghan;

["hds_action","playmusic",true,true] spawn bis_fnc_mp;
waituntil {tache_scenario == 4};

[
  ["LeadTrack01_F_Tacops",
    [
    "Fin du scénario",
    "2 Semaines de préparation à été nécéssaire",
    "Je vous remercie d'y avoir jouer. ça me fait plaisir",
    "c'était plus une sortie epique qu'un commencement",
    "Aurevoir et a bientot dans une autre contexte",
    "FIN",
    "FIN",
    "FIN",
    "FIN",
    "FIN"
    ]
  ],
  "fnc_hds_fin",true,true
] spawn bis_fnc_mp; */

//----- Fin du scénario -----------
