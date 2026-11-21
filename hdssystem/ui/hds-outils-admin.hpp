/*
 * hdssystem\ui\hds-outils-admin.hpp
 * -------------------------------------------------------------
 * HDS — Fenêtre « Outils admin », posée dans une tablette durcie
 *
 * Inclus depuis description.ext. Ouverte par hds_fnc_outilsAdmin, qui
 * vérifie d'abord que le joueur est bien administrateur : la classe de
 * dialogue existe pour tout le monde — un fichier de description est
 * lu par toutes les machines — mais rien ne l'ouvre ailleurs.
 *
 * ===========================================================
 * LA COQUE, ET POURQUOI IL Y EN A DEUX
 * ===========================================================
 * Elle est posée DEUX fois, l'une sur l'autre :
 *
 *   1. dessinée avec des contrôles (HDS_Coque…), tout en bas ;
 *   2. l'image hdssystem\images\tablette-hds.jpg, par-dessus.
 *
 * Ce n'est pas du gâchis, c'est un filet. Arma attend normalement du
 * .paa pour une image d'interface, et le .paa se fabrique avec
 * TexView 2 / ImageToPAA, livrés dans Arma 3 Tools — un outil externe
 * qui n'est pas installé sur cette machine. Le .jpg devrait passer :
 * l'auteur d'origine affichait déjà hdssystem\images\hds-s-ops.jpg
 * dans un parseText. Mais « devrait » n'est pas « passe », et je n'ai
 * pas pu le vérifier en jeu.
 *
 * Si le .jpg se charge, il recouvre entièrement le dessin et on ne
 * voit que lui. S'il ne se charge pas, le contrôle ne peint rien et le
 * dessin reste visible dessous. Dans les deux cas il y a une coque,
 * jamais un trou.
 *
 * -- Le jour où tu installes Arma 3 Tools --
 * hdssystem\images\tablette-hds.png est la source, en 2048x1024.
 * Passe-la dans ImageToPAA, pose le .paa à côté, et change la seule
 * ligne « text = » de HDS_Image. Rien d'autre ne bouge. Tu pourras
 * alors supprimer les contrôles HDS_Coque… si tu veux, le .paa ayant
 * un canal alpha, les coins arrondis seront vraiment découpés.
 *
 * -- Pourquoi ces proportions-là --
 * 0.686 x 0.610 de l'écran : sur un 16:9 cela donne exactement 2:1 à
 * l'écran, le rapport de l'image. Sur un format plus large l'image
 * s'étire un peu, d'où un dessin sans cercle marqué — un cadre
 * essentiellement droit supporte l'étirement, pas un objectif rond.
 *
 * -- Aucune classe héritée du jeu --
 * Les contrôles sont définis en entier, avec leurs « type » et
 * « style » numériques, au lieu d'hériter de RscText / RscButtonMenu.
 * Ces classes existent dans le config du jeu, mais en dépendre pour
 * une mission qui tient à ne réclamer que CBA serait incohérent.
 *
 * Correspondance des types, pour relire sans chercher :
 *   type 0  = texte statique     type 1  = bouton
 *   type 13 = texte structuré
 *   style 0 = aligné à gauche    style 2 = centré   style 48 = image
 */

/* --- L'écran : c'est lui qui fixe tout le reste --- */
#define HDS_W   (0.626 * safezoneW)
#define HDS_X   (safezoneX + 0.187 * safezoneW)
#define HDS_H   (0.500 * safezoneH)
#define HDS_Y   (safezoneY + 0.250 * safezoneH)
#define HDS_R   (0.052 * safezoneH)
#define HDS_M   (0.012 * safezoneW)

/* --- La coque autour --- */
#define HDS_EX  (0.030 * safezoneW)
#define HDS_EY  (0.055 * safezoneH)
#define HDS_BX  (HDS_X - HDS_EX)
#define HDS_BY  (HDS_Y - HDS_EY)
#define HDS_BW  (HDS_W + 2 * HDS_EX)
#define HDS_BH  (HDS_H + 2 * HDS_EY)

/* --- Deux colonnes de boutons : l'écran est large, une seule colonne
       laisserait la moitié droite vide --- */
#define HDS_CW  ((HDS_W - 3 * HDS_M) / 2)
#define HDS_C1  (HDS_X + HDS_M)
#define HDS_C2  (HDS_X + 2 * HDS_M + HDS_CW)

