//missionConfigFIle >> "hds_recrutementperso" pour charger la fenetre dans l'éditeur
class hds_recrutementperso
{
	idd=-1;
	movingenable=false;
	class controls
	{
		////////////////////////////////////////////////////////
		// GUI EDITOR OUTPUT START (by Hiddens, v1.063, #Qygywo)
		////////////////////////////////////////////////////////

		class hds_titre: RscText
		{
			idc = 1001;
			style = 0;

			text = "Recrutement personnalisee"; //--- ToDo: Localize;
			x = 4 * GUI_GRID_W + GUI_GRID_X;
			y = 8.07 * GUI_GRID_H + GUI_GRID_Y;
			w = 34 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			colorBackground[] = {0,0.25,0.65,0.8};
			tooltip = ""; //--- ToDo: Localize;
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
			idc = 2000;
			style = 0;
			tooltipColorShade[] = {0,0,0,1};

			text = "Nombre de soldats"; //--- ToDo: Localize;
			x = 4.5 * GUI_GRID_W + GUI_GRID_X;
			y = 11 * GUI_GRID_H + GUI_GRID_Y;
			w = 22.5 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			colorBackground[] = {0,0,0,0};
			tooltip = ""; //--- ToDo: Localize;
		};
		class hds_signer: RscButton
		{
			idc = 1600;

			text = "Engager"; //--- ToDo: Localize;
			x = 34 * GUI_GRID_W + GUI_GRID_X;
			y = 13.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 4 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			action = "closeDialog 0;[(lbText [2100,lbCurSel 2100])] execvm 'hdssystem\modules\occupations\h-renfortallie\recruepersocustom.sqf'";
		};
		class hds_nbsoldat: RscCombo
		{
			idc = 2100;
			x = 28.5 * GUI_GRID_W + GUI_GRID_X;
			y = 11 * GUI_GRID_H + GUI_GRID_Y;
			w = 9 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			onload = "{(_this select 0) lbAdd _x} foreach ['1','2','4','8'];(_this select 0) lbSetCurSel 0";
		};
		////////////////////////////////////////////////////////
		// GUI EDITOR OUTPUT END
		////////////////////////////////////////////////////////
};
};
