# Configuration : `mes-parametres.sqf`

`mes-parametres.sqf` se trouve **à la racine de ta mission**. C'est ton fichier de configuration : il est chargé par le serveur **et** par chaque client.

Voici le début du fichier, commenté. Les sections suivantes détaillent chaque variable.

```sqf
//Mes outils
hdsversion = "ai-hds-systeme.stable";   // nom de version, affiché dans les messages du mode debug
hdsnombase = ["hds-ros-base"];          // NOM DU MARQUEUR posé sur ta base
hdssysteme = false;                     // mode debug : hds-ops annonce tout ce qu'il fait

//Tous mes objets scriptés
lelieuestunvehicule = false;            // les lieux de soins sont-ils des véhicules ?
sontdeslieudesoin = [soins];            // objets : lieux de soins
sontdesarsenales = [arsenal_console];   // objets : arsenaux
sontdespostesdecommunications = [arsenal_console];            // objets : terminaux de communication
estungarage = [arsenal_console,[8237.49,10049.9,0]];          // [objet, position d'apparition des véhicules]
estunravitaillement = [[8237.49,10049.9,0],10];               // [position, rayon]

//Tous les slots (noms de variable ENTRE GUILLEMETS)
sontdesmanageurs = ["chef_one","chef_two"];
sontdesexpertcoms = ["communication_one","communication_two"];
sontdesmedecins = ["medecin_one","medecin_two"];
sontdesingenieurs = ["mecano_one","mecano_two"];
sontdespilotes = ["pilote_one","pilote_two"];
sontdescontractor = ["contractor_1","contractor_2","contractor_3","contractor_4"];

//Tous les appuis (objets SANS guillemets)
sontdesappuismanageurs = [radio_appui];
sontdesappuisexpertcoms = [radio_appui];
sontdesappuismedicals = [radio_appui];
sontdesappuisingenieurs = [radio_appui];
sontdesappuispilotes = [radio_appui];
sontdesappuiscontractor = [radio_appui];
```

> **La règle à retenir : guillemets ou pas ?**
>
> | Tu déclares… | Écriture | Exemple |
> |---|---|---|
> | un **slot joueur** | entre guillemets : c'est son *nom de variable* | `"chef_one"` |
> | un **objet** de la carte | sans guillemets : c'est l'objet lui-même | `arsenal_console` |
>
> Les noms de slots doivent correspondre **exactement** (casse comprise) au nom de variable posé dans l'éditeur.

---

## Les outils

| Variable | Valeur | Rôle |
|---|---|---|
| `hdsversion` | texte | Nom de version. Préfixe les messages du mode debug. |
| `hdsnombase` | `["nom_du_marqueur"]` | Nom du **marqueur** de ta base. Utilisé par les missions d'otages aléatoires (l'otage doit être ramené à moins de 100 m de ce marqueur) et comme nom du point de réapparition créé automatiquement. |
| `hdssysteme` | `true` / `false` | Mode debug : affiche dans le chat système chaque étape des missions générées. |

> **Important :** `hdsnombase` n'est pas décoratif. Sans marqueur portant ce nom, une mission d'otages aléatoire ne peut pas se terminer. Voir [Dépannage](Depannage).

---

## Les objets scriptés

| Variable | Contenu | Ce que hds-ops en fait |
|---|---|---|
| `sontdeslieudesoin` | liste d'objets | Les transforme en lieux de soins (ACE3). |
| `lelieuestunvehicule` | `true` / `false` | `true` : les lieux de soins sont des véhicules ; `false` : ce sont des lieux fixes. |
| `sontdesarsenales` | liste d'objets | Y ajoute un arsenal. |
| `sontdespostesdecommunications` | liste d'objets | Terminaux qui mettent des ressources à disposition des joueurs. |
| `estungarage` | `[objet, position]` | Terminal du garage virtuel + position d'apparition des véhicules achetés. |
| `estunravitaillement` | `[position, rayon]` | Zone de ravitaillement des véhicules. |

---

## Les slots joueurs

