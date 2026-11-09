# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projet

Mission Arma 3 en SQF (`hds-systeme-ops`, aussi nommé `ai_hds_systeme` dans `me-lire.txt`) : framework d'aide à la création de missions (occupations IA, objectifs aléatoires, tactiques IA, renforts, arsenaux, garage, économie). Code et commentaires en français. Le dépôt ne contient ni build, ni lint, ni tests : tout se valide en lançant la mission dans Arma 3. Pas de runtime Arma ici, donc relire à la main (accolades, `;`, guillemets) et ne jamais affirmer qu'un script « fonctionne » sans test en jeu.

## Chaîne d'initialisation (à comprendre avant de modifier)

`initserver.sqf` et `initplayerlocal.sqf` utilisent `#include` (pas `execVM`) : tout partage le même scope, et `mes-parametres.sqf` est inclus des deux côtés (serveur ET client).
- Serveur : `mes-parametres.sqf` → `virtualgarage/` → `hdssystem/init-serveur.sqf` (relations entre camps, respawn auto, curator Zeus, textes) → `h-init.sqf` de chaque module → `hdssystem/init-scenario.sqf` (lance trafic, renforts, `fnc_scenario_init`, `fnc_hds_missions`). C'est ce dernier fichier qui définit le scénario réellement joué.
- Client : `mes-parametres.sqf` → `hdssystem/init-client.sqf` → `modules/occupations/h-init.sqf`. `onplayerrespawn.sqf` → `init-reapparition.sqf`.

## Convention des fonctions

Les fonctions sont des globales `fnc_*` compilées par `compile preprocessFile "chemin\fichier.sqf"` (chemins Windows, relatifs à la racine de la mission) :
- `fnc_hds_*` (arsenaux, garage, médical, ravitaillement…) dans `mes-parametres.sqf` ;
- `fnc_objectif_*`, `fnc_tactique_*`, `fnc_scenario_*`, `fnc_hds_occupations`, `fnc_renfort_*` dans le `h-init.sqf` de leur module ;
- exception : `modules/commandant` passe par `CfgFunctions` (`description.ext` ← `commandant/init.hpp`, tag `aihds`, fichiers `fn_*.sqf`).

**Ajouter une fonction = créer le `.sqf` ET ajouter sa ligne `compile` dans le bon `h-init.sqf` / `mes-parametres.sqf`.** La casse des chemins est incohérente (ex. `h-init.sqf` cite `objectif_cachearmes.sqf`, le fichier est `objectif_cacheArmes.sqf`) : ne renomme rien sans vérifier toutes les références.

## Modules (`hdssystem/modules/`)

- `occupations` : populations, garnisons, patrouilles par faction (`h-factions/`), renforts alliés et rosters d'équipes (`h-renfortallie/h-rosequipes/` : assaut/soutien/equipage/pilotes/speciale × desert/tiger/urbain), UI de recrutement (`h-interfaces/*.hpp`).
- `missions` : objectifs (`objectif_*.sqf`, `objectif_aleatoire.sqf`). `scenario` : scénarios scriptés (Otage, Collecter, Detruire…), entrée `fnc_scenario_init`.
- `tactiques` : IA tactique (`les_tactiques/`, `les_missions/`, `les_mises_en_places/`), pilotée par `init-evenements.sqf` et `init-plannification.sqf`.
- `commandant` : cerveau IA et installation de bases.

## Configuration et addons

- `mes-parametres.sqf` est la config utilisateur : noms d'objets/unités posés dans l'éditeur (`sontdesarsenales`, `sontdeslieudesoin`, `sontdesmanageurs`…), interrupteurs (`boutiqueactive`, `modehardactive`, `sauvegarderlesequipements`, `hdssysteme` = debug verbeux), `hds_administrateurs` (UID Steam).
- Les addons sont détectés via `CfgPatches` en booléens (`aceestactive`, `afrfactive`, `usafactive`, `opforactive`, `numbactive`…) : toute classe/fonction d'addon optionnel doit rester derrière ces gardes. ACE3 et CBA sont appelés sans garde dans `init-serveur.sqf`.
- Textes affichés : clé `str_hds_*` dans `stringtable.xml` + `localize`, stockée dans une globale `hds_txt_*` (déclarée dans `init-serveur.sqf` et `init-client.sqf`). À privilégier pour tout nouveau texte joueur.
- `me-lire.txt` est en partie désynchronisé du code (ex. `sontdeslieuxdesoin` vs `sontdeslieudesoin`) : le code fait foi.

## Ne pas lire ni modifier sans demande explicite

- Code tiers : `gcam/` (caméra, ~3 800 lignes dans `gcam.sqf`), `engima/Traffic/` (trafic civil), `virtualgarage/`.
- `hdssystem/fonctions/ops-iedsurroute(a finir).sqf` : inachevé ; ses parenthèses et espaces cassent les commandes shell non quotées (`xargs`, `wc`…), toujours quoter le chemin.
- Fichiers média (`.paa`, `.ogg`, `.jpg`, `.wav`).
