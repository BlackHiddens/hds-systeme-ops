# Dépannage

## D'abord : active le mode debug

Dans `mes-parametres.sqf` :

```sqf
hdssysteme = true;
```

hds-ops annonce alors dans le chat système chaque étape de la génération de missions (« Création de la mission en cours », « Joueurs détectés », « Faction aléatoire sélectionnée », etc.). Les messages sont préfixés par `hdsversion`.

---

## Problèmes fréquents

| Symptôme | Cause probable | Solution |
|---|---|---|
| Erreurs au démarrage du serveur | ACE3 ou CBA_A3 absent | Charge les deux addons (voir [la page d'accueil](Home)) |
| Une mission d'otages aléatoire ne se termine jamais | Aucun marqueur ne porte le nom de `hdsnombase` : l'otage ne peut pas être « ramené à la base » | Pose dans l'éditeur un marqueur nommé comme `hdsnombase` (par défaut `hds-ros-base`) sur ta base |
| Un `waituntil {tache_scenario > 1}` ne se déclenche jamais | Avec une seule tâche, `tache_scenario` vaut 1 | Utilise `> 0` ou `>= 1`. Voir [la page d'accueil](Home) |
| `fnc_hds_missions` ne crée aucun objectif ou génère une erreur | Le 8e paramètre (nombre de tâches) manque | Ajoute-le : 8 paramètres sont obligatoires ([Référence](Reference-des-fonctions#fnc_hds_missions)) |
| Un slot n'a pas ses capacités (médecin, menu de renfort…) | Le nom du slot ne correspond pas au nom de variable de l'éditeur, ou il est écrit sans guillemets | Slots : noms **entre guillemets**, casse exacte (voir [Options avancées](Options-avancees#les-slots-joueurs)) |
| Un objet (arsenal, lieu de soins…) ne fonctionne pas | Son nom a été mis entre guillemets, ou n'existe pas dans l'éditeur | Objets : noms **sans guillemets** |
| Les appuis d'un rôle ne fonctionnent pas | Faute dans le nom de la variable | Le nom correct est `sontdesappuisexpertcoms` (et non « exoertcoms ») |
| La faction demandée apparaît en CSAT | L'addon de cette faction n'est pas chargé | Voir le tableau des [Factions](Factions) |
| La faction 7 ou le tirage aléatoire ne donne pas ce que j'attends | La faction 7 n'est pas dans le tirage aléatoire ; la faction 2 est alliée | Demande la faction explicitement |
| Pas de console de debug en jeu | `enableDebugConsole` contient l'UID de l'auteur | Remplace-le par le tien dans `description.ext` |
| Les joueurs n'ont pas de point de réapparition | Les slots ne sont pas BLUFOR | Passe les slots joueurs en BLUFOR (le point est créé pour `west`) |

---

## Limites connues

Fonctions présentes dans le dépôt mais non finalisées ou non branchées :

- `fnc_hds_populace` appelle `fnc_hds_populations`, qui n'existe pas dans le dépôt. Ne l'utilise pas.
- Le script d'IED sur route (`ops-iedsurroute(a finir).sqf`) est inachevé et n'est déclaré nulle part.
- Le module `commandant` n'est appelé par aucun autre fichier (voir [Architecture](Architecture#le-module-commandant)).
- Les paramètres `visible` de `fnc_hds_occupations` et `cibleMarqueur` de `fnc_tactique_contreattaque` ne sont pas utilisés par le code actuel.

---

## Aide

Une question ? Pose-la sur le dépôt du projet (issues) en précisant le contenu de ton `init-scenario.sqf` et les messages du mode debug.
