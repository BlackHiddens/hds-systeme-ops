//------------------------------------------Occupations----------------------------------------
/*
 * Les 16 tableaux de classnames qui occupaient ce fichier ont été
 * retirés : plus rien ne les lisait.
 *
 * Les compositions ennemies viennent du registre de factions
 * (hdssystem\modulesactions), construit au démarrage depuis la config
 * du serveur. Les civils aussi, depuis que hds_fnc_factionsScanCivils
 * range les hommes de camp civil par faction. Et les renforts alliés
 * s'habillent comme les joueurs.
 *
 * Ne restent ici que deux réglages et l'initialisation des fonctions
 * du module.
 */

  HFactionennemi = [0,1,3,4,5,6];
  HFactionalliee = [2];

//Initialisation des fonctions

  //Fonctions principales pour génération d'un occupation
  fnc_occupations_init = compile preprocessFile "hdssystem\modules\occupations\h-fncsysteme\hds_occupations_init.sqf";
  fnc_hds_occupations = compile preprocessFile "hdssystem\modules\occupations\h-occupation.sqf";
  fnc_occupations_civil_init = compile preprocessFile "hdssystem\modules\occupations\h-fncsysteme\hds_occupations_civil_init.sqf";

  //Présence ennemie de fond, semée sur les localisations de la carte.
  //Même histoire que fnc_hds_missions : le corps existait dans
  //hdssystem\fonctions\fonctions\ops-presence-hostile.sqf sans jamais
  //être assigné, et le générateur savait déjà l'appeler.
  fnc_hds_presence_hostile = compile preprocessFile "hdssystem\fonctions\presence-hostile.sqf";

  //Vie civile : trafic sur les routes + population des agglomerations.
  //Remplace fnc_engima_traffic, que la case « Trafic civil » du
  //generateur appelait alors que ce script tiers n'est pas la. Tout
  //vient du registre : rien de plus que CBA_A3 en prerequis.
  fnc_hds_vie_civile = compile preprocessFile "hdssystem\fonctions\vie-civile.sqf";

  //Ajouter des actions
  //fnc_EstUnTerminalRenfort est aussi parti dans mes-parametres.sqf,
  //pour la meme raison : c'est une action posee sur le client.
  if (usafactive isEqualTo true) then {fnc_EstUnTerminalDeGroupeIARHS = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-groupeiarhs.sqf"};
  fnc_EstUnTerminalDeGroupeIA = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-groupeia.sqf";
  fnc_EstUnTerminalDeGroupePERSO = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-groupeiaperso.sqf";

  //Equipement des renforts : copie de la tenue des joueurs
  //
  //Remplace les 28 fichiers de roster R.O.S, soit environ 195 classnames
  //RHS et LOP ecrits a la main. Ils etaient de toute facon enfermes dans
  //un if (foxforactive) : FFCamoPack n'est pas installe ici, donc rien ne
  //se chargeait -- et fnc_americain_polyvalent, qu'appelait l'ancien
  //h-RenfortAllie.sqf, n'existait tout simplement pas.
  fnc_hds_equiperCommeJoueurs = compile preprocessFile "hdssystem\fonctions\equipercommejoueurs.sqf";
  fnc_hds_renfortSpawn        = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-renfortspawn.sqf";

  fnc_renfort_init = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-initrenfortallie.sqf";

  //fnc_renfort_allie et fnc_generer_groupe sont partis dans
  //mes-parametres.sqf : ce sont des fonctions CLIENT, et ce fichier-ci
  //n'est charge que par le serveur via init-systeme.sqf. Elles
  //n'existaient donc sur aucun client, alors que l'action posee par
  //fnc_EstUnTerminalRenfort les appelle de la.
  /*
  A placer dans le fichier h-mission\h-init.sqf(Recommandé) ou le retirer comme commentaire ici

  TerminalDeGroupeIAPERSO = true;publicVariable "TerminalDeGroupeIAPERS";
  TerminalDeGroupeIARHS = true;publicVariable "TerminalDeGroupeIARHS";
  TerminalDeGroupeIA = true;publicVariable "TerminalDeGroupeIA";

  if (TerminalDeGroupeIA) then {[hds_terminal,"Groupe:R.O.S"] remoteExecCall ["fnc_EstUnTerminalDeGroupeIA"]};
  if (TerminalDeGroupeIARHS) then {[hds_terminal,"Groupe:R.H.S"] remoteExecCall ["fnc_EstUnTerminalDeGroupeIA"]};
  if (TerminalDeGroupeIAPERSO)then {[hds_terminal,"Groupe:H.D.S"] remoteExecCall ["fnc_EstUnTerminalDeGroupePERSO"]};

  */