Les slots sont configurés automatiquement selon la liste où tu les ranges. Chaque joueur reçoit aussi le menu de communication **« exécuter la caméra »** (gcam).

| Variable | Rôle | Ce que le joueur reçoit |
|---|---|---|
| `sontdesmanageurs` | Chefs | Pose d'attelle, menu **appeler des mercenaires**, traits ingénieur et médecin (classe médicale ACE 1) |
| `sontdesexpertcoms` | Opérateurs radio | Menu **appeler des mercenaires**, trait `UAVHacker` |
| `sontdesmedecins` | Médecins | Pose d'attelle, trait médecin (classe médicale ACE 1) |
| `sontdesingenieurs` | Mécaniciens | Traits ingénieur et spécialiste explosifs (peuvent réparer les véhicules) |
| `sontdespilotes` | Pilotes | Trait ingénieur, action **créer un équipage** dans leur véhicule |
| `sontdescontractor` | Contractors | Pose d'attelle, menu **appeler des mercenaires** |

Les appels de renfort sont limités par le nombre que tu fixes avec `fnc_renfort_init` (voir [Référence des fonctions](Reference-des-fonctions#contexte-de-mission)). Un clic sur la carte envoie alors un groupe de 8 soldats.

---

## Les appuis

Chaque variable `sontdesappuis…` contient les **objets d'appui** (par exemple un module de demande d'appui posé dans l'éditeur) qui sont synchronisés à chaque joueur du rôle correspondant. Ainsi ce joueur peut solliciter l'appui.

| Variable | Rôle concerné |
|---|---|
| `sontdesappuismanageurs` | Chefs |
| `sontdesappuisexpertcoms` | Opérateurs radio |
| `sontdesappuismedicals` | Médecins |
| `sontdesappuisingenieurs` | Ingénieurs |
| `sontdesappuispilotes` | Pilotes |
| `sontdesappuiscontractor` | Contractors |

- Pour **donner** l'appui à un rôle : `sontdesappuismedicals = [radio_appui];`
- Pour le **retirer** : `sontdesappuismedicals = [];`

> **Attention aux noms :** la variable des opérateurs radio est `sontdesappuis`**`expertcoms`** (et non « exoertcoms »). Une faute de frappe crée une variable inutilisée, sans message d'erreur.

> **Pilotes :** la variable `sontdesappuispilotes` est déclarée, mais aucune synchronisation d'appui n'est appliquée aux pilotes par `init-client.sqf` : seule l'action « créer un équipage » leur est ajoutée.

---

## Les options

| Variable | Défaut | Rôle |
|---|:-:|---|
| `boutiqueactive` | `false` | Active le mode argent : une rémunération est versée à chaque tâche (voir `fnc_scenario_init`). Le compte est stocké dans le profil du joueur. |
| `modehardactive` | `false` | Active le mode « hard » (élimination d'équipement). |
| `sauvegarderlesequipements` | `false` | Sauvegarde et recharge l'équipement des joueurs sur le serveur. |

### Les prix de la boutique

Le tableau `prix` définit le prix de chaque catégorie d'équipement, dans cet ordre :

| Index | Catégorie |
|:-:|---|
| 0 | Arme principale |
| 1 | Arme secondaire |
| 2 | Pistolet |
| 3 | Chargeur |
| 4 | Sac à dos |
| 5 | Module (accessoire) d'arme principale |
| 6 | Module de pistolet |
| 7 | Objet |
| 8 | Lunettes ou bandana |
| 9 | Vision nocturne |
| 10 | Gilet |
| 11 | Chapeaux et casques |

---

## Administrateurs

```sqf
hds_administrateurs = [
"76561198000000000", //Pseudo 1
"76561198000000001"  //Pseudo 2
];
```

Liste des identifiants Steam (UID) des administrateurs du serveur qui héberge la mission. Remplace les valeurs d'exemple par les tiens.

---

## Détection des addons

Cette partie est automatique : tu n'as rien à modifier. Voir [Installation](Installation#optionnels-détectés-automatiquement).

---

## Suite

Ta mission est configurée : [écris maintenant son déroulement](Ecrire-son-scenario).
