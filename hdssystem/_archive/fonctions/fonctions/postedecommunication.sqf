params ["_objets"];
{
  //Recruter une équipe
  _x addaction [(format ["<t color='#353531'>%1</t>",hds_txt_fonctions_divers_librecruterequipe]),{
  [2,true,0] spawn fnc_generer_groupe;
  ["Equipe en cours de regroupement"] remoteexeccall ["systemChat",0];
  },[],0,false,true,"","",3];
  //Demander des renforts sur une positions
  [_x] spawn fnc_hds_demandeurderenforts;
  //Ouvrir le garage de véhicule
  if!(isnil "estungarage" or (count estungarage) == 0)then{
    [
    _x,
    (format ["<t color='#353531'>%1</t>",hds_txt_fonctions_divers_libcommandervehicule]),
    "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_hack_ca.paa",
    "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_hack_ca.paa",
    "_this distance _target < 3",
    "_this distance _target < 3",
    {},
    {},
    {
      [] call DCON_fnc_Garage_Open;
    },
    {},
    [],
    0.5,
    1,
    false,
    false
    ] call BIS_fnc_holdActionAdd;
  };

  //Permettre de débugger la mission en cours
  [
  _x,
  (format ["<t color='#353531'>%1</t>",hds_txt_fonctions_divers_libdebloquermission]),
  "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_hack_ca.paa",
  "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_hack_ca.paa",
  "_this distance _target < 3",
  "_this distance _target < 3",
  {},
  {},
  {
    if!(isnil "tache_effectuee")then{
      tache_effectuee = tache_effectuee + 1;publicVariable "tache_effectuee";
      [format['%1 : %2 %3',hdsversion,tache_effectuee,hds_txt_fonctions_divers_libdebloquermissionignorer]] remoteexeccall ['systemChat',0];
    }else{
      [format['%1 : %2',hdsversion,tache_effectuee,hds_txt_fonctions_divers_libdebloquermissionnonexiste]] remoteexeccall ['systemChat',0];
    };
  },
  {},
  [],
  5,
  1,
  false,
  false
  ] call BIS_fnc_holdActionAdd;

  //Permet de plannifier un saut en parachute
  [
    1000,
    -1,
    _x
  ] spawn fnc_hds_action_saut_parachute;

} foreach (_this select 0);
