# Factions

Partout où une fonction demande une `faction` (ou un `camp` dans les tactiques), tu donnes un **numéro de 0 à 7**.

| N° | Faction | Camp Arma | Addon requis | Tirage aléatoire des missions |
|:-:|---|---|---|:-:|
| **0** | CSAT | `east` | aucun | ✅ |
| **1** | AAF | `independent` | aucun | ✅ |
| **2** | Américains (BLUFOR) | `west` | aucun | ❌ faction alliée |
| **3** | FIA | `east` | aucun | ✅ |
| **4** | Boko Haram | `east` | Project OPFOR | ✅ |
| **5** | Russes (RHS) | `east` | RHS AFRF | ✅ |
| **6** | Afghans | `east` | Project OPFOR | ✅ |
| **7** | État islamique | `east` | Project OPFOR | ❌ |

> **Tirage aléatoire :** quand `fnc_hds_missions` reçoit `factionAléatoire = true`, la faction est tirée au hasard parmi **0, 1, 3, 4, 5 et 6**. La faction 2 est la faction alliée et la 7 doit être demandée explicitement.

> **Addon absent :** si tu demandes une faction dont l'addon n'est pas chargé, c'est la **faction 0 (CSAT)** qui apparaît à la place. Le tirage aléatoire peut donc donner du CSAT en l'absence de Project OPFOR ou de RHS AFRF.

## Relations entre les camps

Elles sont définies au démarrage du serveur (`init-serveur.sqf`).

| | `west` | `east` | `independent` | `civilian` |
|---|:-:|:-:|:-:|:-:|
| `west` | | ennemi | ennemi | allié |
| `east` | ennemi | | allié | allié |
| `independent` | ennemi | allié | | allié |

Les civils sont alliés avec tout le monde. `east` et `independent` sont alliés entre eux.

## Civils

Avec `fnc_hds_missions` et `civils = true`, la population civile s'adapte à la faction : un type de civils distinct est utilisé pour les factions **4**, **5** et **6**, et le type par défaut pour les autres.

## Équipes de renfort allié

Les équipes de renfort allié sont définies dans `modules\occupations\h-renfortallie\h-rosequipes\` : assaut, soutien, équipage, pilotes et spéciale, chacune en variantes **desert**, **tiger** et **urbain**.

## Ajouter une faction

Voir [Architecture](Architecture#ajouter-une-faction).
