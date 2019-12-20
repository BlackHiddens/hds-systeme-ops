params ["_Position","_Taille","_Ratio","_Visible"];
//---------Gén_re et place du personnels dans les batiments

_Taille = _this select 1;
_Ratio = _this select 2;
_Visible = _this select 3;

_Camps = east;

//--------------------Création du marqueur de mission------------------------
_NomduMarqueur = (format ["Occpaikada%1",str (round random 9999)]);
_MarkerZone = createMarker [_NomduMarqueur,(_this select 0)];
_MarkerZone setMarkerShape "Ellipse";
_MarkerZone setMarkerSize [_Taille,_Taille];
//-------Si le camps est différent des east alors le marqueur sera de la couleur du camps---------
_MarkerZone setMarkerColor "colorOPFOR";
if (_Camps isEqualTo independent) then {_MarkerZone setMarkerColor "colorGUER"};
if (_Camps isEqualTo west) then {_MarkerZone setMarkerColor "colorWEST"};
//--------------------------------------
_MarkerZone setMarkerBrush "Border";
//----------------------------------------------------------------------------------
//Rend visible ou invisible selon le paramètre _Visible le Marqueur afficher sur la carte
if ((_this select 3)) then {_NomduMarqueur setMarkerAlpha 0.15} else {_NomduMarqueur setMarkerAlpha 0.0};
//----------------------Stabilisation du ratio de personnels et autres variables---------------
_ListeBatiments = nearestObjects [(_this select 0),["House"],_Taille,false];
_NbBatiments = count _ListeBatiments;
//-----------------------

//------------Passe dans tous les batiments pour déposer des pax mais ne dépasse pas une certaine quantité selon la ratio et le nombre de batiments---------
for "_i" from 0 to (_this select 2) do {
  _Groupes = [_MarkerZone call bis_fnc_randomPosTrigger,east,(configfile >> "CfgGroups" >> "East" >> "LOP_AM_OPF" >> "Infantry" >> "LOP_AM_OPF_Support_section")] call BIS_fnc_spawnGroup;
  [(_this select 0),nil,(units _Groupes),(_this select 1),1,false,true] call ace_ai_fnc_garrison;
  //[_Groupes,(_this select 0),(_this select 1),1,false,true] call CBA_fnc_taskDefend;
  {[_x,"STAND","FULL"] call BIS_fnc_ambientAnimCombat;} foreach units _Groupes;
  _Groupes enableDynamicSimulation true;
};
if (((count _ListeBatiments)/3) > 30) then {[_Position,4,(_Taille/3),false] spawn fnc_AinkadaPatrouilles};
//---------------------------------------
