/*
fnc_occupations_init
  initialise et paramètre l'occupations souhaitée
  0 : <tableau> positions
  1 : <entier> taille du secteur
  2 : <entier> nombre d'équipe généré
  3 : <CfgGroups> chemin classe du l'uniter à générer
  4 : <entier> 0 - defendre / 1 - patrouiller
  5 : <tableau> liste des véhicules qui pourrons apparaitre selon la ratio de difficulté
  6 : <side> camps de la faction généré
  exemple
  _equipe = [_secteur call bis_fnc_randomPosTrigger,east,(configfile >> "CfgGroups" >> "East" >> "LOP_AM_OPF" >> "Infantry" >> "LOP_AM_OPF_Support_section"),east] call fnc_occupations_init;

*/

params ["_position","_taille","_nombres_equipes","_nomclasse_equipe","_type_occupation","_camps"];

//Creer un marqueur
_secteur = [(format ["hds_occups_%1",round random 900]),(_this select 0),"Ellipse",[(_this select 1),(_this select 1)],
"BRUSH:","SolidBorder",
"COLOR:","colorOPFOR"
] call cba_fnc_createmarker;

_secteur setMarkerAlpha 0;
if(hdssysteme)then{_secteur setMarkerAlpha 1};

  for "_i" from 1 to (_this select 2) do {


        //---------Configuration des troupes aux sol

          //Si 0 alors péramétrage de garnison
          if((_this select 4) isequalto 0)then{
            _equipe = [(_secteur call bis_fnc_randomPosTrigger),
                      (_this select 5),
                       (_this select 3)
                      ] call BIS_fnc_spawnGroup;
              [(_this select 0),nil,(units _equipe),(_this select 1),1,false,true] call ace_ai_fnc_garrison;
              {[_x,"STAND","FULL"] call BIS_fnc_ambientAnimCombat} foreach units _equipe;
              _equipe enableDynamicSimulation true;
              if(hdssysteme)then{[format["%1 : création d'une équipe de garnison",hdsversion]] remoteexeccall ['systemChat',0]};
          };
          //Si 1 alors paramétrage de patrouille
          if((_this select 4) isequalto 1)then{
            _equipe = [(_secteur call bis_fnc_randomPosTrigger),
                      (_this select 5),
                      (_this select 3)
                      ] call BIS_fnc_spawnGroup;
              [_equipe,(getmarkerpos _secteur),(_this select 1)] call bis_fnc_taskpatrol;
              _equipe enableDynamicSimulation true;
              if(hdssysteme)then{[format["%1 : création d'une équipe de patrouille",hdsversion]] remoteexeccall ['systemChat',0]};
          };
  };
        //--------Configuration des véhicules---------------
  if((_this select 4) isequalto 2)then{
      for "_i" from 1 to ((_this select 2)-1) do {
          _listeroutes = ((_this select 0) nearRoads ((_this select 1)+(_this select 1)));
          _vehicule = [(getpos (selectrandom _listeroutes)),180,(SelectRandom (_this select 3)),(_this select 5)] call bis_fnc_spawnvehicle;
          [(_vehicule select 2),_secteur call bis_fnc_randomPosTrigger,(_this select 1)] call bis_fnc_taskpatrol;
          (_vehicule select 2) enableDynamicSimulation true;
          if(hdssysteme)then{[format["%1 : création d'une équipe embarquée",hdsversion]] remoteexeccall ['systemChat',0]};
        };
  };
