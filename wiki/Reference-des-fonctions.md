# Référence des fonctions

Tous les paramètres sont à passer **dans l'ordre**, entre crochets, avant le nom de la fonction.

```sqf
[param0, param1, param2] spawn fnc_nom_de_la_fonction;
```

## Types utilisés

| Type | Signification | Exemple |
|---|---|---|
| `position` | Coordonnées `[x,y,z]` | `[4506.92,5729.59,0]` |
| `entier` | Nombre entier | `500` |
| `booléen` | `true` ou `false` | `false` |
| `texte` | Entre guillemets | `"Pilotes"` |
| `faction` | Numéro de faction, de 0 à 7 : voir [Factions](Factions) | `6` |
| `camp` | Un camp Arma : `west`, `east`, `independent` | `west` |
| `objet` | Nom de variable d'un objet de l'éditeur, **sans guillemets** | `otage_0` |

## Sommaire

- [Contexte de mission](#contexte-de-mission)
- [Missions automatiques](#missions-automatiques)
- [Occupations](#occupations)
- [Tactiques](#tactiques)
- [Tâches scénarisées](#tâches-scénarisées)
- [Joueurs, équipement et soutien](#joueurs-équipement-et-soutien)

---

## Contexte de mission

À placer en tête de `init-scenario.sqf`, avec `call`.

### `fnc_scenario_init`

```sqf
[0,0,10] call fnc_scenario_init;
```

| # | Nom | Type | Description |
|:-:|---|---|---|
| 0 | tâches déjà faites | entier | Valeur de départ de `tache_scenario` |
| 1 | rémunération | entier | Somme versée à chaque tâche (si `boutiqueactive`) |
| 2 | points de véhicule | entier | Nombre de véhicules achetables via le garage virtuel |

### `fnc_renfort_init`

```sqf
[3,west] call fnc_renfort_init;
```

| # | Nom | Type | Description |
|:-:|---|---|---|
| 0 | nombre | entier | Nombre d'appels de renfort disponibles |
| 1 | camp | camp | Camp des renforts |

Un joueur appelle le renfort par le menu de communication **« appeler des mercenaires »** (voir [Configuration](Configuration#les-slots-joueurs)). Il clique sur la carte et un groupe de 8 soldats se met en route.

### `fnc_engima_traffic`

```sqf
[] spawn fnc_engima_traffic;
```

Trafic routier civil (Engima's Traffic). Aucun paramètre. Sa configuration est décrite dans `engima\Traffic\Documentation.txt`.

### `fnc_scenario_renfort`

```sqf
[2] spawn fnc_scenario_renfort;
```

| # | Nom | Type | Description |
|:-:|---|---|---|
| 0 | nombre | entier | Nombre d'interventions d'une force alliée créditées par mission |

---

## Missions automatiques

### `fnc_hds_missions`

Génère une suite de missions aléatoires, séparées par un temps d'attente aléatoire (entre 200 et 600 secondes).

```sqf
[700,0,2,1,["NameCity","NameLocal","NameVillage"],true,false,3] spawn fnc_hds_missions;
```

| # | Nom | Type | Description |
|:-:|---|---|---|
| 0 | rayon | entier | Rayon d'action de la mission, en mètres |
| 1 | faction | faction | Faction ennemie. Ignorée si le paramètre 6 vaut `true` |
| 2 | nbMissions | entier | Nombre de missions enchaînées |
| 3 | difficulté | entier | Ratio de difficulté de l'occupation. Le nombre maximum d'événements tactiques vaut difficulté + 1 |
| 4 | lieux | tableau | Types de lieux où une mission peut apparaître (voir ci-dessous) |
| 5 | civils | booléen | `true` : des civils sont présents sur place |
| 6 | factionAléatoire | booléen | `true` : la faction est tirée au hasard et le paramètre 1 est ignoré |
| 7 | nbTâches | entier | Nombre d'objectifs aléatoires par mission. **Obligatoire** |

**Types de lieux** (paramètre 4) :

| Valeur | Lieu |
|---|---|
| `"NameVillage"` | Village |
| `"NameCity"` | Ville |
| `"Name"` | Endroit commun |
| `"NameLocal"` | Endroit particulier |
| `"Strategic"` | Base militaire |

Liste complète : [Location (Bohemia wiki)](https://community.bistudio.com/wiki/Location).

**Déroulement d'une mission :**

1. Choix d'un lieu au hasard sur la carte, puis attente d'au moins un joueur sur le serveur.
2. Occupation ennemie et planification tactique autour du lieu.
3. Civils (si demandés), adaptés à la faction.
4. Création des `nbTâches` objectifs aléatoires, dans un rayon de `rayon / 1,5`.
5. Quand tous les objectifs sont terminés : les points de véhicule augmentent de `nbTâches` et un message l'annonce.
6. Attente aléatoire, puis nettoyage du secteur (unités, véhicules et marqueurs dans le rayon), puis mission suivante.

**Les objectifs aléatoires** sont tirés parmi :

| Fonction | Type d'objectif |
|---|---|
| `fnc_objectif_communication` | Communication |
| `fnc_objectif_otage` | Otage (à ramener près du marqueur `hdsnombase`) |
| `fnc_objectif_logistique` | Logistique |
| `fnc_objectif_tuer` | Éliminer une cible |
| `fnc_objectif_infos` | Informations |
| `fnc_objectif_piratage` | Piratage |
| `fnc_objectif_capturerTenir` | Capturer et tenir |
| `fnc_objectif_cacheArmes` | Cache d'armes |
| `fnc_objectif_apprehender` | Appréhender |
| `fnc_objectif_securiser` | Sécuriser |

Ils sont lancés par `fnc_objectif_aleatoire` avec `[position, rayon, faction]`.

### `fnc_hds_presence_hostile`

Ajoute de l'occupation ennemie et de la surveillance tactique sur les lieux de la carte, **sans créer de mission**.

```sqf
[100,3,false,1,["NameVillage","NameCity","NameLocal"]] spawn fnc_hds_presence_hostile;
```

| # | Nom | Type | Description |
|:-:|---|---|---|
| 0 | rayon | entier | Rayon de chaque zone occupée |
| 1 | faction | faction | Faction ennemie |
| 2 | toujoursPrésent | booléen | `true` : tous les lieux correspondants sont occupés. `false` : environ un lieu sur quatre |
| 3 | difficulté | entier | Ratio de difficulté |
| 4 | lieux | tableau | Types de lieux (voir ci-dessus) |

---

## Occupations

### `fnc_hds_occupations`

Génère l'occupation d'une zone par une faction : garnisons, patrouilles et véhicules.

```sqf
[[4506.92,5729.59,0],1,6,500,false] spawn fnc_hds_occupations;
```

| # | Nom | Type | Description |
|:-:|---|---|---|
| 0 | centre | position | Centre de la zone |
| 1 | ratio | entier | Densité/difficulté de l'occupation |
| 2 | faction | faction | Faction qui occupe la zone |
| 3 | taille | entier | Rayon de la zone, en mètres |
| 4 | visible | booléen | Réservé : non utilisé par le code actuel. Mets `false` |

---

## Tactiques

Les tactiques commandent les troupes IA. Le paramètre de camp est un **numéro de faction** (voir [Factions](Factions)).

### `fnc_tactique_plannification`

Surveille une zone et y déclenche de 3 à 5 (par exemple) événements tactiques au hasard.

```sqf
[[4506.92,5729.59,0],500,6,3,5] spawn fnc_tactique_plannification;
```

| # | Nom | Type | Description |
|:-:|---|---|---|
| 0 | position | position | Centre de la zone surveillée |
| 1 | rayon | entier | Taille de la zone surveillée |
| 2 | faction | faction | Faction qui mène les événements |
| 3 | min | entier | Nombre minimum d'événements |
| 4 | max | entier | Nombre maximum d'événements |

### `fnc_tactique_init`

Fonction appelée par la planification pour générer **une** tactique aléatoire. Elle attend qu'un joueur entre dans la zone, patiente entre 100 et 700 secondes, puis choisit une tactique.

| # | Nom | Type | Description |
|:-:|---|---|---|
| 0 | position | position | Centre de la zone |
| 1 | distance | entier | Distance d'approche des troupes ennemies |
| 2 | faction | faction | Faction qui mène l'événement |

### Les tactiques individuelles

Elles prennent toutes `[position, distance, faction]`.

| Fonction | Effet |
|---|---|
| `fnc_tactique_renfortterrestre` | Fait apparaître un véhicule de transport rempli de soldats |
| `fnc_tactique_appuihelico` | Fait apparaître un hélicoptère d'attaque qui patrouille autour d'un joueur choisi au hasard |
| `fnc_tactique_insertion` | Déploie des renforts d'infanterie par voie aérienne, si possible |

```sqf
[[4506.92,5729.59,0],800,3] spawn fnc_tactique_appuihelico;
```

### `fnc_tactique_contreattaque`

```sqf
[[4502.1,5681.85,0],2,5,700,6,false] spawn fnc_tactique_contreattaque;
```

| # | Nom | Type | Description |
|:-:|---|---|---|
| 0 | position | position | Position visée |
| 1 | nbGroupesInfanterie | entier | Nombre de groupes d'infanterie |
| 2 | nbVéhicules | entier | Nombre de véhicules |
| 3 | distanceApproche | entier | Distance de départ de l'attaque |
| 4 | faction | faction | Faction attaquante |
| 5 | cibleMarqueur | booléen | Réservé : non utilisé par le code actuel. Mets `false` |

---

## Tâches scénarisées

Fonctions du module **hds-scenario**, à utiliser dans `init-scenario.sqf` avec `spawn`. Chaque tâche terminée ajoute 1 à `tache_scenario`.

**Paramètres qui reviennent partout :**

| Nom | Signification |
|---|---|
| `position` | Centre de la mission |
| `taille` | Rayon de la zone de mission, en mètres |
| `visible` | `true` : zone visible sur la carte. `false` : invisible |
| `nom…`, `description` | Textes affichés dans la tâche |

| Fonction | Paramètres, dans l'ordre | But |
|---|---|---|
| `fnc_scenario_otage` | `[position, positionDeLivraison, otages, nomOtages, description, taille, visible]` | Libérer des otages (tableau d'objets) et les ramener à la position de livraison |
| `fnc_scenario_collecter` | `[position, objets, nomObjets, description, taille, visible]` | Récupérer des objets (tableau d'objets) |
| `fnc_scenario_detruire` | `[position, cibles, nomCibles, description, taille, visible]` | Détruire des cibles (tableau d'objets) |
| `fnc_scenario_apprehender` | `[position, positionDeLivraison, cible, nomCible, description, taille, visible]` | Appréhender une cible et la livrer |
| `fnc_scenario_rejoindre` | `[position, nomPosition, description, taille, visible]` | Rejoindre une position |
| `fnc_scenario_securiser` | `[position, nomZone, taille]` | Sécuriser une zone |
| `fnc_scenario_voler` | `[position, cible, nomCible, description]` | Voler un véhicule (la cible) |
| `fnc_scenario_telecharger` | `[position, objet, nom, description, taille, visible]` | Pirater un objet pour en récupérer les données |
| `fnc_scenario_personnalisee` | `[position, déclencheurRéussite, déclencheurÉchec, nomTâche, description, taille, visible]` | Tâche libre : réussie ou échouée selon deux déclencheurs de l'éditeur |

```sqf
[
  [4506.92,5729.59,0], [4847.85,4598.72,0], [otage_0,otage_1],
  "pilotes de l'IDAP", "Trouver et libérer les pilotes de l'IDAP", 50, false
] spawn fnc_scenario_otage;
```

---

## Joueurs, équipement et soutien

Ces fonctions sont normalement appelées par hds-ops à partir de `mes-parametres.sqf`. Tu n'as à les appeler toi-même que pour des cas particuliers.

| Fonction | Paramètres | Rôle |
|---|---|---|
| `fnc_hds_arsenaux` | `[objets]` | Ajoute un arsenal aux objets |
| `fnc_hds_arsenal_complet`, `_gios`, `_prive`, `_afghan`, `_numb` | `[objet]` | Arsenaux prédéfinis. Exemple : `[arsenal_afghan] call fnc_hds_arsenal_afghan;` |
| `fnc_hds_medical` | `[objets]` | Crée des lieux de soins |
| `fnc_hds_poste_de_communication` | `[objets]` | Crée des terminaux de communication |
| `fnc_hds_ravitaillement` | `[position, rayon]` | Zone de ravitaillement des véhicules |
| `fnc_hds_peuposerattelle` | `[joueur]` | Autorise un joueur à poser des attelles |
| `fnc_hds_creerequipages` | `[joueur, texte]` | Ajoute l'action « créer un équipage » |
| `fnc_hds_pointreapparition` | aucun | Crée un point de réapparition |
| `fnc_hds_demandeurderenforts` | `[objet]` | Demande de renforts depuis un objet |
| `fnc_support_avions` | `[classeAvion, camp, classeMunition]` | Appui aérien (bombardement) |
| `fnc_ace_garnir` | `[position, listeDeLeaders, taille, téléportation]` | Garnit les habitations de la zone avec les unités des leaders passés (utilise ACE) |
| `fnc_fnc_informations` | `[texte]` | Affiche un message d'information (le nom contient bien deux fois `fnc_`) |
| `fnc_hds_consteste` | `[campEnnemi, difficulté, rayon]` | Génère des zones contestées sur la carte |

Autres fonctions déclarées dans `mes-parametres.sqf` : `fnc_hds_boutique`, `fnc_hds_saveequipement`, `fnc_hds_soustitre`, `fnc_hds_utilisateurdegcam`, `fnc_hds_action_saut_parachute`, `fnc_hds_introduction`, `fnc_hds_fin`, `fnc_hds_garages`.
