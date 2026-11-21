# Archive HDS — ce que la mission ne charge pas

104 fichiers : 74 fichiers de script, plus 30 exports Arsenal en `.txt`.

Rien ici n'est exécuté. Ces fichiers étaient mélangés au code vivant, ce qui
coûtait à chaque recherche : c'est ce tas qui a fait annoncer deux fausses
pistes, et c'est aussi là que dormaient deux fonctions que le générateur web
appelait sans qu'elles existent nulle part.

**Rien n'a été supprimé.** L'arborescence d'origine est reproduite telle quelle
sous `_archive`, donc remettre un fichier en service, c'est le remonter d'un
cran : `_archive/modules/occupations/h-civils.sqf` retourne en
`modules/occupations/h-civils.sqf`. Rien de ce qui tourne n'a été modifié pour
faire ce rangement.

## Comment cette liste a été établie

Un parcours d'atteignabilité depuis les seuls points d'entrée que le moteur
Arma lit de lui-même — `description.ext`, `mission.sqm`, `initserver.sqf`,
`initplayerlocal.sqf`, `onplayerrespawn.sqf`, `mes-parametres.sqf` — en suivant
tous les `#include`, `preprocessFile`, `preprocessFileLineNumbers` et `execVM`
de proche en proche. Sur 171 fichiers scriptables : **97 chargés, 74 jamais
atteints.** Ce sont ces 74.

La règle est mécanique, et c'est voulu : aucun jugement sur l'utilité d'une
fonctionnalité n'est entré dans le tri.

## Ce qu'il y a, par groupe

### `fonctions/fonctions/` — 30 fichiers
Le placard dormant. Deux fichiers en sont sortis et tournent aujourd'hui :
`ops-missions.sqf` est devenu `fonctions/missions-aleatoires.sqf`
(`fnc_hds_missions`) et `ops-presence-hostile.sqf` est devenu
`fonctions/presence-hostile.sqf` (`fnc_hds_presence_hostile`).

C'est donc le groupe à regarder avant les autres : il reste des corps
récupérables, notamment `demandebombardement.sqf`, `garages.sqf`,
`garnirhabitations.sqf`, `ops-conteste.sqf`, `ops-populace.sqf`,
`ops-rearmement.sqf`, `sauteenparachute.sqf`, `poseattelle.sqf`,
`introscenario.sqf` et `finscenario.sqf`.

Deux réserves pour la suite :

- `ajouteraction.sqf`, `arsenaux.sqf`, `lieumedical.sqf` et
  `postedecommunication.sqf` sont d'anciennes copies de fichiers qui vivent
  maintenant dans `hdssystem/fonctions/`. Ce sont les versions du dossier
  parent qui font foi, pas celles-ci.
- `ops-utilisateurdegcam.sqf` appelle `gcam\gcam.sqf`, qui n'existe pas dans ce
  dépôt. GCam est une caméra de debug tierce.

### `modules/occupations/h-factions/` — 28 fichiers
Les listes de classnames, une par faction et par rôle, qui servaient aux
occupations. Remplacées par le registre (`modules/factions/`), construit au
démarrage depuis la config réelle du serveur : plus aucun classname de faction
en dur, et une faction absente retombe sur une autre du même camp au lieu de ne
rien produire. Ces fichiers n'ont plus de rôle, et les reprendre ferait revenir
le problème qu'ils posaient.

### `modules/commandant/` — 4 fichiers
Le projet commandant-IA, mis de côté. Gardé tel quel.

### `init-client.sqf`, `init-reapparition.sqf`, `init-serveur.sqf` — 3 fichiers
D'anciens points d'entrée que rien n'appelle. Ils définissaient 46 variables
`hds_txt_*` par `localize`, sur un `stringtable.xml` qui n'existe pas dans cette
mission : les appels étaient donc vides même s'ils avaient tourné. Les 12
libellés réellement lus sont maintenant écrits en clair dans
`mes-parametres.sqf`. Les 34 autres n'existent que dans ces fichiers.

