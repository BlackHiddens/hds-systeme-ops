/*
Gestionnaire de boutique dans l'arsenal virtuel
*/
params ["_Objet"];

if(isnil {profileNamespace getvariable "hdscompte"}) then {
  profileNamespace setVariable ["hdscompte",850.50];
};
_Lesfinances = profileNamespace getvariable "hdscompte";
_Inventaire_avant = getunitloadout player;


  _prix_armes_principale = prix select 0;
  _prix_armes_secondaire =  prix select 1;
  _prix_armes_pistolet =  prix select 2;
  _prix_munitions =  prix select 3;
  _prix_sac =  prix select 4;
  _prix_module_principale =  prix select 5;
  _prix_module_pistolet =  prix select 6;
  _prix_objet =  prix select 7;
  _prix_lunette =  prix select 8;
  _prix_vision_nocture = prix select 9;
  _prix_gilet =  prix select 10;
  _prix_chapeau = prix select 11;
  //Récupération de l'équipement du joueurs
  _armeprincipale = primaryWeapon player;
  _moduleprincipale =  primaryWeaponItems player;
  _nbs_items_arme_avant = 0;
  _nbs = 0;
  while {_nbs != count primaryWeaponItems player} do {
    if(primaryWeaponItems player select _nbs != "")then{_nbs_items_arme_avant = _nbs_items_arme_avant + 1};
    _nbs = _nbs + 1;
  };
  //arme secondaire et pistolet
  _armesecondaire = secondaryWeapon player;
  _pistolet = handgunWeapon player;
  _modulepistolet = handgunItems player;
  _nbs_items_pistolet_avant = 0;
  _nbs = 0;
  while {_nbs != count handgunItems player} do {
    if(handgunItems player select _nbs != "")then{_nbs_items_pistolet_avant = _nbs_items_pistolet_avant + 1};
    _nbs = _nbs + 1;
  };

  _gilet = vest player;
  _lunette = goggles player;
  _objets = items player;
  _munitions = magazines player;
  _sac = backpack player;
  _chapeau = headgear player;
  _vision_nocture = hmd player;


