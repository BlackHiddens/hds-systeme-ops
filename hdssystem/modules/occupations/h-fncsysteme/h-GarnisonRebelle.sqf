params ["_Position","_Taille","_Ratio","_Visible"];
//---------Gén_re et place du personnels dans les batiments

_Taille = _this select 1;
_Ratio = _this select 2;
_Visible = _this select 3;
//--------------------Création du marqueur de mission------------------------


_rnum = str(round (random 999));
_NomMarqueur = format ["OccupationH_%1",_rnum];
_MarkerZone = createMarker [_NomMarqueur,(_this select 0)];
_MarkerZone setMarkerShape "Ellipse";
_MarkerZone setMarkerSize [_Taille,_Taille];
//-------Si le camps est différent des east alors le marqueur sera de la couleur du camps---------
_MarkerZone setMarkerColor "colorOPFOR";
//--------------------------------------
_MarkerZone setMarkerBrush "SolidBorder";
//----------------------------------------------------------------------------------
//Rend visible ou invisible selon le paramètre _Visible le Marqueur afficher sur la carte
if (_Visible isEqualto true) then {_MarkerZone setMarkerAlpha 0.15} else {_MarkerZone setMarkerAlpha 0.0};
//----------------------Stabilisation du ratio de personnels et autres variables---------------
_ListeBatiments = nearestObjects [(_this select 0),["House"],_Taille,false];
_NbBatiments = count _ListeBatiments;
//-----------------------
//------------Passe dans tous les batiments pour déposer des pax mais ne dépasse pas une certaine quantité selon la ratio et le nombre de batiments---------

  for "_i" from 0 to (_this select 2) do {
    _Groupes= [_NomMarqueur call bis_fnc_randomPosTrigger,east,(configfile >> "CfgGroups" >> "Indep" >> "IND_G_F" >> "Infantry" >> "I_G_InfSquad_Assault")] call BIS_fnc_spawnGroup;
    /* for "_i" from (count units _Groupes) do {[_Position,(units _Groupes),_Taille+100,true] spawn fnc_ace_garnir}; */
    [_Groupes,(_this select 0),_Taille,1,0,1] call CBA_fnc_taskDefend;
    {[_x,"STAND","FULL"] call BIS_fnc_ambientAnimCombat} foreach units _Groupes;
    _Groupes enableDynamicSimulation true;
    //for "_i" from (count units _Groupes) do {[_Position,(units _Groupes),_Taille+100,true] spawn fnc_ace_garnir};
    sleep 0.5;
  };

//---------------------------------------
