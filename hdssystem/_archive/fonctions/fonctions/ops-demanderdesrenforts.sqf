params ["_objet"];
_action = format ["[%1] spawn fnc_renfort_allie;",(_this select 0)];
[(_this select 0),"<t color='#35383B'>Contacter des </t>|Renforts","Reanimer",1,0.1,false,_action,0] spawn fnc_hds_ajoutaction;