### `modules/missions/objectif_recherche_objet.sqf`, `objectif_tactique.sqf` — 2 fichiers
Deux corps d'objectif jamais assignés à un nom de fonction.

`objectif_tactique.sqf` demande du travail avant d'être utilisable, pas
seulement un câblage : il appelle `fnc_hds_occupations` avec une densité de 0
(qui ne fait donc rien apparaître) et un rayon de 30 m, et son paramètre 0 est
utilisé à la fois comme une position (ligne 5) et comme un nom de marqueur
(ligne 10).

### `modules/occupations/h-civils.sqf` — 1 fichier
L'ancien répartiteur de civils, qui appelait `fnc_Americaingarnison`,
`fnc_Arabespietons` et compagnie — les fonctions du groupe `h-factions`
ci-dessus. Remplacé par `fnc_occupations_civil_init`, qui prend ses classes dans
le registre.

### `modules/occupations/h-fncsysteme/h-GarnisonArmee.sqf`, `h-GarnisonRebelle.sqf` — 2 fichiers
Deux anciennes variantes de garnison. Remplacées par `hds_fnc_garnison`
(`compat/h-compat.sqf`), qui place les hommes dans les bâtiments **puis** les
anime — l'ordre inverse figeait tout le monde dehors.

### `modules/occupations/h-interfaces/` + `recruepersocustom.sqf` — 4 fichiers
Les dialogues des terminaux de recrutement. **Ce groupe-là est le seul à
demander de l'attention**, parce que c'est une fonctionnalité en option, pas un
reste :

- `fenetre_recrueperso.hpp` définit la classe `hds_recrutement`,
  `fenetre_recrutementpersocustom.hpp` définit `hds_recrutementperso`, et
  `defines.hpp` porte leurs contrôles de base.
- `modules/occupations/h-groupeia.sqf` et `h-groupeiaperso.sqf` sont toujours en
  service — compilés par `modules/occupations/h-init.sqf` — et appellent
  `createDialog "hds_recrutement"` et `createDialog "hds_recrutementperso"`.
- Mais `description.ext` n'inclut aucun de ces `.hpp`, et les trois lignes qui
  posent les actions sur un terminal sont en commentaire à la fin de
  `modules/occupations/h-init.sqf`. La fonctionnalité était donc déjà
  inatteignable avant ce rangement, dans les deux sens : pas de dialogue, et
  personne pour l'ouvrir.

Pour la remettre en route il faut les deux moitiés : ajouter
`#include "hdssystem\modules\occupations\h-interfaces\fenetre_recrueperso.hpp"`
(et l'autre) à `description.ext` après avoir remonté le dossier, puis décommenter
les lignes `TerminalDeGroupeIA...` de `h-init.sqf`.

### `modules/occupations/h-renfortallie/h-rosequipes/` — 30 fichiers `.txt`
Des compositions d'équipe exportées depuis l'Arsenal, rangées par tenue
(Desert, Tiger, Urban) et par rôle (équipage, pilotes, soutien, spéciale).

Ce ne sont pas des scripts : rien ne les lit, et rien ne les a jamais lus ici.
Elles accompagnaient 24 fichiers de roster `.sqf` qui ont été supprimés quand les
renforts alliés sont passés à `fnc_hds_equiperCommeJoueurs`, qui copie
l'équipement des joueurs présents au lieu de piocher dans des listes écrites à
la main. Gardées comme matière de référence : un export Arsenal se recolle dans
l'Arsenal en jeu, c'est de la donnée réutilisable à la main.

## Si tu veux vraiment supprimer

Une fois que la mission a tourné et que tu es sûr de ton coup, le dossier
`hdssystem/_archive/` entier peut partir. Il n'y a pas de dépôt git ici, donc
cette suppression-là est définitive : c'est la raison pour laquelle ce rangement
déplace au lieu d'effacer.
