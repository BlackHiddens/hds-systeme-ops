/*
Par : Hiddens 0.0.0.1

Descriptions : permet de focaliser l'attention de hds-tactique dans la zone souhaité.
il pourra alors générer des évènements selon le contexte de la mission

0 : <tableau> positions
1 : <entier> Taille de la zone surveillée
2 : <entier> faction généré durant les évènements 0,1,2,3,4,5,6
3 : <entier> nombre minimum d'évènements généré
4 : <entier> nombre maximum d'évènements généré

exemple :
[[0,0,0,0],1000,0,2,5] spawn fnc_tactique_plannification;

*/

params ["_position","_rayon","_faction","_min","_max"];

_nbs_evenement = round random (_this select 4);
while{_nbs_evenement < (_this select 3)}do{_nbs_evenement = round random (_this select 4)};
while {_nbs_evenement != 0} do {
    [(_this select 0),(_this select 1),(_this select 2)] remoteexec ["fnc_tactique_init",2];
    _nbs_evenement = _nbs_evenement - 1;
};
