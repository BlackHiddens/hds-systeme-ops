/*
 * fnc_hds_renfort_allie
 * ─────────────────────────────────────────────────────────────
 * Appel d'appui par clic sur la carte. Côté client : interface et
 * décompte. L'apparition elle-même part au serveur.
 *
 * 0 : <OBJECT> l'objet porteur de l'action (non utilisé, conservé
 *              pour la compatibilité des appels existants)
 */

params ["_Objet"];

openMap true;
ModeAppelRenfort = true;
publicVariable "ModeAppelRenfort";
hint "Où avez-vous besoin d'un appui ?";

onMapSingleClick {
    if (ModeAppelRenfort isEqualTo true && NbRenfortDispo > 0) then {

        // Le serveur fait apparaître : il a le registre de factions, et
        // le groupe lui appartient au lieu d'être local au client.
        [_pos, CampsRenfortAllie, player, false, 450, 650, "ASSAUT"]
            remoteExec ["fnc_hds_renfortSpawn", 2];

        openMap false;

        [West, "Base"] sideChat format [
            "Reçu, nous arrivons dès que possible sur la position %1.", _pos
        ];
        systemChat "Les troupes sont actuellement en mouvement";

        NbRenfortDispo = NbRenfortDispo - 1;
        publicVariable "NbRenfortDispo";
        hint format ["Il vous reste %1 renfort(s)", NbRenfortDispo];
    };

    if (NbRenfortDispo == 0 && { ModeAppelRenfort isEqualTo true }) then {
        [West, "Base"] sideChat "Nous n'avons plus de garnison Monsieur !";
    };

    ModeAppelRenfort = false;
    publicVariable "ModeAppelRenfort";
};
