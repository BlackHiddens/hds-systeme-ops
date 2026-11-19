# Contexte pour la session locale (hds-ops)

À lire en entier avant de toucher à quoi que ce soit.

## Le projet

**hds-ops** (dépôt `hds-systeme-ops`) est un framework de missions Arma 3 écrit en SQF, par Hiddens (l'utilisateur).

- Dépôt : https://github.com/BlackHiddens/hds-systeme-ops
- Branche de travail : `claude/charming-meitner-v1st8z`. Elle contient `CLAUDE.md` (architecture) et `wiki/` (documentation).
- Le dépôt est un **dossier de mission squelette** : sa racine est une racine de mission, mais sans `mission.sqm`.

## L'environnement

- Mission de l'utilisateur : `C:\Users\peron\Documents\Arma 3 - Other Profiles\Hiddens\mpmissions\NewHDS.Stratis` (carte Stratis, 4 personnages jouables pour l'instant). C'est le dossier de travail de cette session.
- Le script n'y est **pas encore installé**.

## Étape 0 : installer le script, sans rien écraser

1. **Sauvegarde** d'abord le dossier de mission (copie datée à côté).
2. Clone le dépôt dans un dossier temporaire **hors de la mission**, puis passe sur la branche `claude/charming-meitner-v1st8z`.
3. Copie dans la mission : `hdssystem\`, `engima\`, `gcam\`, `virtualgarage\`, `conversations\`, `mes-parametres.sqf`, `stringtable.xml`, `texts.bikb`.
4. **Fusionne** (ne remplace pas) `description.ext`, `initserver.sqf`, `initplayerlocal.sqf` et `onplayerrespawn.sqf` avec ceux de la mission s'ils existent. Les lignes à garder sont décrites dans `wiki/Home.md`, section « Ma mission avait déjà des fichiers du même nom ».
5. Ne modifie **jamais** `mission.sqm` sans accord. Lis-le : slots joueurs (noms de variable, camp), marqueurs, objets, et la liste des mods (`addOns`, `addOnsAuto`).
6. Renseigne `mes-parametres.sqf` d'après ce que tu as lu : les joueurs s'écrivent **entre guillemets** (`"chef_one"`), les objets **sans guillemets**. Les slots doivent être BLUFOR. Pose un marqueur `hds-ros-base` sur la base.
7. Rapporte à l'utilisateur ce que tu as trouvé dans `mission.sqm` **avant** de continuer.

## Objectifs, dans l'ordre

### 1. Prérequis réduits à CBA seul (option : aucun mod)

Constat (recherche rapide, à vérifier) :

- **ACE** est cité dans une quarantaine de fichiers. La plupart ne sont que des listes d'objets médicaux ACE (`ACE_tourniquet`, `ACE_morphine`…) dans `hdssystem\modules\occupations\h-renfortallie\h-rosequipes\**` et `hdssystem\fonctions\arsenaux\**`.
- Les vrais appels de fonctions ACE sont peu nombreux :
  - `ace_arsenal_fnc_initBox` (`arsenaux.sqf`, `arsenaux\complet.sqf`) ;
  - `ace_medical_treatment_fnc_fullHeal` (`lieumedical.sqf`) ;
  - `ace_ai_fnc_garrison` (`hds_occupations_civil_init.sqf`) ;
  - `ace_modules_fnc_moduleInit` (`init-serveur.sqf`, module Zeus) ;
  - `ace_hearing_disableVolumeUpdate` (`introscenario.sqf`) ;
  - la variable `ace_medical_medicClass` (`init-client.sqf`, `init-reapparition.sqf`).
- **CBA** n'est utilisé qu'à 11 endroits : `CBA_fnc_taskDefend`, `CBA_fnc_taskPatrol`, `cba_fnc_createmarker`. Le jeu de base a des équivalents (`BIS_fnc_taskDefend`, `BIS_fnc_taskPatrol`, `createMarker`).

Piste proposée : une petite couche de compatibilité qui, quand ACE est absent, utilise un équivalent vanilla (arsenal `BIS_fnc_arsenal`, soin simple, trousse de soins à la place des objets ACE, module Zeus sans appel ACE, garnison via `CBA_fnc_taskDefend`). ACE resterait utilisable s'il est présent.

### 2. Détection automatique des factions installées

- Aujourd'hui : 8 tests `CfgPatches` dans `mes-parametres.sqf` (`aceestactive`, `opforactive`, `afrfactive`, `usafactive`, `foxforactive`, `cosactive`, `rdsactive`, `numbactive`), et des `case` écrits en dur pour les factions 0 à 7 dans `hdssystem\modules\occupations\h-occupation.sqf` et dans les 4 fichiers de `hdssystem\modules\tactiques\les_tactiques\`.
- Les équipes `h-rosequipes` utilisent des classes **RHS USAF écrites en dur** (par exemple `rhsusf_weap_m9`) : sans RHS, elles seraient cassées.
- Piste proposée : lire la config du jeu au démarrage du serveur (`CfgFactionClasses`, `CfgGroups`, `CfgVehicles`) pour bâtir un **registre de factions** (identifiant, nom, camp, groupes d'infanterie, véhicules, hélicoptères armés, addon requis). Les identifiants 0 à 7 restent ceux des factions actuelles. Les profils soignés actuels deviennent des cas particuliers, avec un repli automatique pour les factions inconnues.
- Attention : certains mods définissent mal leurs groupes. Prévoir des règles de repli.

### 3. Plateforme web reliée au serveur (plus tard)

- Arma 3 ne sait pas faire de requête web. Il faut une **extension** côté serveur (`callExtension`) qui fait des requêtes HTTPS **sortantes** vers l'API du site.
- Le script doit lire une **liste d'étapes en données** (comme celles du générateur) et **ne jamais exécuter du code reçu du réseau** (pas de `compile` sur du texte venant du web). Vérifier le droit de l'appelant côté serveur.
- Question à poser à l'utilisateur d'abord : où tourne le serveur final, et son hébergeur autorise-t-il les extensions ?
- À réutiliser : le générateur de mission (artefact claude.ai) définit déjà le schéma des 19 types d'étapes : https://claude.ai/artifact/BrrYeF6fkgeWMrUgdY3SXa

## Règles de travail

- L'utilisateur est francophone et préfère le **tutoiement**. Explications **courtes et simples**, sans jargon, jamais de pavé. Il n'aime pas la complexité.
- Ne dis jamais qu'un script SQF « fonctionne » sans l'avoir testé en jeu. Lance la mission (éditeur multijoueur ou serveur local) et lis le fichier **RPT** (dans `%LOCALAPPDATA%\Arma 3\`) pour les erreurs. Demande l'accord avant de lancer le jeu.
- Petites étapes, **un commit par étape**, sur une branche dédiée. Demande avant tout gros changement, toute suppression ou tout renommage.
- Ne modifie pas le code tiers : `gcam\`, `engima\`, `virtualgarage\`.
- Les chemins SQF utilisent des antislashs. La casse des fichiers est parfois incohérente entre les `h-init.sqf` et le disque : ne renomme rien sans vérifier toutes les références.
- Tout se passe dans le dossier de la mission de l'utilisateur. Garde les modifications du dépôt de référence séparées des modifications de la mission.

## Pour comprendre le code

- `CLAUDE.md` : ordre de démarrage (`#include` dans `initserver.sqf` et `initplayerlocal.sqf`), convention des fonctions (`compile preprocessFile` dans les `h-init.sqf` et `mes-parametres.sqf`), modules.
- `wiki/Reference-des-fonctions.md` : signatures de toutes les fonctions, vérifiées contre le code.
- `wiki/Factions.md` : numéros de faction 0 à 7 et addons requis.