class hds_outils_admin
{
    idd = 70101;
    movingEnable = 1;
    enableSimulation = 1;
    onLoad = "private _droit = ((getPlayerUID player) in (missionNamespace getVariable ['hds_administrateurs', []])) || {isServer && hasInterface}; if (!_droit) then { [{_this closeDisplay 2}, _this select 0] call CBA_fnc_execNextFrame } else { uiNamespace setVariable ['hds_outils_admin_fenetre', _this select 0]; [] call hds_fnc_outilsEtat; };";
    onUnload = "uiNamespace setVariable ['hds_outils_admin_fenetre', displayNull];";

    class controlsBackground
    {
        /* === Repli dessiné : visible seulement si l'image ne charge pas === */
        class HDS_Coque
        {
            idc = -1;
            type = 0;
            style = 0;
            x = HDS_BX;
            y = HDS_BY;
            w = HDS_BW;
            h = HDS_BH;
            text = "";
            font = "RobotoCondensed";
            sizeEx = 0.03;
            colorText[] = {1, 1, 1, 1};
            colorBackground[] = {0.16, 0.18, 0.13, 1};
            shadow = 0;
        };

        class HDS_CoqueBord : HDS_Coque
        {
            x = HDS_BX + 0.0035 * safezoneW;
            y = HDS_BY + 0.006 * safezoneH;
            w = HDS_BW - 0.007 * safezoneW;
            h = HDS_BH - 0.012 * safezoneH;
            colorBackground[] = {0.27, 0.29, 0.22, 1};
        };

        class HDS_CoqueCreux : HDS_Coque
        {
            x = HDS_X - 0.005 * safezoneW;
            y = HDS_Y - 0.009 * safezoneH;
            w = HDS_W + 0.010 * safezoneW;
            h = HDS_H + 0.018 * safezoneH;
            colorBackground[] = {0.08, 0.09, 0.07, 1};
        };

        class HDS_Objectif : HDS_Coque
        {
            x = HDS_BX + 0.011 * safezoneW;
            y = HDS_BY + 0.155 * safezoneH;
            w = 0.009 * safezoneW;
            h = 0.016 * safezoneH;
            colorBackground[] = {0.05, 0.07, 0.09, 1};
        };

        class HDS_Diode : HDS_Coque
        {
            x = HDS_BX + 0.013 * safezoneW;
            y = HDS_BY + 0.205 * safezoneH;
            w = 0.005 * safezoneW;
            h = 0.009 * safezoneH;
            colorBackground[] = {0.21, 0.69, 0.32, 1};
        };

        class HDS_HautParleur : HDS_Coque
        {
            x = HDS_BX + HDS_BW - 0.020 * safezoneW;
            y = HDS_BY + HDS_BH / 2 - 0.055 * safezoneH;
            w = 0.010 * safezoneW;
            h = 0.110 * safezoneH;
            colorBackground[] = {0.11, 0.12, 0.09, 1};
        };

        class HDS_BarreBas : HDS_Coque
        {
            x = HDS_X + HDS_W / 2 - 0.045 * safezoneW;
            y = HDS_BY + HDS_BH - 0.022 * safezoneH;
            w = 0.090 * safezoneW;
            h = 0.006 * safezoneH;
            colorBackground[] = {0.34, 0.37, 0.29, 1};
        };

        /* === La vraie coque. Si elle charge, tout ce qui précède disparaît === */
        class HDS_Image
        {
            idc = 70104;
            type = 0;
            style = 48;
            x = HDS_BX;
            y = HDS_BY;
            w = HDS_BW;
            h = HDS_BH;
            text = "hdssystem\images\tablette-hds.jpg";
            font = "RobotoCondensed";
            sizeEx = 0.03;
            colorText[] = {1, 1, 1, 1};
            colorBackground[] = {0, 0, 0, 0};
            shadow = 0;
        };

        /* === L'écran, par-dessus la coque quelle qu'elle soit === */
        class HDS_Fond : HDS_Coque
        {
            idc = 70100;
            x = HDS_X;
            y = HDS_Y;
            w = HDS_W;
            h = HDS_H;
            colorBackground[] = {0.04, 0.06, 0.08, 0.97};
        };
    };

    class controls
    {
        /* Barre de titre : la poignée. movingEnable + moving déplacent
           TOUT le display, coque et image comprises. */
        class HDS_Titre
        {
            idc = 70102;
            type = 0;
            style = 2;
            moving = 1;
            x = HDS_X;
            y = HDS_Y;
            w = HDS_W;
            h = HDS_R;
            text = "HDS — Outils admin";
            font = "RobotoCondensedBold";
            sizeEx = 0.042;
            colorText[] = {0, 0.667, 1, 1};
            colorBackground[] = {0.08, 0.11, 0.14, 1};
            shadow = 0;
        };

