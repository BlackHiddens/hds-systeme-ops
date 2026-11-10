# Le hiddens-système-opération (hds-ops)

Ce projet est un Framework de développement ArmA3. Il permet d’éditer et de développer des missions complexes et scénarisées en un temps record. Grâce à cela, il est possible de se concentrer sur les détails du scénario et non sur la technique et les limites du possible. passez plus de temps sur l'ambiance de mission sera plus simple.

De plus, les éditeurs oublient souvent quelques petits détails, comme celui de paramétrer les fractions ou encore de désactiver les IA des slots. Ce Framwork de paramètre a votre place.

hds-ops fonctionne en synergie avec les sous projet ci-dessous appelé **modules**

### hds-tactique
> Ce module regroupe plusieurs fonctions ayant pour but de commander les troupes d'IA. il déclenche des évènements comment une demande de renfort terrestre ou encore un appui aérien si la faction le permet.

### hds-missions
> Ce module regroupe plusieurs fonctions ayant pour but de gérer la création de mission automatique. en utilisant les autres modules pour le faire, il peux créer une missions de toutes pièce sans avoir besoin d'éditer votre mission.

### hds-occupations
> Ce module regroupe plusieurs fonctions ayant pour but de générer de l'occupation sur zone. Cela va du civil au personnel dangereux. Il travail en synergie avec les autres modules afin d'affiner ses performance et ses possibilités.

### hds-scenario
> Ce module regroupe plusieurs fonctions ayant pour but de vous permettre de créer un scénario très détaillés. il possible aussi l'un des fichiers les plus important. init-scenario.sqf qui sera littéralement votre feuille d'instruction pour créer lé déroulement de votre scénario ou et opération.

***

# Où commencer ?

> Par l'installation !

Afin d'installer le script, vous devez déposer le contenu du dossier **hds-ops** à la racine du dossier de votre mission. Les mods **ACE3** et **CBA_A3** sont nécessaires. Voilà le script est prêt à interagir avec votre mission.

# Interagir comment ?

> En modifiant les paramètres et en adaptant de description à votre scénario.

**hds-ops** doit être avant toute chose configuré selon la mission que vous préparez.
Cela se fera via le fichier **mes-parametres.sqf** qui se situe à la racine du dossier de votre mission.
Voici comment se présente le fichier et ce qui vous concerne.

### Le paramétrages de base

```sqf
//Mes outils
hdsversion = "hdss-ops.alpha";   //Version du hds-systeme-opsn
hdsnombase = ["hdss-ros-base"];  //Nom du marqueur posé sur votre base (indispensable pour les missions d'otages)
hdssysteme = false;              //Mode debuggé activé
//Tous mes objets scriptés
lelieuestunvehicule = false;     //Le lieu médical est un véhicule ? sinon c'est un lieu
sontdeslieudesoin = [soins];    //Liste des objets qui sont des lieux de soins
sontdesarsenales = [];          //Liste des objets qui sont des arsenales
sontdespostesdecommunications = []; //liste des objets qui sont des terminal de communications (Il met à disposition des ressources pour les joueurs)
estungarage = [ordinateur,[3018.75,5884.02,0]];//objet pouvant faire aussi de terminal de garage ainsi que la position de spawn des véhicules achetés
//Tous les slots
sontdesmanageurs = ["chef_one","chef_two"];
sontdesexpertcoms = ["communication_one","communication_two"];
sontdesmedecins = ["medecin_one","medecin_two"];
sontdesingenieurs = ["mecano_one","mecano_two"];
sontdespilotes = ["pilote_one","pilote_two"];
sontdescontractor = ["contractor_1","contractor_2","contractor_3","contractor_4"];
//Tous les appuis
sontdesappuismanageurs = [Demandeur_appui];
sontdesappuisexpertcoms = [Demandeur_appui];
sontdesappuismedicals = [];
sontdesappuisingenieurs = [];
sontdesappuispilotes = [];
sontdesappuiscontractor = [];

```
#### Outils

hdsversion : version du scénario (optionnel).
hdsnombase : nom du marqueur que vous posez sur votre base dans l'éditeur. Les missions d'otages en ont besoin : l'otage doit être ramené à moins de 100 m de ce marqueur.
hdssysteme : vrai ou faux pour faire la chasse aux bugs.

#### Objets scripté

Les slots sont automatiquement configurés par le script. En effet, les hds vont paramétrer les slots selon leurs affectations. Cela permettra d'appeler des appuis si nécessaire et paramétré.


