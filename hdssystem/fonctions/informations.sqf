// ---------------------------------------------------------------------------------------------------------------------
// Simple welcome message hint script by Jamie (A.K.A WalkingHazard)
// ---------------------------------------------------------------------------------------------------------------------
params ["_infos"];

_displayCount = -1;

// Settings
_n = 0; //Number of seconds (^10) hint will be display for

// Display hint for _n seconds
while {(_displayCount) < (_n)} do {

_separator = parseText "<br />------------------------<br />";
_imageFile = parseText "<img size='5' image='hdssystem\images\hds-s-ops.jpg'>";
//_title = parseText "<t color='#FFBF00' size='1.1' shadow='2' shadowColor='#000000' align='center'>Brieffing</t>";
//_ts = parseText "Adresse TeamSpeak";
//_infox = parseText "ts01-uk.nitrado.net:11200";
//_info = parseText "<br />------------------------<br />";
_info1 = parseText (_this select 0);

_recru = parseText "";
_recru1 = parseText "<t color='#FFBF00' size='1.1' shadow='2' shadowColor='#000000' align='center'></t>  </br>";
_fin = parseText "";
_fin1 = parseText "<t color='#FFBF00' size='1.1' shadow='2' shadowColor='#000000' align='center'>Amusez-vous bien</t>  </br>";



//_title _ts _infox _separator _separator _separator, _info,_info2,_info3,_info4,_info5,_info6,_info7,_info8

_txt = composeText [_imageFile,_separator,_info1,_recru,_recru1,_fin,_fin1];
hintSilent _txt;

_displayCount = _displayCount + 1;

// Delay hint redisplay for 10 seconds to reduce server strain, hence (_n) is ^10
sleep 8;
};
