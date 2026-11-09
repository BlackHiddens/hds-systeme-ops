# Installation

hds-ops s'installe **à la racine du dossier de ta mission**, celui qui contient ton `mission.sqm`. Le dépôt ne contient pas de `mission.sqm` : c'est à toi de fournir la mission (carte, slots, objets).

---

## 1. Prérequis

### Obligatoires

| Addon | Pourquoi |
|---|---|
| **CBA_A3** | Création des marqueurs (`cba_fnc_createmarker`) dans `init-serveur.sqf` |
| **ACE3** | Module Zeus/curator (`ace_modules_fnc_moduleInit`) et médical, appelés sans vérification dans `init-serveur.sqf` |

> **À savoir :** `mes-parametres.sqf` détecte ACE3 (variable `aceestactive`), mais `init-serveur.sqf` l'appelle sans vérifier. Sans ACE3 et CBA, le serveur génère des erreurs au démarrage.

### Optionnels (détectés automatiquement)

La détection se fait par `CfgPatches` dans `mes-parametres.sqf`. Rien à configurer : si l'addon est chargé, son contenu devient disponible.

| Addon | Variable | Effet connu |
|---|---|---|
| Project OPFOR | `opforactive` | Factions 4, 6 et 7 ([Factions](Factions)) |
| RHS AFRF | `afrfactive` | Faction 5 (Russes) |
| RHS USAF | `usafactive` | Détecté |
| RDS Civilian Pack | `rdsactive` | Civils supplémentaires |
| Project Numb 3 | `numbactive` | Détecté |
| FoxFor Camo Pack | `foxforactive` | Détecté |
| C.O.S | `cosactive` | Détecté |

> Si tu demandes une faction dont l'addon est absent, c'est la faction **0 (CSAT)** qui est utilisée à la place.

---

## 2. Copier les fichiers

Copie le contenu du dépôt à la racine de ta mission :

```
ta_mission.NomDeLaCarte\
├── mission.sqm              ← ta mission
├── description.ext          ← fourni par hds-ops (à fusionner si tu as déjà le tien)
├── initserver.sqf           ← idem
├── initplayerlocal.sqf      ← idem
├── onplayerrespawn.sqf      ← idem
├── mes-parametres.sqf       ← TA configuration
├── stringtable.xml
├── hdssystem\               ← le framework (init-scenario.sqf s'y trouve)
├── conversations\
├── engima\
├── gcam\
└── virtualgarage\
```

### Si ta mission a déjà ces fichiers : fusionne-les

Chaque fichier doit contenir **au minimum** les lignes suivantes.

**`initserver.sqf`**

```sqf
#include "mes-parametres.sqf"
#include "virtualgarage\virtualgarage.sqf"
#include "hdssystem\init-serveur.sqf"
#include "hdssystem\modules\occupations\h-init.sqf"
#include "hdssystem\modules\tactiques\h-init.sqf"
#include "hdssystem\modules\missions\h-init.sqf"
#include "hdssystem\modules\scenario\h-init.sqf"
//Exécution du scénario choisi
#include "hdssystem\init-scenario.sqf"
```

**`initplayerlocal.sqf`**

```sqf
#include "mes-parametres.sqf"
#include "hdssystem\init-client.sqf"
#include "hdssystem\modules\occupations\h-init.sqf"
```

**`onplayerrespawn.sqf`**

```sqf
#include "hdssystem\init-reapparition.sqf"
```

**`description.ext`** : en plus de tes propres réglages, hds-ops a besoin de :

```sqf
#include "gcam\gcam_component.hpp"       // interface de la caméra gcam

class CfgFunctions
{
    #include "hdssystem\modules\commandant\init.hpp"
};

class CfgCommunicationMenu
{
    class Renfort_terrestre                // menu « appeler des mercenaires »
    {
        text = "call contractor | appeler des mercenaires";
        submenu = "";
        expression = "[player] spawn fnc_renfort_allie;";
        icon = "\a3\Ui_f\data\GUI\Cfg\CommunicationMenu\call_ca.paa";
        cursor = "";
        enable = 1;
        removeAfterExpressionCall = 0;
    };
    class Executer_gcam                    // menu « exécuter la caméra »
    {
        text = "executed camera | exécuter la camera";
        submenu = "";
        expression = "[player] execVM 'gcam\gcam.sqf';";
        icon = "a3\Ui_f\data\GUI\Cfg\RespawnRoles\recon_ca.paa";
        cursor = "";
        enable = 1;
        removeAfterExpressionCall = 0;
    };
};
```

> **Attention :** `initserver.sqf` et `initplayerlocal.sqf` utilisent `#include` et non `execVM`. Tout partage donc le même contexte d'exécution. Ne remplace pas les `#include` par des `execVM`.

Réglages de réapparition fournis dans `description.ext` (modifiables) :

```sqf
RespawnOnStart = 0;
respawnDelay = 5;
respawnVehicleDelay = 5;
disabledAI = 1;
respawnDialog = 1;
respawn = 3;
ticketWEST = 10;
respawnTemplates[] = {"MenuPosition","Tickets"};
```

> **À personnaliser :** la ligne `enableDebugConsole[] = {"…"};` contient l'identifiant Steam de l'auteur. Remplace-le par le tien (ou par une liste d'UID).

---

## 3. Préparer l'éditeur

Dans ton `mission.sqm`, pose et **nomme** (champ « Nom de variable ») ce que tu déclareras ensuite dans [Configuration](Configuration) :

- [ ] Les **slots joueurs**, en camp **BLUFOR**. Le point de réapparition automatique est créé pour BLUFOR.
- [ ] Les **objets** utilisés : arsenal, lieu de soins, poste de communication, garage, demandeur d'appui…
- [ ] Un **marqueur** posé sur ta base, dont le nom correspond à `hdsnombase` (par défaut `hds-ros-base`).
- [ ] Les éléments de ton scénario : otages, cibles, déclencheurs (voir [Écrire son scénario](Ecrire-son-scenario)).

Tu peux ensuite passer à la [Configuration](Configuration).
