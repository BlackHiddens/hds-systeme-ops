# Hiddens Système Opérations (hds-ops)

> **Un framework Arma 3 pour créer des missions complexes et scénarisées en un temps record.**
> Concentre-toi sur l'ambiance et l'histoire de ta mission, pas sur la technique et les limites du possible.

hds-ops s'occupe aussi des petits détails que les éditeurs oublient souvent : paramétrer les factions, désactiver les IA des slots joueurs, créer un point de réapparition, etc.

---

## Démarrer en 3 étapes

| Étape | Ce que tu fais | Page |
|:-:|---|---|
| **1** | Copier hds-ops dans ta mission et vérifier les prérequis | [Installation](Installation) |
| **2** | Déclarer tes slots, objets et options dans `mes-parametres.sqf` | [Configuration](Configuration) |
| **3** | Écrire le déroulement de ta mission dans `hdssystem\init-scenario.sqf` | [Écrire son scénario](Ecrire-son-scenario) |

**Exemple complet d'une mission publique** (5 missions aléatoires enchaînées, avec civils et trafic routier) :

```sqf
[0,0,10] call fnc_scenario_init;   // contexte de mission
[3,west] call fnc_renfort_init;    // 3 appels de renfort alliés
[] spawn fnc_engima_traffic;       // trafic routier civil

[500,0,5,1,["NameVillage","NameLocal"],true,true,1] spawn fnc_hds_missions;
```

---

## Ce que hds-ops fait tout seul

- Désactive les IA des slots joueurs à la connexion.
- Force la première réapparition sans tenir compte des marqueurs de réapparition.
- Crée automatiquement un point de réapparition BLUFOR là où se trouvent les premiers joueurs connectés.
- Pose un marqueur BLUFOR (zone de 100 m) sur cette première zone d'apparition.
- Détecte les addons présents (ACE3, RHS, Project OPFOR…) et active le contenu correspondant.
- Configure les slots (chefs, radios, médecins, ingénieurs, pilotes, contractors) selon leur rôle : voir [Configuration](Configuration#les-slots-joueurs).

---

## Les modules

hds-ops fonctionne avec quatre modules principaux. Ils travaillent ensemble : un module en appelle un autre pour affiner ses possibilités.

| Module | Dossier | Rôle |
|---|---|---|
| **hds-occupations** | `modules\occupations` | Peuple une zone : civils, garnisons, patrouilles, véhicules, renforts alliés. |
| **hds-tactiques** | `modules\tactiques` | Commande les troupes IA : renfort terrestre, contre-attaque, appui hélicoptère, insertion. |
| **hds-missions** | `modules\missions` | Génère des missions automatiques, sans éditer ta mission. |
| **hds-scenario** | `modules\scenario` | Tâches scénarisées (otages, destruction, collecte…). Il s'écrit dans `init-scenario.sqf`, ta « feuille d'instructions ». |

Et aussi :

- le dossier `hdssystem\fonctions` : arsenaux, lieux de soins, postes de communication, garage virtuel, boutique, ravitaillement… (voir [Référence des fonctions](Reference-des-fonctions)) ;
- un module expérimental `commandant` (voir [Architecture](Architecture#le-module-commandant)) ;
- des outils intégrés : **gcam** (caméra), **Engima's Traffic** (trafic civil) et **Virtual Garage**.

---

## Toutes les pages

| Page | Contenu |
|---|---|
| [Installation](Installation) | Prérequis, copie des fichiers, préparation de l'éditeur |
| [Configuration](Configuration) | Tout `mes-parametres.sqf` : objets, slots, appuis, options, prix |
| [Écrire son scénario](Ecrire-son-scenario) | `init-scenario.sqf`, exemples public et privé |
| [Référence des fonctions](Reference-des-fonctions) | Paramètres de chaque fonction |
| [Factions](Factions) | Numéros de faction (0 à 7) et addons requis |
| [Architecture](Architecture) | Ordre de démarrage, convention des fonctions, étendre le projet |
| [Dépannage](Depannage) | Problèmes fréquents, limites connues |

*Version du script : `ai-hds-systeme.stable` (variable `hdsversion`).*
