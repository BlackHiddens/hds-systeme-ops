# Hiddens Système Opérations (hds-ops)

**hds-ops crée tes missions Arma 3 à ta place.** Tu choisis où ça se passe. Il place les ennemis, les civils, les objectifs et les renforts. Toi, tu t'occupes de l'ambiance.

Il règle aussi les petits détails qu'on oublie : les IA des slots sont désactivées, le point de réapparition se crée tout seul, les addons sont détectés automatiquement.

> **Tu débutes ?** Suis les 3 étapes ci-dessous, dans l'ordre. Compte 15 minutes. Tu n'as rien d'autre à lire.

---

## Avant de commencer

Il te faut :

- **Arma 3** avec les mods **ACE3** et **CBA_A3**
- **une mission** : un dossier qui contient un `mission.sqm`, sur la carte de ton choix
- *(facultatif)* **RHS** ou **Project OPFOR**, pour avoir plus de factions ennemies

---

## 1. Installer

**a. Copie les fichiers.**
Sur la page du dépôt, clique sur **Code**, puis **Download ZIP**. Copie tout le contenu dans le dossier de ta mission, là où se trouve `mission.sqm`.

<details>
<summary>Ma mission avait déjà des fichiers du même nom (initserver.sqf, description.ext…)</summary>

N'écrase pas les tiens. Ouvre-les et ajoute-y ces lignes.

**`initserver.sqf`**

```sqf
#include "mes-parametres.sqf"
#include "virtualgarage\virtualgarage.sqf"
#include "hdssystem\init-serveur.sqf"
#include "hdssystem\modules\occupations\h-init.sqf"
#include "hdssystem\modules\tactiques\h-init.sqf"
#include "hdssystem\modules\missions\h-init.sqf"
#include "hdssystem\modules\scenario\h-init.sqf"
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

**`description.ext`** : copie dedans les blocs `#include "gcam\gcam_component.hpp"`, `CfgFunctions` et `CfgCommunicationMenu` du fichier `description.ext` du dépôt.

</details>

**b. Prépare ta mission dans l'éditeur.** Trois choses, deux minutes :

1. Mets tes slots joueurs dans le camp **BLUFOR**.
2. Pose un **marqueur** sur ta base et appelle-le `hds-ros-base`.
3. *(facultatif)* Donne un nom aux joueurs et aux objets que le script doit configurer. Double-clique dessus et remplis le champ *Nom de variable*. Par exemple `chef_one` pour un chef d'équipe, ou `arsenal_console` pour une caisse d'arsenal.

---

## 2. Dire au script qui est qui

Ouvre le fichier `mes-parametres.sqf`, à la racine de ta mission. Cherche ce bloc et remplace les noms par ceux que tu as donnés dans l'éditeur :

```sqf
hdsnombase = ["hds-ros-base"];                 // le marqueur de ta base

sontdesarsenales  = [arsenal_console];         // tes caisses d'arsenal
sontdeslieudesoin = [soins];                   // tes lieux de soins

sontdesmanageurs  = ["chef_one","chef_two"];   // les chefs d'équipe
sontdesexpertcoms = ["communication_one"];     // les opérateurs radio
sontdesmedecins   = ["medecin_one"];           // les médecins
sontdesingenieurs = ["mecano_one"];            // les mécaniciens
sontdespilotes    = ["pilote_one"];            // les pilotes
sontdescontractor = ["contractor_1"];          // les mercenaires
```

> **Une seule règle à retenir.**
> Un **joueur** s'écrit **entre guillemets** : `"chef_one"`.
> Un **objet** s'écrit **sans guillemets** : `arsenal_console`.

Le reste du fichier, laisse-le tel quel. Chaque joueur reçoit tout seul ce qui va avec son rôle (un médecin soigne, un pilote crée son équipage…). Le détail est dans [Options avancées](Options-avancees#les-slots-joueurs).

---

## 3. Lancer ta mission

Bonne nouvelle : **tu n'as rien à écrire pour une première partie.**

Le fichier `hdssystem\init-scenario.sqf` contient déjà une mission qui marche. Elle enchaîne 5 missions automatiques, avec des ennemis, des civils et des objectifs tirés au hasard.

Lance ta mission comme d'habitude (aperçu multijoueur de l'éditeur, ou ton serveur). C'est tout.

