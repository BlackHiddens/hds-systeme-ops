//missionConfigFIle >> "hds_recrutement" pour charger la fenetre dans l'éditeur
class hds_recrutement
{
	idd=-1;
	movingenable=false;
	class controls
	{
		////////////////////////////////////////////////////////
		// GUI EDITOR OUTPUT START (by Hiddens, v1.063, #Cecywi)
		////////////////////////////////////////////////////////

		class hds_titre: RscText
		{
			idc = 1001;
			style = 0;

			text = "Recrutement"; //--- ToDo: Localize;
			x = 4 * GUI_GRID_W + GUI_GRID_X;
			y = 8.07 * GUI_GRID_H + GUI_GRID_Y;
			w = 34 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			colorBackground[] = {0,0.25,0.65,0.8};
		};
		class hds_background: RscFrame
		{
			idc = 1999;

			x = 4 * GUI_GRID_W + GUI_GRID_X;
			y = 9.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 34 * GUI_GRID_W;
			h = 3.5 * GUI_GRID_H;
			colorBackground[] = {0,0,0,0.85};
		};
		class hds_libellesoldat: RscText
		{
			idc = 2668;
			style = 0;
			tooltipColorShade[] = {0,0,0,1};

			text = "Type d'equipe"; //--- ToDo: Localize;
			x = 4.5 * GUI_GRID_W + GUI_GRID_X;
			y = 10 * GUI_GRID_H + GUI_GRID_Y;
			w = 7.5 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			colorBackground[] = {0,0,0,0};
			tooltip = ""; //--- ToDo: Localize;
		};
		class hds_signer: RscButton
		{
			idc = 1600;
			action = "closeDialog 0;[(lbValue [2100,lbCurSel 2100]),true,(lbValue [2200,lbCurSel 2200])] execvm 'h-missions\h-modules\h-occupations\h-renfortallie\recrueperso.sqf'";

			text = "Signer le contrat"; //--- ToDo: Localize;
			x = 31 * GUI_GRID_W + GUI_GRID_X;
			y = 13.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 7 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class hds_nbsoldat: RscCombo
		{
			idc = 2100;
			onload = "{(_this select 0) lbAdd _x} foreach ['Assaut','Soutien'];(_this select 0) lbSetCurSel 0;{(_this select 0) lbSetValue [_x,_x]} foreach [0,1];";

			x = 28.5 * GUI_GRID_W + GUI_GRID_X;
			y = 10 * GUI_GRID_H + GUI_GRID_Y;
			w = 9 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class hds_libellecamouflage: RscText
		{
			idc = 2000;
			style = 0;
			tooltipColorShade[] = {0,0,0,1};

			text = "Camouflage"; //--- ToDo: Localize;
			x = 4.5 * GUI_GRID_W + GUI_GRID_X;
			y = 11.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 7.5 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			colorBackground[] = {0,0,0,0};
			tooltip = ""; //--- ToDo: Localize;
		};
		class hds_equipecamouflage: RscCombo
		{
			idc = 2200;
			onload = "{(_this select 0) lbAdd _x} foreach ['Désert','Tigre','Urbain'];(_this select 0) lbSetCurSel 0;{(_this select 0) lbSetValue [_x,_x]} foreach [0,1,2]";

			x = 28.5 * GUI_GRID_W + GUI_GRID_X;
			y = 11.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 9 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		class hds_annuler: RscButton
		{
			idc = 1700;
			action = "closeDialog 0";

			text = "Annuler"; //--- ToDo: Localize;
			x = 26.5 * GUI_GRID_W + GUI_GRID_X;
			y = 13.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 4 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
		};
		////////////////////////////////////////////////////////
		// GUI EDITOR OUTPUT END
		////////////////////////////////////////////////////////


};
};
