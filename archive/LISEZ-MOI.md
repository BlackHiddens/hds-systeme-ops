# Archive — tentatives mises de côté

## commandant-ia.zip

Une tentative de laisser une IA piloter la **stratégie macro** des forces
ennemies : pas le comportement d'un groupe au contact, mais les décisions
d'ensemble — où renforcer, quoi défendre, quand décrocher — en fonction de
ce qui se passait réellement sur le terrain.

La chaîne était :

```
SQF écrit dans le RPT   [HDS][OPFOR_POS], [HDS_CONTACT], [HDS_PERTES]
      ↓
bridge Python           lit le RPT, appelle l'API Claude
      ↓
hds_ordres.sqf          écrit par le pont
      ↓
executeur.sqf           relu toutes les 5 s côté mission
```

Le zip contient :

- `bridge/` — le pont Python (`main.py`, `web.py`, config et directives) ;
- `hdssystem-modules-commandant/` — le module SQF correspondant
  (`fn_cerveau.sqf`, `fn_definirunebase.sqf`, `fn_installerunebase.sqf`,
  `init.hpp`).

**Pourquoi c'est abandonné :** ça ne fonctionnait pas assez bien. Le
principe tient, l'exécution non — les ordres arrivaient trop tard pour la
situation qu'ils visaient, et le détour par le fichier RPT rendait la
boucle fragile.

Rien dans la mission ne l'appelle plus. Le module était déjà sorti du
chemin de chargement avant d'être archivé ici.

**Pour y revenir :** décompresser le zip, ou récupérer les fichiers tels
quels dans l'historique git — ils y sont en clair, au commit qui précède
leur archivage.