        class HDS_Etat
        {
            idc = 70103;
            type = 13;
            style = 0;
            x = HDS_X + HDS_M;
            y = HDS_Y + HDS_R * 1.3;
            w = HDS_W - HDS_M * 2;
            h = HDS_R * 2.2;
            size = 0.036;
            text = "";
            colorText[] = {0.78, 0.82, 0.85, 1};
            colorBackground[] = {0, 0, 0, 0};
            shadow = 0;
            class Attributes
            {
                font = "RobotoCondensed";
                color = "#c7d0d6";
                align = "left";
                shadow = 0;
            };
        };

        class HDS_BtnJournal
        {
            idc = 70110;
            type = 1;
            style = 2;
            x = HDS_C1;
            y = HDS_Y + HDS_R * 4.0;
            w = HDS_CW;
            h = HDS_R * 1.1;
            text = "Copier le journal (120 lignes)";
            tooltip = "Tout ce que le système a journalisé, erreurs comprises. C'est ce qu'il faut coller en premier.";
            action = "[120, ''] call hds_fnc_journalCopier; [] call hds_fnc_outilsEtat;";
            font = "RobotoCondensed";
            sizeEx = 0.038;
            borderSize = 0;
            offsetX = 0;
            offsetY = 0;
            offsetPressedX = 0;
            offsetPressedY = 0;
            colorText[] = {0.88, 0.92, 0.95, 1};
            colorDisabled[] = {0.4, 0.4, 0.4, 1};
            colorBackground[] = {0.11, 0.15, 0.19, 1};
            colorBackgroundDisabled[] = {0.08, 0.08, 0.08, 1};
            colorBackgroundActive[] = {0, 0.4, 0.62, 1};
            colorFocused[] = {0, 0.4, 0.62, 1};
            colorShadow[] = {0, 0, 0, 0};
            colorBorder[] = {0, 0, 0, 0};
            soundClick[] = {"\A3\ui_f\data\sound\onclick", 0.07, 1};
            soundEnter[] = {"\A3\ui_f\data\sound\onover", 0.09, 1};
            soundPush[] = {"\A3\ui_f\data\sound\new1", 0, 0};
            soundEscape[] = {"\A3\ui_f\data\sound\onescape", 0.09, 1};
        };

        class HDS_BtnErreurs : HDS_BtnJournal
        {
            idc = 70111;
            x = HDS_C2;
            text = "Copier les erreurs et alertes";
            tooltip = "Le rapport court : uniquement ce qui a mal tourné.";
            action = "[0, 'ALERTE'] call hds_fnc_journalCopier; [] call hds_fnc_outilsEtat;";
            colorText[] = {1, 0.65, 0.4, 1};
        };

        class HDS_BtnTout : HDS_BtnJournal
        {
            idc = 70112;
            y = HDS_Y + HDS_R * 5.4;
            text = "Copier tout le tampon";
            tooltip = "Les 300 dernières lignes gardées en mémoire. Long à relire, mais complet.";
            action = "[0, ''] call hds_fnc_journalCopier; [] call hds_fnc_outilsEtat;";
        };

        class HDS_BtnRegistre : HDS_BtnJournal
        {
            idc = 70113;
            x = HDS_C2;
            y = HDS_Y + HDS_R * 5.4;
            text = "Copier le registre (JSON)";
            tooltip = "À coller dans le générateur de mission, onglet « Registre du serveur ». Le JSON est construit par le serveur, seul à détenir le registre.";
            action = "[player, ''] remoteExec ['hds_fnc_factionsExportDemande', 2]; [] call hds_fnc_outilsEtat;";
            colorText[] = {0.67, 1, 0.67, 1};
        };

        class HDS_BtnFermer : HDS_BtnJournal
        {
            idc = 70119;
            x = HDS_C1;
            y = HDS_Y + HDS_R * 7.2;
            w = HDS_W - 2 * HDS_M;
            text = "Fermer";
            tooltip = "";
            action = "private _f = findDisplay 70101; if (isNull _f) then { closeDialog 0 } else { _f closeDisplay 2 };";
            colorBackground[] = {0.16, 0.09, 0.09, 1};
            colorBackgroundActive[] = {0.55, 0.16, 0.16, 1};
            colorFocused[] = {0.55, 0.16, 0.16, 1};
        };
    };
};
