//Initialisation du son
params ["_musique","_paragraphe"];

enableRadio false;
0 fadeSound 0;
0 fadeMusic 1.0;
_Structure_texte = "<t font='PuristaMedium' size=3.0 color='##FEFFFF'>";

//Introduction
PlayMusic (_this select 0);
cutText ["", "black out", 5];
{
  cutText [format ["%1 %2 </t>",_Structure_texte,_x],"black faded",-1,true,true];
  sleep 5;
} foreach (_this select 1);

//Réinitialiser le son normalement
10 fadeMusic 1.0;
10 fadeSound 1.0;
enableRadio true;
sleep 1;
0 fadeMusic 0.5;
"end1" call BIS_fnc_endMission;
/* ["Aeodrome AAC|Altis","Sénarisé par Hiddens"] spawn bis_fnc_infotext;

["Bienvenu chez vous ! Vous être actuellement avec vos camarades les plus chères.
Vous avez décidé de rentrer ensemble et exécuter cette fameuse dernière mission pour empaucher la prime exceptionnelle.
Pour se faire, il vous est donnée de faire une mission d'escorde.
Garde vos reflexe soldats vous en aurez besoin."] spawn fnc_fnc_informations;
sleep 5;
["Difficulté|10/10","Respawn infini"] spawn bis_fnc_infotext; */