1. sontdesmanageurs : Tous les slots de chefs
2. sontdesexpertcoms : Tous les slots d'opérateur radio. Ils pourront avoir des options supplémentaires d'appel de renfort.
3. sontdesmedecins : Tous les slots de médecin.
4. sontdesingenieurs : tous les slots de mécanicien. Ils pourront réparer des véhicules.
5. sontdespilotes : Tous les pilotes. Les pilotes sont généralement livrés à eux même. Afin de rendre les pilotes indépendants. Les pilotes peuvent générer de l'équipage dans leur véhicules. Si le garage virtuel est activé alors vous n'entendrez plus parler de lui durant vos missions immersives.
6. sontdescontractor : Les contracteurs peuvent appeler des renforts terrestres et sont reliés à l'appui que vous aurez installé.

#### Affectation des appuis.

Par défaut, il n'y a que les managers et les opérateurs radio qui peuvent solliciter de l'appui. Mais comme indiqué ci-dessous, tout le monde peut avoir l'option.

```sqf
sontdesappuismanageurs = [radio_appui];
sontdesappuisexpertcoms = [radio_appui];
sontdesappuismedicals = [radio_appui];
sontdesappuisingenieurs = [radio_appui];
sontdesappuispilotes = [radio_appui];
sontdesappuiscontractor = [radio_appui];
```

### Les paramètre de la description du scénario.

> Vous pouvez aussi modifié le fichier description.ext selon vos désirs.

```sqf
author="Hidden's";
OnLoadName = "Hidden's|hds";

RespawnOnStart = 0;
respawnDelay = 5;
respawnVehicleDelay = 5;
disabledAI = 1;
respawnDialog = 1;
respawn = 3;
ticketWEST = 10;
```

## Maintenant, où doit-je écrire mon scénario ?

> dans le fichier init-scenario.sqf qui se trouve dans hdssystem\init-scenario.sqf

Ce fichier est votre journal de bord. C'est lui qui déroulera votre mission.
2 exemples de missions. Un scénario de soirée et une mission public à laisser tourner en semaine.
C'est le seul autre fichier dans lequel vous devriez écrire

**Exemple d'une mission publique.**

Dans ce scénario, 5 missions différentes avec des factions aléatoires selon les modes activés sur le serveur seront proposées aux joueurs. Les civils sont présents sur le secteur et peuvent circuler sur les routes. fnc_scenario_init est à configurer ainsi par défaut inutile de la changer.

```sqf
//initialisation du contexte de mission
[0,0,10] call fnc_scenario_init; //[nombre_tache_scenario,prix_renumeration,pointdevehicule] call fnc_scenario_init;
[3,west] call fnc_renfort_init;  //[nombre_appel_renfort,camps_des_renforts] call fnc_renfort_init
[] spawn fnc_engima_traffic;     //traffic routier civil

//[<entier>:rayon,<entier>:faction,<entier>:nombremissions,<entier>:difficulté,<tableau>:typelocalisation,<booleen>:civil,<booleen>:factionaléatoire,<entier>:nombredetâches] spawn fnc_hds_missions;

[150,1,5,1,["NameVillage","NameLocal"],true,true,1] spawn fnc_hds_missions;

```
**Exemple d'un scénario privé.**

Dans cette mission scénarisée, 3 appels de renfort alliés sont possibles et il y a du trafic civil.
L'objectif est de récupérer 2 otages. Quand ils seront récupérés, l'ennemi attaquera votre base.

La zone sera occupée par des ennemis et le commandant IA planifiera entre 3 et 5 opérations sur une zone de 500 à mettre autour de la mission si c'est une de ses troupes vous décèle. La faction est rebelle.

```sqf
//initialisation du contexte de mission
[0,0,10] call fnc_scenario_init; //[nombre_tache_scenario,prix_renumeration,pointdevehicule] call fnc_scenario_init;
[3,west] call fnc_renfort_init;  //[nombre_appel_renfort,camps_des_renforts] call fnc_renfort_init
[] spawn fnc_engima_traffic;     //traffic routier civil

//-----------------Objectifs et déroulement----------------------
//le hds-tactique surveille la zone et peut créer des évènements inconnu
[[4506.92,5729.59,0],500,6,3,5] spawn fnc_tactique_plannification;
//le hds_occupation génère des ennemi dans la zone
[[4506.92,5729.59,0],1,6,500,false] spawn fnc_hds_occupations;
//Une mission d'extraction de pilote est générée
[[4506.92,5729.59,0],[4847.85,4598.72,0],[otage_0,otage_1],"pilotes de l'IDAP","Trouver et libérer les pilotes de l'IDAP",50,false] spawn fnc_scenario_otage;

//Attendre qu'une mission soit faite
waituntil {tache_scenario > 0};

//une contre attaque ennemi est donnée au coordonnée indiquée
[[4502.1,5681.85,0],2,5,700,6,false] spawn fnc_tactique_contreattaque;

```

> des exemples simples. cela vous permettra de vous concentrer sur l'ambiance de votre mission et non sa mécanique et son déroulement.
Si vous souhaitez plus d'informations, il est possible de poser vos questions
