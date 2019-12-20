params ["_pos","_taille","_faction"];
_ListeDeMissions = ["0","1","2","3","4","5","6","7","8","9","10","11"];
_Choix = selectRandom _ListeDeMissions;

switch (_Choix) do {
    case "0":{[_pos,hds_txt_objectif_communication,_taille] spawn fnc_objectif_communication};
    case "1":{[_pos,hds_txt_objectif_otage,_taille] spawn fnc_objectif_otage};
    case "2":{[_pos,hds_txt_objectif_logistique,_taille] spawn fnc_objectif_logistique};
    case "3":{[_pos,hds_txt_objectif_hvt,_taille] spawn fnc_objectif_tuer};
    case "4":{[_pos,hds_txt_objectif_infos,_taille] spawn fnc_objectif_infos};
    case "5":{[_pos,hds_txt_objectif_piratage,_taille] spawn fnc_objectif_piratage};
    //case "6":{[_pos,"Convois"] spawn fnc_objectif_convois};
    case "7":{[_pos,hds_txt_objectif_structure,200,30,(_this select 2)] spawn fnc_objectif_capturerTenir};
    case "8":{[_pos,hds_txt_objectif_cache,_Taille] spawn fnc_objectif_cacheArmes};
    case "9":{[_pos,hds_txt_objectif_arrestation,_Taille] spawn fnc_objectif_apprehender};
    case "10":{[_pos,hds_txt_objectif_securiser,(_taille*2),false] spawn fnc_objectif_securiser};
    default {[_pos,hds_txt_objectif_securiser,_taille,false] spawn fnc_objectif_securiser};
};
