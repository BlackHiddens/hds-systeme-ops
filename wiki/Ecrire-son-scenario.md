# Écrire son scénario : `init-scenario.sqf`

> **Où écrire ma mission ?** Dans `hdssystem\init-scenario.sqf`.

Ce fichier est ton **journal de bord** : c'est lui qui déroule ta mission. Avec `mes-parametres.sqf`, c'est le seul fichier dans lequel tu devrais avoir besoin d'écrire.

Il est exécuté par le serveur, à la fin de `initserver.sqf`. Tu peux donc y utiliser `waituntil` et `sleep` pour enchaîner les étapes.

---

## Les deux parties d'un scénario

```
init-scenario.sqf
├── 1. Le contexte   → règles générales (tâches, renforts, trafic)
└── 2. Le déroulé    → ce qui se passe, dans l'ordre
```

### 1. Le contexte

Trois lignes, quasiment toujours les mêmes :

```sqf
[0,0,10] call fnc_scenario_init;   // [tâchesDéjàFaites, rémunération, pointsVéhicule]
[3,west] call fnc_renfort_init;    // [nombreAppelsDeRenfort, campDesRenforts]
[] spawn fnc_engima_traffic;       // trafic routier civil
```

| Ligne | Paramètres | Détail |
|---|---|---|
| `fnc_scenario_init` | tâches déjà faites au départ, rémunération par tâche (si `boutiqueactive`), points de véhicule du garage virtuel | [Référence](Reference-des-fonctions#contexte-de-mission) |
| `fnc_renfort_init` | nombre d'appels de renfort, camp des renforts | idem |
| `fnc_engima_traffic` | aucun | Retire cette ligne si tu ne veux pas de trafic civil |

### 2. Le déroulé

Tu enchaînes ensuite les fonctions des modules (occupations, tactiques, missions, scénario). Voir la [Référence des fonctions](Reference-des-fonctions).

---

## Le compteur de tâches `tache_scenario`

- Il démarre à la valeur donnée en premier paramètre de `fnc_scenario_init` (en général `0`).
- Chaque tâche des `fnc_scenario_*` qui se termine **ajoute 1** (pour les otages, qu'elle soit réussie ou échouée).
- Tu l'utilises pour attendre l'avancement de ta mission :

```sqf
waituntil {tache_scenario > 0};    // au moins 1 tâche terminée
waituntil {tache_scenario >= 3};   // au moins 3 tâches terminées
```

> **Piège classique :** avec **une seule** tâche scénarisée, `tache_scenario` ne vaut que `1` à la fin. Un `waituntil {tache_scenario > 1}` ne se déclencherait jamais.
>
> Les missions aléatoires de `fnc_hds_missions` utilisent un compteur interne distinct (`tache_effectuee`) : tu n'as pas à t'en occuper.

---

## Exemple 1 : une mission publique

> À laisser tourner en semaine. 5 missions aléatoires s'enchaînent, avec des factions tirées au hasard. Les civils sont présents et circulent sur les routes.

```sqf
// ----- Contexte -----
[0,0,10] call fnc_scenario_init;
[3,west] call fnc_renfort_init;
[] spawn fnc_engima_traffic;

// ----- Déroulé -----
// [rayon, faction, nbMissions, difficulté, typesDeLieux, civils, factionAléatoire, nbTâchesParMission]
[500,0,5,1,["NameVillage","NameLocal"],true,true,1] spawn fnc_hds_missions;
```

| Valeur | Signification |
|---|---|
| `500` | Chaque mission se déroule dans un rayon de 500 m |
| `0` | Faction de départ. **Ignorée** ici, car la faction aléatoire est à `true` |
| `5` | 5 missions enchaînées |
| `1` | Difficulté 1 |
| `["NameVillage","NameLocal"]` | Les missions apparaissent dans des villages et des lieux particuliers |
| `true` | Des civils sont présents sur place |
| `true` | La faction ennemie est tirée au hasard |
| `1` | Chaque mission comporte 1 objectif aléatoire |

> **Attention :** `fnc_hds_missions` attend **8 paramètres**. Le huitième (le nombre de tâches par mission) est obligatoire.

Détail complet : [`fnc_hds_missions`](Reference-des-fonctions#fnc_hds_missions).

---

## Exemple 2 : un scénario privé

> Une soirée scénarisée. Il y a 3 appels de renfort alliés et du trafic civil. L'objectif est de récupérer 2 pilotes otages. Quand ils sont libérés, l'ennemi contre-attaque.

La zone est occupée par la faction 6 (milice afghane, **Project OPFOR requis**, voir [Factions](Factions)). Le commandant IA planifie entre 3 et 5 événements dans un rayon de 500 m autour de la mission : ils se déclenchent quand un joueur entre dans la zone.

```sqf
// ----- Contexte -----
[0,0,10] call fnc_scenario_init;
[3,west] call fnc_renfort_init;
[] spawn fnc_engima_traffic;

// ----- Déroulé -----
// hds-tactiques surveille la zone : de 3 à 5 événements imprévus
[[4506.92,5729.59,0],500,6,3,5] spawn fnc_tactique_plannification;

// hds-occupations place des ennemis dans la zone
[[4506.92,5729.59,0],1,6,500,false] spawn fnc_hds_occupations;

// Mission d'extraction des pilotes
[
  [4506.92,5729.59,0],                          // centre de la mission
  [4847.85,4598.72,0],                          // où ramener les otages
  [otage_0,otage_1],                            // les otages posés dans l'éditeur
  "pilotes de l'IDAP",                          // nom affiché
  "Trouver et libérer les pilotes de l'IDAP",   // description
  50,                                           // rayon de la zone
  false                                         // marqueur invisible sur la carte
] spawn fnc_scenario_otage;

// Attendre que la mission soit terminée
waituntil {tache_scenario > 0};

// L'ennemi contre-attaque (remplace par les coordonnées de ta base)
[[4502.1,5681.85,0],2,5,700,6,false] spawn fnc_tactique_contreattaque;
```

---

## Conseils

- **`spawn` ou `call` ?** Utilise `call` pour le contexte (`fnc_scenario_init`, `fnc_renfort_init`) et `spawn` pour tout le reste : ces fonctions attendent et tournent en tâche de fond.
- **Positions** : tu peux relever les coordonnées dans l'éditeur (`[x,y,z]`).
- **Objets de l'éditeur** (`otage_0`, déclencheurs, véhicules…) : écris leur nom de variable **sans guillemets**.
- **Mode debug** : passe `hdssysteme = true` dans `mes-parametres.sqf` pour suivre chaque étape dans le chat.
- **Présence hostile d'ambiance** : [`fnc_hds_presence_hostile`](Reference-des-fonctions#fnc_hds_presence_hostile) ajoute de l'occupation ennemie sur plusieurs lieux sans créer de mission.

Tous les paramètres sont dans la [Référence des fonctions](Reference-des-fonctions).