["Open",[true]] call BIS_fnc_arsenal;
waitUntil {isnull(uinamespace getvariable "RSCDisplayArsenal")};

    //Revente et achat d'une arme principale

      if(_armeprincipale isequalto "" and primaryWeapon player != "")then{_Lesfinances = _Lesfinances - _prix_armes_principale};
      if(_armeprincipale != "" and primaryWeapon player isequalto "")then{_Lesfinances = _Lesfinances - (_prix_armes_principale/3)};
      if(_armeprincipale != primaryWeapon player and primaryWeapon player != "" and _armeprincipale != "")then{_Lesfinances = (_Lesfinances + (_prix_armes_principale/3)) - _prix_armes_principale};

    //Revente et achat d'une arme secondaire
    /* if (primaryWeapon player != _armeprincipale) then {
      if(_armeprincipale != "" and primaryWeapon player != "")then{_Lesfinances = _Lesfinances - (_prix_armes_principale/2)};
      if(_armeprincipale isequalto "" and primaryWeapon player != "")then{_Lesfinances = _Lesfinances - _prix_armes_principale};
      if(_armeprincipale != "" and primaryWeapon player isequalto "")then{};
    }; */
    //Revente et achat d'un gilet

      if(_gilet isequalto "" and vest player != "")then{_Lesfinances = _Lesfinances - _prix_gilet};
      if(_gilet != "" and vest player isequalto "")then{_Lesfinances = _Lesfinances + (_prix_gilet/3)};
      if(_gilet != vest player and vest player != "" and _gilet != "")then{_Lesfinances = (_Lesfinances + (_prix_gilet/3)) - _prix_gilet};

    //Revente et achat d'un sac

      if(_sac isequalto "" and backpack player != "")then{_Lesfinances = _Lesfinances - _prix_sac};
      if(_sac != "" and backpack player isequalto "")then{_Lesfinances = _Lesfinances + (_prix_sac/3)};
      if(_sac != backpack player and backpack player != "" and _sac != "")then{_Lesfinances = (_Lesfinances + (_prix_sac/3)) - _prix_sac};

    //Revente et achat des lunettes

      if(_lunette isequalto "" and goggles player != "")then{_Lesfinances = _Lesfinances - _prix_lunette};
      if(_lunette != "" and goggles player isequalto "")then{_Lesfinances = _Lesfinances + (_prix_lunette/3)};
      if(_lunette != goggles player and goggles player != "" and _lunette != "")then{_Lesfinances = (_Lesfinances + (_prix_lunette/3)) - _prix_lunette};

    //Revente et achat des lunettes

      if(_vision_nocture isequalto "" and hmd player != "")then{_Lesfinances = _Lesfinances - _prix_vision_nocture};
      if(_vision_nocture != "" and hmd player isequalto "")then{_Lesfinances = _Lesfinances + (_prix_vision_nocture/3)};
      if(_vision_nocture != hmd player and hmd player != "" and _vision_nocture != "")then{_Lesfinances = (_Lesfinances + (_prix_vision_nocture/3)) - _prix_vision_nocture};

    //Revente et achat chapeaux

      if(_chapeau isequalto "" and headgear player != "")then{_Lesfinances = _Lesfinances - _prix_chapeau};
      if(_chapeau != "" and headgear player isequalto "")then{_Lesfinances = _Lesfinances + (_prix_chapeau/3)};
      if(_chapeau != headgear player and headgear player != "" and _chapeau != "")then{_Lesfinances = (_Lesfinances + (_prix_chapeau/3)) - _prix_chapeau};

    //Revente et achat d'accessoire de l'arme principale
      _nbs_items_arme_apres = 0;
      _nbs = 0;
      while {_nbs != count primaryWeaponItems player} do {
        if(primaryWeaponItems player select _nbs != "")then{_nbs_items_arme_apres = _nbs_items_arme_apres + 1};
        _nbs = _nbs + 1;
      };
      if(_nbs_items_arme_apres > _nbs_items_arme_avant)then{_Lesfinances = _Lesfinances - ((_prix_module_principale)*(_nbs_items_arme_apres - _nbs_items_arme_avant))};
      if(_nbs_items_arme_apres < _nbs_items_arme_avant)then{_Lesfinances = _Lesfinances + ((_prix_module_principale/3)*(_nbs_items_arme_avant -_nbs_items_arme_apres))};
      //Revente et achat d'accessoire du pistolet
        _nbs_items_pistolet_apres = 0;
        _nbs = 0;
        while {_nbs != count handgunItems player} do {
          if(handgunItems player select _nbs != "")then{_nbs_items_pistolet_apres = _nbs_items_pistolet_apres + 1};
          _nbs = _nbs + 1;
        };
        if(_nbs_items_pistolet_apres > _nbs_items_pistolet_avant)then{_Lesfinances = _Lesfinances - ((_prix_module_principale)*(_nbs_items_arme_apres - _nbs_items_arme_avant))};
        if(_nbs_items_pistolet_apres < _nbs_items_pistolet_avant)then{_Lesfinances = _Lesfinances + ((_prix_module_principale/3)*(_nbs_items_arme_avant -_nbs_items_arme_apres))};

    //achat et vente des munitions
    if ((count _munitions) > (count magazines player)) then {
      for "_i" from 0 to ((count _munitions) - (count magazines player)) do {
        _Lesfinances = _Lesfinances + (_prix_munitions/3);
      }
    };
    if((count _munitions) == (count magazines player))then{};
    if((count _munitions) < (count magazines player))then{
      for "_i" from 0 to ((count magazines player)-(count _munitions)) do {
        _Lesfinances = _Lesfinances - _prix_munitions;
      };
    };

    //achat et vente des objets
    if ((count _objets) > (count items player)) then {
      for "_i" from 0 to ((count _objets) - (count items player)) do {
        _Lesfinances = _Lesfinances + (_prix_objet/3);
      }
    };
    if((count _objets) == (count items player))then{};
    if((count _objets) < (count items player))then{
      for "_i" from 0 to ((count items player)-(count _objets)) do {
        _Lesfinances = _Lesfinances - _prix_objet;
      };
    };

    //récapitulatif de l'argent restant
    if(_Lesfinances < 0)then{
      [format [" Trop chère<br/><br/>restitution<br/> : %1 €<br />",(profileNamespace getvariable "hdscompte")]] call fnc_fnc_informations;
      player setunitloadout _Inventaire_avant;
    }else{
      profileNamespace setVariable ["hdscompte",_Lesfinances];
      [format [" Votre compte = %1 €<br />",(profileNamespace getvariable "hdscompte")]] call fnc_fnc_informations;
    };