### Changer la mission automatique

Tu veux plus de missions, plus difficiles, ou d'autres types de lieux ? Tout se règle sur une seule ligne.

<details>
<summary>Voir les réglages, chiffre par chiffre</summary>

Dans `init-scenario.sqf`, repère la ligne `fnc_hds_missions`. Chaque chiffre a un rôle :

```sqf
[ 500,    // taille de chaque mission, en mètres
  6,      // l'ennemi (sans effet ici, car "ennemi au hasard" est à true plus bas)
  5,      // nombre de missions à la suite
  3,      // difficulté : plus le chiffre est grand, plus c'est dur
  ["NameVillage","NameCity","NameLocal","Name"],   // où ça se passe
  true,   // des civils sont présents
  true,   // l'ennemi est tiré au hasard
  3       // nombre d'objectifs dans chaque mission
] spawn fnc_hds_missions;
```

- **Les lieux possibles :** `"NameVillage"` village, `"NameCity"` ville, `"NameLocal"` endroit particulier, `"Name"` endroit commun, `"Strategic"` base militaire.
- **Pour choisir l'ennemi toi-même :** mets `false` à l'avant-dernière ligne, et le numéro de la faction à la 2e ligne. Les numéros sont dans [Factions](Factions).

</details>

### Écrire ta propre histoire

Tu préfères une mission écrite à la main, étape par étape ?

<details>
<summary>Voir un exemple : libérer 2 otages, puis l'ennemi contre-attaque</summary>

Supprime la ligne `fnc_hds_missions` et écris tes étapes à la place. Garde les lignes du haut du fichier. Pose d'abord 2 otages dans l'éditeur et appelle-les `otage_0` et `otage_1`.

```sqf
// 1. Les ennemis surveillent la zone : de 3 à 5 surprises
[[4506.92,5729.59,0], 500, 6, 3, 5] spawn fnc_tactique_plannification;

// 2. La zone est occupée par des ennemis
[[4506.92,5729.59,0], 1, 6, 500, false] spawn fnc_hds_occupations;

// 3. La mission : libérer les otages
[
  [4506.92,5729.59,0],                         // où se passe la mission
  [4847.85,4598.72,0],                         // où ramener les otages
  [otage_0,otage_1],                           // les otages de l'éditeur
  "Pilotes de l'IDAP",                         // leur nom
  "Trouver et libérer les pilotes de l'IDAP",  // la consigne affichée
  50,                                          // taille de la zone
  false                                        // zone cachée sur la carte
] spawn fnc_scenario_otage;

// 4. On attend que la mission soit terminée
waituntil {tache_scenario > 0};

// 5. L'ennemi contre-attaque (mets les coordonnées de ta base)
[[4502.1,5681.85,0], 2, 5, 700, 6, false] spawn fnc_tactique_contreattaque;
```

- Les coordonnées `[x,y,z]` se relèvent dans l'éditeur.
- Le `6` est la faction : la milice afghane, qui demande le mod Project OPFOR. Sans lui, tu auras du CSAT. Les autres numéros sont dans [Factions](Factions).
- `tache_scenario` compte les missions terminées. Avec une seule mission, écris `> 0` : un `> 1` n'arriverait jamais.

</details>

---

## Ça ne marche pas ?

1. Dans `mes-parametres.sqf`, passe `hdssysteme = true;`. Le script annonce alors chaque étape dans le chat.
2. Regarde la page [Dépannage](Depannage).

---

## Pour aller plus loin

Tu n'as pas besoin de ces pages pour commencer.

| Page | Quand la lire |
|---|---|
| [Options avancées](Options-avancees) | Tu veux régler les rôles, la boutique, les appuis |
| [Référence des fonctions](Reference-des-fonctions) | Tu veux écrire un scénario plus poussé |
| [Factions](Factions) | Tu veux choisir l'ennemi |
| [Dépannage](Depannage) | Quelque chose ne marche pas |
| [Architecture](Architecture) | Tu veux modifier le script lui-même |

*Au cœur du script, 4 modules travaillent ensemble : **hds-occupations** (peuple une zone), **hds-tactiques** (commande les troupes IA), **hds-missions** (crée les missions automatiques) et **hds-scenario** (tes missions écrites à la main).*
