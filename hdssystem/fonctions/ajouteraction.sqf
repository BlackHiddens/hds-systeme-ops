/*
 * fnc_hds_ajoutaction
 * Crée un addAction avec icône et durée d'exécution.
 * Params: [objet, message, icone, duree, distance, supprimer, codes, ordre]
 */

params ["_LeSujet","_LeMessage","_Icone","_LaDureeAction","_LaDistanceVisible","_Supprimer","_Codes","_Ordre"];

switch (_Icone) do {
    case ("Hacker"):      {_Icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_hack_ca.paa"};
    case ("Connecter"):   {_Icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_connect_ca.paa"};
    case ("Rechercher"):  {_Icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_search_ca.paa"};
    case ("Deconnecter"): {_Icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_unbind_ca.paa"};
    case ("Reanimer"):    {_Icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_reviveMedic_ca.paa"};
    case ("atterir"):     {_Icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_takeOff1_ca.paa"};
    default               {_Icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_connect_ca.paa"};
};

_LaDistanceVisible = format ["_this distance _target < %1", _LaDistanceVisible];

[_LeSujet,
 _LeMessage,
 _Icone,
 _Icone,
 _LaDistanceVisible,
 _LaDistanceVisible,
 {},
 {},
 {call compile (_arguments select 0)},
 {},
 [_Codes],
 _LaDureeAction,
 _Ordre,
 _Supprimer,
 false
] call BIS_fnc_holdActionAdd;
