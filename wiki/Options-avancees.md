# Options avancées

> **Cette page est facultative.** Pour ta première mission, tout est sur la [page d'accueil](Home).
> Elle sert quand tu veux régler plus finement ce que reçoivent tes joueurs, la boutique ou les appuis. Toutes les variables se trouvent dans `mes-parametres.sqf`.

## Sommaire

- [Les slots joueurs](#les-slots-joueurs)
- [Les appuis](#les-appuis)
- [Les objets spéciaux](#les-objets-spéciaux)
- [La boutique et les options](#la-boutique-et-les-options)
- [Administrateurs et console de debug](#administrateurs-et-console-de-debug)

---

## Les slots joueurs

Chaque joueur reçoit ce qui va avec son rôle, selon la liste où tu l'as rangé. Tous les joueurs reçoivent aussi le menu **« exécuter la caméra »**.

| Liste | Rôle | Ce que le joueur reçoit |
|---|---|---|
| `sontdesmanageurs` | Chefs | Pose d'attelle, menu **appeler des mercenaires**, compétences ingénieur et médecin |
| `sontdesexpertcoms` | Opérateurs radio | Menu **appeler des mercenaires** |
| `sontdesmedecins` | Médecins | Pose d'attelle, compétence médecin |
| `sontdesingenieurs` | Mécaniciens | Compétences ingénieur et explosifs (peuvent réparer les véhicules) |
| `sontdespilotes` | Pilotes | Compétence ingénieur, action **créer un équipage** |
| `sontdescontractor` | Mercenaires | Pose d'attelle, menu **appeler des mercenaires** |

**Appeler des mercenaires :** le joueur clique sur la carte et un groupe de 8 soldats se met en route. Le nombre d'appels possibles se règle avec la ligne `fnc_renfort_init` de `init-scenario.sqf` (le premier chiffre).

> **Rappel :** les joueurs s'écrivent **entre guillemets** (`"chef_one"`), et ils doivent porter exactement le même nom que dans l'éditeur, majuscules comprises.

---

## Les appuis

Un **appui** est un objet de l'éditeur (par exemple un module de demande d'appui) relié aux joueurs d'un rôle. Ces joueurs peuvent alors le solliciter.

```sqf
sontdesappuismanageurs  = [radio_appui];
sontdesappuisexpertcoms = [radio_appui];
sontdesappuismedicals   = [radio_appui];
sontdesappuisingenieurs = [radio_appui];
sontdesappuiscontractor = [radio_appui];
```

- Pour **donner** l'appui à un rôle : mets le nom de ton objet entre les crochets.
- Pour le **retirer** : `sontdesappuismedicals = [];`
- Les objets s'écrivent **sans guillemets**.

> Fais attention à l'orthographe : c'est bien `sontdesappuisexpertcoms`. Une faute de frappe crée une variable que le script n'utilise jamais, sans message d'erreur.
>
> Les pilotes n'ont pas d'appui : la variable `sontdesappuispilotes` existe, mais le script ne l'utilise pas.

---

## Les objets spéciaux

Ces variables sont **sans guillemets**, comme tous les objets.

| Variable | Contenu | Rôle |
|---|---|---|
| `sontdeslieudesoin` | liste d'objets | Lieux de soins (ACE3) |
| `lelieuestunvehicule` | `true` ou `false` | `true` : les lieux de soins sont des véhicules |
| `sontdesarsenales` | liste d'objets | Y ajoute un arsenal |
| `sontdespostesdecommunications` | liste d'objets | Terminaux qui donnent des ressources aux joueurs |
| `estungarage` | `[objet, position]` | Terminal du garage virtuel, et lieu où apparaissent les véhicules achetés |
| `estunravitaillement` | `[position, rayon]` | Zone où les véhicules sont ravitaillés |

---

## La boutique et les options

| Variable | Défaut | Rôle |
|---|:-:|---|
| `boutiqueactive` | `false` | Mode argent : chaque tâche rapporte une somme, gardée dans le profil du joueur |
| `modehardactive` | `false` | Mode « hard » (élimination d'équipement) |
| `sauvegarderlesequipements` | `false` | Sauvegarde et recharge l'équipement des joueurs sur le serveur |
| `hdssysteme` | `false` | Mode debug : le script annonce chaque étape dans le chat |

La somme versée par tâche est le 2e chiffre de la ligne `fnc_scenario_init` dans `init-scenario.sqf`.

### Les prix

Le tableau `prix` donne le prix de chaque catégorie, dans cet ordre :

| Position | Catégorie |
|:-:|---|
| 1 | Arme principale |
| 2 | Arme secondaire |
| 3 | Pistolet |
| 4 | Chargeur |
| 5 | Sac à dos |
| 6 | Accessoire d'arme principale |
| 7 | Accessoire de pistolet |
| 8 | Objet |
| 9 | Lunettes ou bandana |
| 10 | Vision nocturne |
| 11 | Gilet |
| 12 | Chapeaux et casques |

---

## Administrateurs et console de debug

Dans `mes-parametres.sqf`, `hds_administrateurs` est la liste des identifiants Steam des administrateurs du serveur :

```sqf
hds_administrateurs = [
"76561198000000000", //Pseudo 1
"76561198000000001"  //Pseudo 2
];
```

Dans `description.ext`, la ligne `enableDebugConsole[] = {"…"};` contient l'identifiant Steam de l'auteur du script. **Remplace-le par le tien** si tu veux la console de debug en jeu.
