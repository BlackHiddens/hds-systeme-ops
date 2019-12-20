params ["_Centre","_Taille","_Visible"];
_Centre = _this select 0;
_Taille = _this select 1;
_Visible = _this select 2;
//--------------------Création du marqueur de mission------------------------

_rnum = str(round (random 999));
_NomMarqueur = format ["OccupationMaster_%1",_rnum];
_MarkerZone = createMarker [_NomMarqueur,_Centre];
_MarkerZone setMarkerShape "Ellipse";
_MarkerZone setMarkerSize [_Taille,_Taille];
_MarkerZone setMarkerColor "colorOPFOR";
_MarkerZone setMarkerBrush "Horizontal";
if (_Visible isEqualTo true) then {_MarkerZone setMarkerAlpha 0.2} else {_MarkerZone setMarkerAlpha 0};

//Prendre la mission en cours
_MissionEnCour = DebutOperation;
//--------------------------Attend que tous les joueurs rentre dans la zone de mission--------------------------------------------------------
waitUntil {[_NomMarqueur,selectRandom allPlayers] call bis_fnc_inTrigger isEqualto true or DebutOperation > _MissionEnCour};

switch (round random 3) do {
    case 1:{['AmbientTrack02a_F_Tacops'] remoteExec ['PlayMusic',0]};
    case 2:{['AmbientTrack01_F_Tank'] remoteExec ['PlayMusic',0]};
    case 3:{['EventTrack01a_F_Tacops'] remoteExec ['PlayMusic',0]};
};



//["AmbientTrack02a_F_Tacops"] remoteExec ["PlayMusic",0];
//----------------------------Attend la fin des taches pour effectuer le contenu----------------------------------------------------------------
//Attend que la mission soit terminé pour être auto supprimé
waitUntil {DebutOperation > _MissionEnCour};      //Si la mission en cours change de valeur alors c'est que la mission est terminée
deleteMarker _NomMarqueur;                        //Supprimer le générateur d'ennemi (En effet il prend un peu de temps pour poser les soldats)
