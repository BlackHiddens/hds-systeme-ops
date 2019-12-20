//Utilise la fonction ace afin de pouvoir garnir la zone avec les unités de votre choix
params ["_Position","_ListeLeader","_Taille","_Teleportation"];
_ListeUnites = []; //_ListeUnites est un tableau
//Ajoute les unites appartenant à chaque leader passé en paramètre
{{_ListeUnites append [_x]} forEach units group _x;} forEach _ListeLeader;
//Fonction ace disponible dans les scripts de ace :) cherchez dans ace_ia
[_Position,nil,_ListeUnites,_Taille,1,true,_Teleportation] call ace_ai_fnc_garrison;
