  //initialiser les slots au démarrage de la mission selon les besoin. sinon vooir le init-reapparition.sqf
    [player,"Executer_gcam"] call bis_fnc_addcommMenuItem;
    //Configuration des médecins-----------------------------------------
    {
      if(vehiclevarname player isequalto _x)then{
        [player] spawn fnc_hds_peuposerattelle;
        player setVariable ["ace_medical_medicClass",1,true];
        player setUnitTrait ["Medic",true];
        {_x synchronizeObjectsAdd [player]} foreach sontdesappuismedicals;
      };
    } foreach sontdesmedecins;
    //---------------------------------------------------------------------

    //configuration des expert en transmission-----------------------------
    {
      if(vehiclevarname player isequalto _x)then{
        [player,"Renfort_terrestre"] call bis_fnc_addcommMenuItem;
        player setUnitTrait ["UAVHacker",true];
        {_x synchronizeObjectsAdd [player]} foreach sontdesappuisexpertcoms;
      };
    } foreach sontdesexpertcoms;
    //----------------------------------------------------------------------

    //Configuration des manageurs-------------------------------------------
    {
      if(vehiclevarname player isequalto _x)then{
        [player] spawn fnc_hds_peuposerattelle;
        [player,"Renfort_terrestre"] call bis_fnc_addcommMenuItem;
        player setUnitTrait ["engineer",true];
        player setUnitTrait ["Medic",true];
        player setVariable ["ace_medical_medicClass",1,true];
        {_x synchronizeObjectsAdd [player]} foreach sontdesappuismanageurs;
      };
    } foreach sontdesmanageurs;
    //-----------------------------------------------------------------------

    //Configuration des ingénieurs-------------------------------------------
    {
      if(vehiclevarname player isequalto _x)then{
        player setUnitTrait ["explosiveSpecialist",true];
        player setUnitTrait ["engineer",true];
        {_x synchronizeObjectsAdd [player]} foreach sontdesappuisingenieurs;

    };
    } foreach sontdesingenieurs;
    //------------------------------------------------------------------------
    //Configuration des pilotes
    {
      if(vehiclevarname player isequalto _x)then{
        player setUnitTrait ["engineer",true];
        [player,"créer un équipage"] spawn fnc_hds_creerequipages;
    };
    } foreach sontdespilotes;
    //Configuration des contractor
    {
      if(vehiclevarname player isequalto _x)then{
      {_x synchronizeObjectsAdd [player]} foreach sontdesappuiscontractor;
      [player] spawn fnc_hds_peuposerattelle;
      [player,"Renfort_terrestre"] call bis_fnc_addcommMenuItem;
    };
    } foreach sontdescontractor;

  //Exécution diverse
  {[_x] spawn fnc_hds_medical} foreach sontdeslieudesoin;
  [sontdesarsenales] spawn fnc_hds_arsenaux;
  [sontdespostesdecommunications] spawn fnc_hds_poste_de_communication;

  if(boutiqueactive)then{
  //Si le variable "hdsargent" existe alors la coder pour qu'il soit ramassable
      if!(isnil "hdsargent")then{
        [hdsargent,
        "récupérer votre part",
        "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_reviveMedic_ca.paa",
        "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_reviveMedic_ca.paa",
        ("_this distance _target < 3"),
        ("_this distance _target < 3"),
        {},
        {},
        {
          profilenamespace setvariable ["hdscompte",((profileNamespace getvariable "hdscompte") + renumeration)];
          [(format["Votre compte : %1 euros",(profileNamespace getvariable "hdscompte")])] spawn fnc_fnc_informations;
        },
        {},
        [],
        0.5,
        1.2,
        true,
        false
        ] call BIS_fnc_holdActionAdd;
      };

      //Consulter les comptes
      [
      player,
      "consulter vos compte",
      "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_hack_ca.paa",
      "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_hack_ca.paa",
      ("_this distance _target < 0.1"),
      ("_this distance _target < 0.1"),
      {},
      {},
      {
        [(format["Votre compte : %1 €",(profileNamespace getvariable "hdscompte")])] spawn fnc_fnc_informations;
      },
      {},
      [],
      0.5,
      1,
      false,
      false
      ] call BIS_fnc_holdActionAdd;
      //Consulter le tableaux de prix
      [
      player,
      "consulter le tableaux des prix",
      "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_hack_ca.paa",
      "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_hack_ca.paa",
      ("_this distance _target < 0.1"),
      ("_this distance _target < 0.1"),
      {},
      {},
      {
        [format
                [
          "arme principale : %1 € <br/>
           arme secondaire : %2 € <br/>
           arme de poing : %3 € <br/>
           chargeur : %4 € <br/>
           sac à dos : %5 € <br/>
           module principale : %6 € <br/>
           module d'arme de poing : %7 € <br/>
           objets divers : %8 € <br/>
           lunette et cagoule : %9 € <br/>
           vision nocture : %10 € <br/>
           porte plaque : %11 € <br/>
           casques et chapeaux : %12 € <br/>",
           prix select 0,
           prix select 1,
           prix select 2,
           prix select 3,
           prix select 4,
           prix select 5,
           prix select 6,
           prix select 7,
           prix select 8,
           prix select 9,
           prix select 10,
           prix select 11
                ]
        ] spawn fnc_fnc_informations;
      },
      {},
      [],
      0.5,
      1,
      false,
      false
      ] call BIS_fnc_holdActionAdd;

      [
      player,
      "consulter nombre point de vehicule",
      "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_hack_ca.paa",
      "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_hack_ca.paa",
      ("_this distance _target < 0.1"),
      ("_this distance _target < 0.1"),
      {},
      {},
      {
        [format
                [
          "Point véhicule : %1 pts",
           pointdevehicule
                ]
        ] spawn fnc_fnc_informations;
      },
      {},
      [],
      0.5,
      1,
      false,
      false
      ] call BIS_fnc_holdActionAdd;

    if(sauvegarderlesequipements isequalto true)then{
      [player,[ProfileNameSpace,"hdssystem|456987"]] call BIS_fnc_loadInventory;
      sleep 5;
      [player,[ProfileNameSpace,"hdssystem|456987"]] call BIS_fnc_saveInventory;
      [60] spawn fnc_hds_saveequipement;
    };

    [
    if(boutiqueactive)then{

      while{true}do{
        if!(isnil "nombre_de_missions")then{
        _nombre_de_missions = nombre_de_missions;
        waituntil {_nombre_de_missions != nombre_de_missions};

        profilenamespace setVariable ["hdscompte",(
          comptedemissions
          +((count allplayers)*20)
          +(random round comptedemissions)
          +(profilenamespace getvariable "hdscompte")
        )];

        [format ["Compte = %1 € (+ %2 €)<br/>",
                (profileNamespace getvariable "hdscompte")
                ]] spawn fnc_fnc_informations;
        }
      }
    }
    ] spawn bis_fnc_spawn;
  };
  hds_txt_objectif_communication = localize "str_hds_objectif_communication";
  hds_txt_objectif_otage = localize "str_hds_objectif_otage";
  hds_txt_objectif_logistique = localize "str_hds_objectif_logistique";
  hds_txt_objectif_hvt = localize "str_hds_objectif_hvt";
  hds_txt_objectif_infos = localize "str_hds_objectif_infos";
  hds_txt_objectif_piratage = localize "str_hds_objectif_piratage";
  hds_txt_objectif_structure = localize "str_hds_objectif_structure";
  hds_txt_objectif_cache = localize "str_hds_objectif_cache";
  hds_txt_objectif_arrestation = localize "str_hds_objectif_arrestation";
  hds_txt_objectif_capture = localize "str_hds_objectif_capture";
  hds_txt_objectif_securiser = localize "str_hds_objectif_securiser";

  hds_txt_virtualgarage_acheter = localize "str_hds_virtualgarage_acheter";
  hds_txt_virtualgarage_description = localize "str_hds_virtualgarage_description";

  hds_txt_fonctions_medical_santestable = localize "str_hds_fonctions_medical_santestable";
  hds_txt_fonctions_arsenal_libinteraction = localize "str_hds_fonctions_arsenal_libinteraction";
  hds_txt_fonctions_divers_libcommandervehicule = localize "str_hds_fonctions_divers_libcommandervehicule";
  hds_txt_fonctions_divers_librecruterequipe = localize "str_hds_fonctions_divers_librecruterequipe";
  hds_txt_fonctions_divers_libdebloquermission = localize "str_hds_fonctions_divers_libdebloquermission";
  hds_txt_fonctions_divers_libdebloquermissionignorer = localize "str_hds_fonctions_divers_libdebloquermissionignorer";
  hds_txt_fonctions_divers_libdebloquermissionnonexiste = localize "str_hds_fonctions_divers_libdebloquermissionnonexiste";
  hds_txt_fonctions_divers_libsautenparachute = localize "str_hds_fonctions_divers_libsautenparachute";
  hds_txt_fonctions_divers_descsautenparachute = localize "str_hds_fonctions_divers_descsautenparachute";
  /*
  {
    if(getplayeruid player isequalto _x)then{
        module_zeus synchronizeObjectsAdd [player];
        player assignCurator module_zeus;
        [module_zeus,[player],true] call ace_zeus_fnc_bi_moduleCurator;
        [format["%1 : administrateur %2 identifié",hdsversion,name player]] remoteexeccall ['systemChat',0];
        };
  } foreach hds_administrateurs;
*/

//---------------------------------------------

/*
  ["LeadTrack01_F_Tacops",
 true,
    [
      "Résumer de l'opération",
      "Sur plusieurs écran scénarisé"
    ]
  ] call fnc_hds_introduction;
*/

  [
  "
  L'hélipad est maintenant un ravitaillement automatique pour les véhicules.<br/><br/>
  "
  ] spawn fnc_fnc_informations;

  [
    [
      ["Altis"]
    ]
  ] call fnc_hds_soustitre;
