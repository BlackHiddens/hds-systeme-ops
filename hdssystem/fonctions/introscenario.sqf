//Initialisation du son


/*
  Permet de d'afficher un écran de présentation
*/
params ["_musique","_volumefin","_paragraphe"];

  if((_this select 1)) then {ace_hearing_disableVolumeUpdate = true};
  PlayMusic (_this select 0);

  enableRadio false;
  0 fadeSound 0;
  0 fadeMusic 0.5;
  _Structure_texte = "<t font='PuristaMedium' size=3.0 color='##FEFFFF'>";

  cutText ["", "BLACK OUT", 3];
  sleep 3;

{
  cutText [format ["%1 %2 </t>",_Structure_texte,_x],"black faded",-1,true,true];
  sleep 8;
} foreach (_this select 2);

  cutText ["","black in",5];
//Réinitialiser le son normalement
  10 fadeMusic 0;
  10 fadeSound 1.0;
  enableRadio true;
  sleep 10;
  0 fadeMusic 0.5;

  if((_this select 1)) then {
    playmusic "";
    ace_hearing_disableVolumeUpdate = false
  };
