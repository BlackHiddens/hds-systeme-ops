#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
HDS Bridge — Commandant IA
Lit le RPT Arma 3, appelle Claude (tool use + mémoire + doctrine), écrit ordres.sqf
"""

import sys, io, re, json, time, logging, os, math, threading
from pathlib import Path
import anthropic

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

BRIDGE_DIR     = Path(__file__).parent
CFG_PATH       = BRIDGE_DIR / "config.json"
with open(CFG_PATH, encoding="utf-8") as _f:
    CFG = json.load(_f)

MISSION_DIR    = BRIDGE_DIR.parent
RPT_DIR        = Path(CFG["rpt_dir"])
API_KEY        = os.environ.get("ANTHROPIC_API_KEY") or CFG.get("api_key", "")
# La cle se met dans la variable d'environnement ANTHROPIC_API_KEY.
# config.json reste un repli, mais ne jamais l'y laisser si le dossier est partage.
MODEL          = CFG.get("model", "claude-haiku-4-5-20251001")
MISSION        = CFG["mission"]

# Ordres écrits dans AppData\Local\Arma 3 (hors dossier mission).
# Ce dossier est exclu des scans Windows Defender par l'installeur Arma 3 → pas de verrou.
# Le chemin est transmis à SQF via bridge\hds_config.sqf (généré au démarrage du bridge).
ORDRES_PATH    = BRIDGE_DIR / "hds_ordres.sqf"  # bridge\ mission — .sqf garanti compatible loadFile Arma
HDS_CONFIG_PATH = BRIDGE_DIR / "hds_config.sqf"   # conservé pour compatibilité

DIRECTIVE_PATH = BRIDGE_DIR / "directive.txt"
QUESTION_PATH  = BRIDGE_DIR / "question.txt"   # question du commandant → joueur
REPONSE_PATH   = BRIDGE_DIR / "reponse.txt"    # réponse du joueur → commandant
DOCTRINE_PATH  = BRIDGE_DIR / "doctrine.txt"

# Suivi mtime directive → cycle immédiat quand le joueur envoie une nouvelle directive
_directive_mtime: float = 0.0
_reponse_mtime:   float = 0.0   # suivi mtime reponse.txt (réponse joueur à une question)

# Question en attente du commandant (envoyée via outil demander_joueur)
_pending_question: str = ""

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [BRIDGE] %(levelname)s  %(message)s",
    datefmt="%H:%M:%S",
    stream=sys.stdout,
)
log = logging.getLogger("hds")


# ═══════════════════════════════════════════════════════════
# GÉOGRAPHIE — données dynamiques (peuplées depuis le RPT Arma)
# ═══════════════════════════════════════════════════════════

# Toutes les localisations connues : peuplées dynamiquement par parse_lines()
# via nearestLocations SQF → [HDS][MAP_LOC] → RPT.
# Aucune donnée Malden codée en dur — fonctionne sur n'importe quelle carte.
VILLAGES: dict[str, dict] = {}   # {"NomLieu": {"pos": [x,y], "desc": "..."}}

# Rayon d'influence : groupe < CTRL_RADIUS d'un lieu = tient ce lieu
CTRL_RADIUS = 600

# Localisations découvertes dynamiquement via nearestLocations SQF → RPT
# Rempli par parse_lines() à chaque ligne [HDS][MAP_LOC]
DISCOVERED_LOCS: dict[str, dict] = {}  # {"NomLieu": {"pos":[x,y], "type":"NameCity"}}

# Zones affichées dans le tableau de contrôle du rapport tactique.
# Peuplées automatiquement depuis DISCOVERED_LOCS (capitales, villes, aéroports).
# Max 15 entrées pour garder le rapport lisible.
ZONE_CTRL_DISPLAY: set[str] = set()
ZONE_CTRL_MAX = 15

# Carte courante (mis à jour dès réception de [HDS][MAP_INFO])
_world_name: str = ""
_world_size: int = 0

# Anti-harcèlement : cycle où la dernière question a été posée.
# Claude ne peut pas poser deux questions en moins de QUESTION_COOLDOWN_CYCLES cycles.
_last_question_cycle: int = -99
QUESTION_COOLDOWN_CYCLES: int = 10  # ~10 cycles ≈ 8-15 min — empêche le harcèlement


# ═══════════════════════════════════════════════════════════
# DOCTRINES TACTIQUES
# ═══════════════════════════════════════════════════════════

DOCTRINES = {
    "AGRESSIVE": (
        "CHERCHER ET DÉTRUIRE\n"
        "• Recon continu sur tous les axes d'approche (routes principales, côtes)\n"
        "• Dès contact : QRF immédiat + renfort_terrestre en soutien\n"
        "• Avance sur l'objectif principal avec 2+ groupes — 1 fixation frontale, 1 flanc\n"
        "• Ne laisse aucune zone vide : occuper() dès qu'une position est libre\n"
        "• Priorité ordres : attaquer > qrf > renfort_terrestre > occuper > recon"
    ),
    "DEFENSIVE": (
        "DÉFENSE EN PROFONDEUR\n"
        "• Garnison immédiate sur les villes principales, ports et carrefours clés\n"
        "• Avant-postes avancés (recon/embuscade) à 500m de chaque axe d'accès\n"
        "• 1-2 groupes en réserve mobile pour contre-attaque\n"
        "• Si position perdue → contre_attaque dans les 5 minutes\n"
        "• Priorité ordres : defendre > occuper > contre_attaque > embuscade"
    ),
    "GUERRILLA": (
        "HARCÈLEMENT ET MOBILITÉ\n"
        "• Jamais deux fois au même endroit — repositionner après chaque engagement\n"
        "• Embuscades sur les axes de progression ennemis (routes, passages, cols)\n"
        "• Évite les fronts — collines centrales, lisières de maquis, forêts\n"
        "• Recon permanent, action brève, disparaître\n"
        "• Priorité ordres : embuscade > recon > repositionner > qrf"
    ),
    "HYBRIDE": (
        "ADAPTATION DYNAMIQUE\n"
        "• Phase PASSIVE    → defendre les points clés + recon axes d'approche\n"
        "• Phase CONTACT    → QRF immédiat, préparer flanquement\n"
        "• Phase ENGAGEMENT → fixation frontale + débordement flanc simultané\n"
        "• Phase FOB        → frappe coordonnée multi-vecteurs (terrestre + hélio)\n"
        "• Toujours garder 1 groupe en réserve mobile"
    ),
}


# ═══════════════════════════════════════════════════════════
# OUTILS CLAUDE — tool use (function calling)
# ═══════════════════════════════════════════════════════════

TOOLS = [
    {
        "name": "repositionner",
        "description": "Déplace un groupe OPFOR à pied vers une nouvelle position. Optimal < 800m.",
        "input_schema": {
            "type": "object",
            "properties": {
                "groupe_id":    {"type": "string", "description": "ID exact du groupe (ex: OPFOR-ALPHA)"},
                "position":     {"type": "array", "items": {"type": "number"}, "minItems": 2},
                "comportement": {"type": "string", "enum": ["SAFE", "AWARE", "COMBAT"], "default": "AWARE"}
            },
            "required": ["groupe_id", "position"]
        }
    },
    {
        "name": "defendre",
        "description": (
            "Garnison défensive : occupe les bâtiments, tient le point durablement. "
            "Utilise pour TENIR un village, un carrefour, un avant-poste."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "groupe_id": {"type": "string"},
                "position":  {"type": "array", "items": {"type": "number"}, "minItems": 2}
            },
            "required": ["groupe_id", "position"]
        }
    },
    {
        "name": "embarquer",
        "description": (
            "Monte un groupe dans le véhicule ami le plus proche et le projette vers la destination. "
            "OBLIGATOIRE si le groupe a des véhicules (veh>0) et que la destination est à >500m. "
            "Logistique motorisée : rapide, expose moins les troupes."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "groupe_id":   {"type": "string"},
                "destination": {"type": "array", "items": {"type": "number"}, "minItems": 2}
            },
            "required": ["groupe_id", "destination"]
        }
    },
    {
        "name": "debarquer",
        "description": "Fait sortir un groupe de son véhicule à une position pour combattre à pied.",
        "input_schema": {
            "type": "object",
            "properties": {
                "groupe_id": {"type": "string"},
                "position":  {"type": "array", "items": {"type": "number"}, "minItems": 2}
            },
            "required": ["groupe_id", "position"]
        }
    },
    {
        "name": "recon",
        "description": (
            "Envoie un groupe en patrouille de reconnaissance silencieuse. "
            "À utiliser quand l'ennemi n'est pas localisé ou pour surveiller un axe."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "groupe_id": {"type": "string"},
                "zone":      {"type": "array", "items": {"type": "number"}, "minItems": 2},
                "rayon":     {"type": "integer", "default": 400}
            },
            "required": ["groupe_id", "zone"]
        }
    },
    {
        "name": "embuscade",
        "description": (
            "Place un groupe en embuscade silencieuse (couché, attend l'ennemi). "
            "Idéal sur un axe de progression ennemi probable : routes principales, passages, côtes."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "groupe_id": {"type": "string"},
                "position":  {"type": "array", "items": {"type": "number"}, "minItems": 2}
            },
            "required": ["groupe_id", "position"]
        }
    },
    {
        "name": "attaquer",
        "description": "Assaut Search and Destroy sur un objectif. Utilise seulement si supériorité confirmée.",
        "input_schema": {
            "type": "object",
            "properties": {
                "groupe_id": {"type": "string"},
                "objectif":  {"type": "array", "items": {"type": "number"}, "minItems": 2}
            },
            "required": ["groupe_id", "objectif"]
        }
    },
    {
        "name": "qrf",
        "description": (
            "Réaction rapide : envoie le groupe OPFOR disponible le plus proche d'une position de contact. "
            "À utiliser dès qu'un contact est signalé."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "position":     {"type": "array", "items": {"type": "number"}, "minItems": 2},
                "taille_min":   {"type": "integer", "default": 3},
                "comportement": {"type": "string", "enum": ["AWARE", "COMBAT"], "default": "COMBAT"}
            },
            "required": ["position"]
        }
    },
    {
        "name": "renfort_terrestre",
        "description": (
            "RENFORT — Fait arriver une colonne motorisée (véhicule + soldats de la faction OPFOR) depuis hors-carte par route (~3min). "
            "QUAND l'utiliser : tous tes groupes sont engagés ou détruits, tu as besoin de nouveaux effectifs. "
            "Ne pas utiliser si tu as des groupes disponibles — repositionne-les plutôt."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "position": {"type": "array", "items": {"type": "number"}, "minItems": 2,
                             "description": "Position d'arrivée du renfort [x, y]"}
            },
            "required": ["position"]
        }
    },
    {
        "name": "contre_attaque",
        "description": (
            "Envoie un groupe existant reprendre agressivement une position perdue (SAD combat + garnison après). "
            "Différent d'attaquer() : le groupe tient la position une fois reprise. "
            "Utilise pour reconquérir un point stratégique."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "groupe_id": {"type": "string", "description": "ID exact du groupe qui fait la contre-attaque"},
                "position":  {"type": "array", "items": {"type": "number"}, "minItems": 2, "description": "Position à reprendre [x, y]"}
            },
            "required": ["groupe_id", "position"]
        }
    },
    {
        "name": "insertion",
        "description": (
            "RENFORT — Dépose par hélicoptère une nouvelle section de la faction OPFOR sur zone (~2min). "
            "Utilise quand tu n'as plus de groupes disponibles dans le secteur et que la distance est >3km. "
            "NE PAS confondre avec insertion_helico() qui transporte un GROUPE EXISTANT."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "position": {"type": "array", "items": {"type": "number"}, "minItems": 2,
                             "description": "LZ de dépose [x, y]"}
            },
            "required": ["position"]
        }
    },
    {
        "name": "occuper",
        "description": (
            "Envoie un groupe existant occuper et tenir une zone (garnison dans les bâtiments, HOLD permanent). "
            "Similaire à defendre() mais sans attendre l'arrivée — garnison immédiate dès sur place. "
            "Utilise pour s'emparer durablement d'une position stratégique."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "groupe_id": {"type": "string", "description": "ID exact du groupe qui va occuper la zone"},
                "position":  {"type": "array", "items": {"type": "number"}, "minItems": 2, "description": "Position à occuper [x, y]"}
            },
            "required": ["groupe_id", "position"]
        }
    },
    # ── Comportements tactiques avancés ─────────────────────────
    {
        "name": "mission_attaque",
        "description": (
            "MISSION COORDONNEE — Envoie 1 à 3+ groupes attaquer un objectif de façon coordonnée. "
            "1 groupe : attaque directe SAD. "
            "2 groupes : groupe 1 = suppression frontale, groupe 2 = flanquement 90°. "
            "3+ groupes : fixation frontale + double flanquement gauche/droite + réserve mobile. "
            "PRÉFÉRER cette fonction à attaquer() dès que tu as 2+ groupes disponibles."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "groupes_ids": {"type": "array", "items": {"type": "string"}, "minItems": 1,
                               "description": "Liste des groupe_ids participants ex: [\"G1\",\"G2\"]"},
                "objectif":    {"type": "array", "items": {"type": "number"}, "minItems": 2,
                               "description": "Position cible [x, y]"}
            },
            "required": ["groupes_ids", "objectif"]
        }
    },
    {
        "name": "insertion_helico",
        "description": (
            "TRANSPORT AERIEN — Transporte un groupe EXISTANT par hélico vers un objectif d'assaut (>2km). "
            "Hélico existant sur carte en priorité, spawn au point OPFOR le plus proche si aucun dispo. "
            "Séquence : heli vient chercher le groupe → embarquement → vol → LZ → débarquement → assaut. "
            "NE PAS CONFONDRE avec insertion() qui spawne de NOUVELLES troupes."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "groupe_id":   {"type": "string", "description": "ID exact du groupe à transporter"},
                "destination": {"type": "array",  "items": {"type": "number"}, "minItems": 2,
                               "description": "LZ d'insertion et objectif d'assaut [x,y]"}
            },
            "required": ["groupe_id", "destination"]
        }
    },
    {
        "name": "extraction_helico",
        "description": (
            "REPOSITIONNEMENT AERIEN — Envoie un hélico VIDE chercher un groupe et le dépose à destination. "
            "Hélico existant en priorité, spawn au point OPFOR le plus proche si aucun dispo. "
            "Séquence : heli (vide, juste pilote) → LZ groupe → embarquement → vol → dépose → groupe tient zone. "
            "Utilisations : groupe encerclé, repositionnement rapide longue distance, réserve mobile."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "groupe_id":   {"type": "string"},
                "destination": {"type": "array", "items": {"type": "number"}, "minItems": 2,
                               "description": "Destination après extraction [x,y]"}
            },
            "required": ["groupe_id", "destination"]
        }
    },
    {
        "name": "poste_avance",
        "description": (
            "Établit un poste avancé défensif (FOA) : périmètre 360°, prone, "
            "garnison bâtiments, patrouilles courtes régulières. "
            "PLUS COMPLET que defendre() : échelon les unités sur tout le périmètre, "
            "effectue des rondes de sécurité toutes les 5-8min. "
            "QUAND l'utiliser : terrain clé à tenir durablement (crête, carrefour, entrée de village), "
            "avant-poste sur un axe d'approche ennemi probable, ou surveillance prolongée d'une zone."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "groupe_id": {"type": "string"},
                "position":  {"type": "array", "items": {"type": "number"}, "minItems": 2}
            },
            "required": ["groupe_id", "position"]
        }
    },
    {
        "name": "suppression",
        "description": (
            "Feu de suppression / appui-feu : groupe prend position dominante et tire en continu sur la cible. "
            "Utilisé pour COUVRIR la manœuvre d'un autre groupe (fixation frontale pendant flanquement). "
            "Le groupe se positionne sur terrain élevé, à genou (MIDDLE), et maintient SAD vers l'objectif. "
            "DOCTRINE : toujours coupler suppression() + attaquer() ou insertion_helico() en simultané. "
            "Ex: ALPHA suppression([cible]) pendant que BRAVO attaquer([flanc])."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "groupe_id":       {"type": "string", "description": "Groupe qui fournit le feu de couverture"},
                "position_cible":  {"type": "array",  "items": {"type": "number"}, "minItems": 2,
                                   "description": "Zone à supprimer (là où l'ennemi est ou va être)"}
            },
            "required": ["groupe_id", "position_cible"]
        }
    },
    {
        "name": "appui_helico",
        "description": (
            "APPUI CAS — Spawn un hélicoptère de combat de la faction OPFOR qui attaque et patrouille la zone. "
            "QUAND l'utiliser : position fortifiée, véhicule blindé ennemi, nettoyer zone avant assaut. "
            "ATTENTION : risque de feu ami — utilise uniquement sur zones sans troupes OPFOR proches."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "position": {"type": "array", "items": {"type": "number"}, "minItems": 2,
                            "description": "Centre de la zone d'appui feu CAS [x, y]"}
            },
            "required": ["position"]
        }
    },
    {
        "name": "regrouper",
        "description": (
            "Ralliement d'urgence : annule tous les ordres en cours (garnison, patrouille, embuscade) "
            "et fait converger le groupe vers un point de rassemblement à vitesse maximale. "
            "QUAND l'utiliser : avant une frappe coordonnée multi-groupes, après pertes sévères, "
            "groupe isolé qui doit rejoindre la ligne principale, ou concentration de forces avant assaut majeur. "
            "À l'arrivée le groupe attend (HOLD) le prochain ordre."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "groupe_id":            {"type": "string"},
                "position_ralliement":  {"type": "array", "items": {"type": "number"}, "minItems": 2,
                                        "description": "Point de rassemblement [x,y]"}
            },
            "required": ["groupe_id", "position_ralliement"]
        }
    },
    {
        "name": "demander_joueur",
        "description": (
            "Communique avec le GÉNÉRAL (joueur humain). UNIQUEMENT dans ces deux cas :\n"
            "  (1) DEMANDE DE RENFORTS — OBLIGATOIRE avant d'utiliser renfort_terrestre(), "
            "insertion(), contre_attaque(), occuper(). Ces outils font apparaître de nouvelles "
            "troupes : tu dois obtenir l'accord du Général AVANT. "
            "Format strict : 'Général, je demande autorisation [outil] à [position] : [raison en 1 phrase].'\n"
            "  (2) RAPPORT DE DÉFAITE — si tous tes effectifs sont à zéro et la mission irréalisable, "
            "informe le Général et admets la défaite.\n"
            "\n"
            "ABSOLUMENT INTERDIT — NE JAMAIS DEMANDER :\n"
            "  ✗ 'Dois-je continuer l'attaque ?' — TU DÉCIDES.\n"
            "  ✗ 'Que faire avec mes pertes ?' — TU ADAPTES (replier/regrouper/tenir).\n"
            "  ✗ 'Dois-je me replier ?' — TU CHOISIS selon la situation.\n"
            "  ✗ 'Quelle est ta priorité ?' — MISSION PERMANENTE = ta priorité.\n"
            "  ✗ Coordonnées, positions, confirmations de manœuvres, infos déjà dans le rapport.\n"
            "  ✗ Toute question tactique — la tactique c'est TON rôle, pas celui du Général.\n"
            "\n"
            "Pertes importantes mais effectifs > 0 → tu gères SEUL : qrf(), regrouper(), "
            "extraction_helico(), replier vers position défensive — sans demander.\n"
            "Si autorisé → utilise l'outil de renfort au cycle suivant immédiatement. "
            "Si refus ou sans réponse → continue sans renfort, compose avec tes effectifs."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "question": {
                    "type": "string",
                    "description": "Question claire et concise à poser au joueur (1-3 phrases max)."
                },
                "contexte": {
                    "type": "string",
                    "description": "Bref contexte expliquant pourquoi tu as besoin de cette information."
                }
            },
            "required": ["question"]
        }
    },
]


# ═══════════════════════════════════════════════════════════
# CONTEXTE CARTE — system prompt (mis en cache API)
# ═══════════════════════════════════════════════════════════

MAP_CONTEXT = """Tu es le Commandant OPFOR dans Arma 3.
Mission : dominer la carte, neutraliser les forces BLUFOR (ouest), tenir les positions strategiques.
Tu raisonnes et agis comme un vrai officier de commandement — logique militaire rigoureuse.

La carte en cours et ses localisations exactes (noms + coordonnees) te sont fournies dans chaque
rapport tactique, section "LOCALISATIONS CARTE" et "CONTROLE DES ZONES". Utilise ces coordonnees.
Ne jamais utiliser une coordonnee qui ne vient pas de ces sections ou d'une directive joueur.

======= SYSTEME DE COORDONNEES ARMA 3 =======

Les outils attendent des positions en METRES [x, y, 0].
  [0,0] = coin SUD-OUEST de la carte.  x croissant = EST.  y croissant = NORD.
  Grille 4 chiffres : "XX-YY"    -> [XX*100, YY*100, 0]           ex: "48-92" -> [4800,9200,0]
  Grille 6 chiffres : "XXX-YYY"  -> [X1X2*100+X3*10, Y1Y2*100+Y3*10, 0]
Si le joueur cite une grille -> convertis et utilise EXACTEMENT ces coordonnees.
En cas de doute sur une position -> demander_joueur() plutot qu'inventer.

======= ANALYSE DU TERRAIN — PRINCIPES GENERAUX =======

COLLINES / CRETES :
  Avantage defensif MAXIMAL. Defenseur en crete surclasse attaquant en montee (ratio 3:1).
  Point culminant = observation 360 degres = information = initiative.
  Tenir les cretes = dominer la carte.

PLAINES COTIERES :
  Vitesse vehicules MAIS couverture NULLE.
  Un groupe en plaine decouverte = cible facile. Traverser vite, ne pas stationner.
  Zones de debarquement probables -> surveiller en permanence.

FORETS / MAQUIS :
  Ralentit les vehicules, couvre l'infanterie.
  Ideal pour embuscades et repositionnements discrets.

CARREFOURS ROUTIERS :
  Verrous logistiques. Tenir un carrefour = bloquer les renforts ennemis.
  Les perdre = permettre un encerclement rapide.

======= AXES D'APPROCHE BLUFOR — PRINCIPES =======

BLUFOR attaque generalement depuis le SUD / SUD-EST (debarquement ou hors-carte).
Identifier les localites au sud de la carte (y faible) = zones d'entree probables.
L'axe principal est le couloir routier le plus direct vers l'objectif OPFOR principal.
Les flancs est et ouest permettent des contournements -> surveiller avec recon().

LIGNES DEFENSIVES GENERIQUES :
  LIGNE AVANT    : localites sud/periph. — retarder, renseigner, puis replier
  LIGNE CENTRALE : carrefours et hauteurs — garnison lourde, poste_avance
  LIGNE ARRIERE  : ville/port principal — defense absolue, reserve mobile QRF

======= PRIORITES STRATEGIQUES (ordre de decision) =======

  1. TENIR les villes/ports principaux (NameCity/NameCityCapital) — objectifs primaires
  2. CONTROLER les points culminants — observation = initiative
  3. BLOQUER les passages/cols sur l'axe principal — embuscade = 20-30min de retard
  4. COUVRIR les flancs est et ouest — empecher le debordement
  5. SURVEILLER les zones de debarquement (cotes, plages au sud) — detection precoce

======= PRINCIPES DE COMMANDEMENT MILITAIRE =======

1. ECONOMIE DE FORCE — Concentre sur les points decisifs, pas partout.
   Un groupe < 3 hommes = inutile, declenche contre_attaque ou renfort.
   Ne jamais mettre 2 groupes sur un meme point (gaspillage).

2. SOUTIEN MUTUEL — Deux groupes allies < 800m se couvrent mutuellement.
   Flanc expose = flanc mort. Colmate les breches avant d'avancer.

3. DEFENSE EN PROFONDEUR — Ligne avant + ligne principale + reserve.
   Reserve = contre-attaque. Ne la deploie jamais en avant sans raison.

4. INITIATIVE — Sans contact = RECON sur zones suspectes.
   Avec contact = FIXER frontalement + DEBORDER un flanc simultanement.

5. LOGISTIQUE (REGLE ABSOLUE) :
   [a pied] + distance > 3000m -> insertion_helico() ou renfort_terrestre()
   [a pied] + distance 2000-3000m -> renfort_terrestre() ou insertion_helico()
   [a pied] + distance < 2000m -> repositionner() ou defendre() — JAMAIS d'helico
   [veh > 0] + distance > 500m -> embarquer() OBLIGATOIRE

6. MEMOIRE — Ne repete pas si situation inchangee. Garnison stable -> laisse sauf urgence.

7. COORDINATION MULTI-VECTEURS — La tactique c'est deux outils simultanement :
   suppression(A, cible) + attaquer(B, flanc)       — fixer + deborder
   suppression(A, cible) + insertion_helico(B, LZ)  — fixation + surprise aerienne
   embuscade(A, passage) + defendre(B, village)     — retarder + tenir
   appui_helico(zone) + attaquer(A, zone)           — CAS + assaut terrestre simultane

======= CATALOGUE DES ORDRES DISPONIBLES =======

DEPLACEMENT :
  repositionner(groupe, pos, [comportement])  — deplacement tactique < 800m
  regrouper(groupe, ralliement)               — sprint rassemblement, annule tout

TRANSPORT :
  embarquer(groupe, destination)              — motorise -> zone (spawn camion si necessaire)
  debarquer(groupe, pos)                      — sortir vehicule, pied
  insertion_helico(groupe, objectif)          — transport helico existant -> LZ -> assaut (>2km OBLIGATOIRE)
  extraction_helico(groupe, zone_sure)        — recupere groupe en difficulte par helico

DEFENSE / OCCUPATION :
  defendre(groupe, pos)                       — garnison batiments, HOLD
  poste_avance(groupe, pos)                   — FOA : perimetre 360, prone, patrouilles
  occuper(pos, faction)                       — spawn garnison + patrouille + vehicule

COMBAT OFFENSIF :
  attaquer(groupe, objectif)                  — assaut SAD offensif
  qrf(pos, taille_min)                        — groupe disponible le plus proche -> contact
  embuscade(groupe, pos)                      — position cachee, attend l'ennemi
  suppression(groupe, cible)                  — feu de couverture pour manoeuvre alliee
  appui_helico(pos, faction)                  — CAS Kajman arme sur zone

RENFORT (SPAWN) :
  renfort_terrestre(pos, faction)             — colonne motorisee hors-carte (~3min)
  contre_attaque(pos, faction)               — force combinee inf+veh pour reprendre
  insertion(pos, faction)                     — helico + NOUVELLES troupes

RENSEIGNEMENT :
  recon(groupe, zone, rayon)                  — patrouille silencieuse, localiser BLUFOR

======= PHASES ET POSTURES =======

  PASSIVE        -> poste_avance verrous principaux + recon axes d'approche sud
  CONTACT        -> qrf() immediat + suppression() + flanquement
  ENGAGEMENT     -> suppression(frontal) + attaquer(flanc) simultane
  FOB_IDENTIFIEE -> appui_helico(fob) + insertion_helico(groupe, fob) + renfort_terrestre(fob)

======= INITIATIVES AUTONOMES — SANS DIRECTIVE =======

  PASSIVE, capitale/ville principale vide   -> poste_avance(groupe, ville) — objectif vital
  PASSIVE, point culminant vide             -> poste_avance(groupe, sommet) — observation 360
  PASSIVE, passage/col cle vide             -> embuscade(groupe, passage) — bloquer axe
  PASSIVE, flanc est vide                   -> recon(groupe, flanc_est) — surveiller cote
  PASSIVE, zone sud vide                    -> recon(groupe, zone_sud) — surveiller entree
  CONTACT sud (y faible)                    -> qrf + embuscade axe principal — intercepter
  CONTACT est (x eleve)                     -> renforcer flanc droit + recon cote est
  CONTACT nord (y eleve)                    -> QRF vers objectif principal — proteger port
  FOB identifiee                            -> appui_helico + insertion_helico simultanes
  Groupe < 3 hommes                         -> extraction_helico + contre_attaque position
  2 groupes sur meme point                  -> repositionner l'un sur un verrou vide

======= REGLES ABSOLUES SUR LES POSITIONS =======

Coordonnees TOUJOURS valides — tu peux les utiliser sans demander :
  1. Section "LOCALISATIONS CARTE" du rapport (nearestLocations SQF — exactes)
  2. Section "CONTROLE DES ZONES" du rapport
  3. Section "FORCES OPFOR" du rapport — [x,y] de chaque groupe = coordonnee reelle en jeu
     → poste_avance(groupe, [sa_position])      : tenir la position actuelle
     → repositionner(groupe, [x+300, y+200, 0]) : deplacer a 300m est, 200m nord
     → recon(groupe, [sa_position], 500)         : patrouiller autour
  4. Position identifiee par le joueur (section "POSITIONS IDENTIFIEES")
  5. Grille convertie dans la directive courante
  6. Offset +/-200 a 800m autour d'une position connue

JAMAIS utiliser demander_joueur() pour :
  - Des coordonnees ou noms de lieux
  - Des informations deja presentes dans le rapport tactique (positions OPFOR, contacts)
  - Des confirmations de routine
  demander_joueur() = UNIQUEMENT directive ambigue du joueur ou choix irreversible majeur.

Si LOCALISATIONS CARTE vide -> utilise les positions OPFOR du rapport. Tu n'es PAS bloque.

TERMINOLOGIE :
  ennemi / forces ennemies / BLUFOR = forces OUEST (side west) — ceux que tu combats
  tes troupes / nos forces / OPFOR = forces EST/independant — ce que tu commandes"""


# ═══════════════════════════════════════════════════════════
# ÉTAT TACTIQUE
# ═══════════════════════════════════════════════════════════

class Etat:
    def __init__(self):
        self.opfor:     dict[str, list]  = {}
        self.effectifs: dict[str, int]   = {}
        self.vehicules: dict[str, dict]  = {}
        self.contacts:  list[dict]       = []
        self.pertes:    list[str]        = []
        self.fob_pos:   list | None      = None
        self.last_seen: dict[str, float] = {}  # timestamp derniere position OPFOR connue
        self.faction:   int              = 0   # faction OPFOR (0=CSAT, 1=AAF, 3=FIA, 5=RHS-Russie, 6=Afghan)
        # Contexte tactique en temps réel
        self.behavior:   dict[str, str]  = {}  # "SAFE" / "AWARE" / "COMBAT"
        self.in_vehicle: dict[str, bool] = {}  # leader monté dans véhicule
        self.garrison:   dict[str, bool] = {}  # groupe en garnison active
        self.waypoints:  dict[str, int]  = {}  # nb waypoints actifs

    def add_contact(self, c: dict):
        c["t_bridge"] = time.time()
        self.contacts.append(c)
        self.contacts = self.contacts[-30:]
        self._update_fob()

    def add_perte(self, gid: str, avant: int, apres: int):
        msg = f"{gid}: {avant}->{apres} hommes"
        self.pertes.append(msg)
        self.pertes = self.pertes[-10:]
        self.effectifs[gid] = apres
        if apres == 0:
            # Groupe anéanti — retirer complètement de l'état OPFOR
            self._retirer_groupe(gid)
            log.info(f"[ETAT] {gid} anéanti — retiré de l'état OPFOR")
        else:
            log.info(f"PERTES {msg}")

    def _retirer_groupe(self, gid: str):
        """Retire un groupe de tous les dictionnaires d'état."""
        self.opfor.pop(gid, None)
        self.effectifs.pop(gid, None)
        self.vehicules.pop(gid, None)
        self.behavior.pop(gid, None)
        self.in_vehicle.pop(gid, None)
        self.garrison.pop(gid, None)
        self.waypoints.pop(gid, None)
        self.last_seen.pop(gid, None)

    def purge_stale(self, max_age_s: float = 180):
        """Retire les groupes dont la position n'a pas été mise à jour depuis max_age_s."""
        now = time.time()
        stale = [gid for gid, ts in list(self.last_seen.items()) if now - ts > max_age_s]
        for gid in stale:
            self._retirer_groupe(gid)
            log.info(f"[ETAT] {gid} non vu depuis {int(max_age_s)}s — retiré (probablement détruit)")

    def _update_fob(self):
        recent = [c for c in self.contacts if time.time() - c.get("t_bridge", 0) < 600]
        if len(recent) >= 3:
            xs = [c["position"][0] for c in recent]
            ys = [c["position"][1] for c in recent]
            cx, cy = sum(xs) / len(xs), sum(ys) / len(ys)
            if max(max(xs) - min(xs), max(ys) - min(ys)) < 500:
                self.fob_pos = [int(cx), int(cy), 0]

    def resume_blufor(self) -> str:
        if not self.contacts:
            return "  Aucun contact — BLUFOR non localisés"
        now = time.time()
        lines = []
        for c in self.contacts[-6:]:
            p   = c.get("position", [0, 0, 0])
            age = int(now - c.get("t_bridge", now))
            age_s = f"{age}s" if age < 60 else f"{age // 60}min"
            lines.append(
                f"  [T-{age_s}] {c.get('unite','?')} @ [{int(p[0])},{int(p[1])}]"
                f"  repéré par {c.get('groupe','?')}"
            )
        if self.fob_pos:
            lines.append(f"  !! FOB ESTIMÉE @ [{self.fob_pos[0]},{self.fob_pos[1]}]")
        return "\n".join(lines)

    def resume_pertes(self) -> str:
        return "\n".join(f"  {p}" for p in self.pertes) if self.pertes else "  Aucune"

    def phase(self) -> str:
        if not self.contacts:       return "PASSIVE"
        if self.fob_pos:            return "FOB_IDENTIFIEE"
        if len(self.contacts) >= 3: return "ENGAGEMENT"
        return "CONTACT"


ETAT = Etat()

# Mémoire des ordres — last order type par groupe
_group_orders:  dict[str, str] = {}
# Compteur de cycles
_cycle_count: int = 0

# Lieux décrits par le joueur dans ses directives (persistant toute la session)
# Format : {"nom/desc" : {"pos": [x,y,0], "desc": "description complète"}}
_lieux_joueur: dict[str, dict] = {}


# ═══════════════════════════════════════════════════════════
# HELPERS GÉOGRAPHIQUES / INTELLIGENCE
# ═══════════════════════════════════════════════════════════

def _dist(p1: list, p2: list) -> int:
    return int(math.sqrt((p1[0]-p2[0])**2 + (p1[1]-p2[1])**2))

def _nearest_village(pos: list) -> tuple[str, int]:
    if not VILLAGES:
        return "?", 99999
    best_name, best_dist = "?", 99999
    for name, data in VILLAGES.items():
        d = _dist(pos, data["pos"])
        if d < best_dist:
            best_name, best_dist = name, d
    return best_name, best_dist

def _estimate_zone_control() -> dict[str, str]:
    """Estime le contrôle des zones stratégiques (ZONE_CTRL_DISPLAY) selon positions OPFOR et contacts BLUFOR."""
    ctrl = {}
    if not VILLAGES or not ZONE_CTRL_DISPLAY:
        return ctrl
    for vname, data in VILLAGES.items():
        if vname not in ZONE_CTRL_DISPLAY:
            continue
        vpos = data["pos"]
        opfor_near = [gid for gid, pos in ETAT.opfor.items() if _dist(pos, vpos) < CTRL_RADIUS]
        blufor_near = [c for c in ETAT.contacts
                       if time.time() - c.get("t_bridge", 0) < 300
                       and _dist(c.get("position", [0, 0]), vpos) < 600]
        if opfor_near and not blufor_near:
            ctrl[vname] = f"OPFOR ({', '.join(opfor_near[:2])})"
        elif opfor_near and blufor_near:
            ctrl[vname] = "⚔ CONTESTÉ"
        elif blufor_near:
            ctrl[vname] = "⚠ BLUFOR"
        else:
            ctrl[vname] = "vide"
    return ctrl

def _min_threat_dist(pos: list) -> int | None:
    """Distance minimale entre pos et le dernier contact BLUFOR connu."""
    if not ETAT.contacts:
        return None
    recent = [c for c in ETAT.contacts if time.time() - c.get("t_bridge", 0) < 300]
    if not recent:
        return None
    return min(_dist(pos, c.get("position", [0, 0])) for c in recent)

def _transport_advice(pos: list, veh: dict, nearest_dist: int) -> str:
    """Conseil logistique pour ce groupe (tient compte des véhicules vides proches)."""
    veh_count = veh.get("count", 0)   # soldats déjà dans un véhicule
    dispo     = veh.get("dispo",  0)  # véhicules vides dans un rayon de 600m

    if veh_count > 0 and nearest_dist > 500:
        return f"→ EMBARQUER() vers objectif ({nearest_dist}m) [veh équipé]"
    if veh_count == 0 and dispo > 0 and nearest_dist > 500:
        return f"→ EMBARQUER() — {dispo} véh. vide(s) à 600m ({nearest_dist}m objectif)"
    if veh_count == 0 and dispo == 0 and nearest_dist > 3000:
        return f"⚠ TRÈS LOIN ({nearest_dist}m) → INSERTION_HELICO() [rapide+surprise] ou renfort_terrestre()"
    if veh_count == 0 and dispo == 0 and nearest_dist > 2000:
        return f"⚠ AUCUN VÉH ({nearest_dist}m) → renfort_terrestre() ou insertion_helico()"
    if veh_count == 0 and dispo == 0 and nearest_dist > 800:
        return f"({nearest_dist}m à pied — lent, envisager embarquer() si véh disponible)"
    return ""


# ═══════════════════════════════════════════════════════════
# RPT
# ═══════════════════════════════════════════════════════════

def find_rpt() -> Path | None:
    files = list(RPT_DIR.glob("*.rpt"))
    return max(files, key=lambda p: p.stat().st_mtime) if files else None

def read_new(path: Path, pos: int) -> tuple[list[str], int]:
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            f.seek(pos)
            lines = f.readlines()
            return lines, f.tell()
    except OSError:
        return [], pos

def parse_lines(lines: list[str]) -> list[str]:
    triggers = []
    for line in lines:
        # Position OPFOR + véhicule + contexte tactique temps réel
        # Format : [HDS][OPFOR_POS] GID @ [x,y] Nh veh=N(type) dispo=N b=BEHAV inv=T/F gar=T/F wp=N
        m = re.search(
            r"\[HDS\]\[OPFOR_POS\] (.+?) @ \[(\d+),(\d+)\] (\d+)h "
            r"(veh=[^\s]*)(?:\s+dispo=(\d+))?(?:\s+b=(\w+))?(?:\s+inv=([TF]))?(?:\s+gar=([TF]))?(?:\s+wp=(\d+))?",
            line
        )
        if m:
            gid = m.group(1).strip()
            ETAT.opfor[gid]      = [int(m.group(2)), int(m.group(3))]
            ETAT.effectifs[gid]  = int(m.group(4))
            ETAT.last_seen[gid]  = time.time()
            vm = re.match(r"veh=(\d+)(?:\((\w+)\))?", m.group(5))
            dispo = int(m.group(6)) if m.group(6) else 0
            if vm:
                ETAT.vehicules[gid] = {"count": int(vm.group(1)), "type": vm.group(2), "dispo": dispo}
            else:
                ETAT.vehicules[gid] = {"count": 0, "type": None, "dispo": dispo}
            # Contexte tactique temps réel
            if m.group(7):  ETAT.behavior[gid]   = m.group(7)          # SAFE/AWARE/COMBAT
            if m.group(8):  ETAT.in_vehicle[gid]  = m.group(8) == "T"  # monté en véhicule
            if m.group(9):  ETAT.garrison[gid]    = m.group(9) == "T"  # en garnison
            if m.group(10): ETAT.waypoints[gid]   = int(m.group(10))   # nb waypoints actifs
            # Log relayé
            veh_cnt = ETAT.vehicules[gid]["count"]
            veh_typ = ETAT.vehicules[gid]["type"] or "?"
            veh_log = f"veh={veh_cnt}({veh_typ})" if veh_cnt > 0 else "veh=0"
            behav   = ETAT.behavior.get(gid, "?")
            log.info(f"[HDS][OPFOR_POS] {gid} @ [{ETAT.opfor[gid][0]},{ETAT.opfor[gid][1]}] {ETAT.effectifs[gid]}h {veh_log} dispo={dispo} b={behav}")

        # Contact BLUFOR
        m2 = re.search(r"\[HDS_CONTACT\](\{.*\})", line)
        if m2:
            try: ETAT.add_contact(json.loads(m2.group(1)))
            except Exception: pass

        # Pertes
        m3 = re.search(r"\[HDS_PERTES\]([^|]+)\|(\d+)\|(\d+)", line)
        if m3:
            ETAT.add_perte(m3.group(1), int(m3.group(2)), int(m3.group(3)))

        # ── Info carte (worldName / worldSize) ──────────────────────────────
        # Format : [HDS][MAP_INFO] worldName=Malden worldSize=12800 centre=[6400,6400]
        m_info = re.search(r"\[HDS\]\[MAP_INFO\] worldName=(\S+) worldSize=(\d+)", line)
        if m_info:
            global _world_name, _world_size
            new_name = m_info.group(1)
            new_size = int(m_info.group(2))
            if new_name != _world_name:
                # Changement de carte → réinitialiser toutes les données géographiques
                if _world_name:
                    log.info(f"[MAP] Changement de carte : {_world_name} → {new_name} — reset géographie")
                    VILLAGES.clear()
                    DISCOVERED_LOCS.clear()
                    ZONE_CTRL_DISPLAY.clear()
                _world_name = new_name
                _world_size = new_size
                log.info(f"[MAP] Carte : {_world_name} ({_world_size}x{_world_size}m)")

        # ── Localisations carte (dump nearestLocations depuis SQF) ──────────
        # Format : [HDS][MAP_LOC] NomLieu @ [x,y] type=NameCity
        # Le SQF répète le dump toutes les 3min — on ignore les doublons silencieusement.
        m_loc = re.search(r"\[HDS\]\[MAP_LOC\] (.+?) @ \[(\d+),(\d+)\] type=(\w+)", line)
        if m_loc:
            loc_name = m_loc.group(1).strip()
            loc_x    = int(m_loc.group(2))
            loc_y    = int(m_loc.group(3))
            loc_type = m_loc.group(4)
            if loc_name and loc_name not in DISCOVERED_LOCS:
                # Première réception — enregistrer et loguer
                DISCOVERED_LOCS[loc_name] = {"pos": [loc_x, loc_y], "type": loc_type}
                type_desc = {
                    "NameCityCapital": "CAPITALE",
                    "NameCity":        "VILLE",
                    "NameVillage":     "VILLAGE",
                    "Airport":         "AEROPORT",
                    "CityCenter":      "CENTRE-VILLE",
                    "nameLocal":       "LIEU",
                }.get(loc_type, loc_type)
                if loc_name in VILLAGES:
                    VILLAGES[loc_name]["pos"] = [loc_x, loc_y]
                else:
                    VILLAGES[loc_name] = {
                        "pos":  [loc_x, loc_y],
                        "desc": f"{type_desc} @ [{loc_x},{loc_y}]"
                    }
                # Auto-ajout dans ZONE_CTRL_DISPLAY (villes, capitales, aéroports)
                if loc_type in ("NameCityCapital", "NameCity", "Airport") and \
                        len(ZONE_CTRL_DISPLAY) < ZONE_CTRL_MAX:
                    ZONE_CTRL_DISPLAY.add(loc_name)
                    log.info(f"[MAP] Zone stratégique : {loc_name} [{loc_x},{loc_y}] ({type_desc})")
                else:
                    log.info(f"[MAP] Lieu : {loc_name} [{loc_x},{loc_y}] ({type_desc})")
            # Doublon (dump répété) → silencieux, ne rien faire

        # Diagnostic exécuteur — fichier ordres introuvable
        # Faction OPFOR configurée en jeu
        m_fac = re.search(r"\[HDS\]\[FACTION_OPFOR\] (\d+)", line)
        if m_fac:
            ETAT.faction = int(m_fac.group(1))

        # Groupe anéanti signalé explicitement par detection.sqf
        m_det = re.search(r"\[HDS\]\[OPFOR_DETRUIT\] (.+)", line)
        if m_det:
            gid_det = m_det.group(1).strip()
            ETAT._retirer_groupe(gid_det)
            log.info(f"[ETAT] {gid_det} detruit (signal SQF) — retiré immédiatement")

        if "[HDS_EXEC] FICHIER ORDRES INTROUVABLE" in line:
            m_path = re.search(r"path=(.+)", line)
            log.error(f"[SQF] FICHIER ORDRES INTROUVABLE — Arma lit : {m_path.group(1).strip() if m_path else '?'}")
            log.error(f"[SQF]   Bridge écrit dans : {ORDRES_PATH}")

        if "[HDS_TRIGGER]CYCLE_IA" in line:
            triggers.append("CYCLE_IA")
        elif "[HDS_TRIGGER]CYCLE_STRATEGIQUE" in line:
            triggers.append("CYCLE_STRATEGIQUE")

    return triggers


# ═══════════════════════════════════════════════════════════
# DIRECTIVE ET DOCTRINE
# ═══════════════════════════════════════════════════════════

def read_directive() -> str:
    try:
        t = DIRECTIVE_PATH.read_text(encoding="utf-8").strip()
        return t if t else ""
    except Exception:
        return ""

def _directive_changed() -> bool:
    """Renvoie True si directive.txt a été modifié depuis le dernier check."""
    global _directive_mtime
    try:
        mtime = DIRECTIVE_PATH.stat().st_mtime
        if mtime != _directive_mtime:
            changed = _directive_mtime > 0   # False au tout premier appel (init)
            _directive_mtime = mtime
            return changed
    except Exception:
        pass
    return False

def _reponse_changed() -> bool:
    """Renvoie True si reponse.txt existe et a été modifié (réponse joueur à une question)."""
    global _reponse_mtime
    try:
        if not REPONSE_PATH.exists():
            return False
        mtime = REPONSE_PATH.stat().st_mtime
        if mtime != _reponse_mtime:
            _reponse_mtime = mtime
            return True
    except Exception:
        pass
    return False

def read_reponse() -> str:
    """Lit et efface reponse.txt. Retourne la réponse du joueur."""
    global _pending_question, _reponse_mtime
    try:
        txt = REPONSE_PATH.read_text(encoding="utf-8").strip()
        REPONSE_PATH.unlink(missing_ok=True)
        _reponse_mtime = 0.0
        # Effacer la question en attente
        _pending_question = ""
        QUESTION_PATH.unlink(missing_ok=True)
        return txt
    except Exception:
        return ""

def read_doctrine() -> str:
    try:
        t = DOCTRINE_PATH.read_text(encoding="utf-8").strip().upper()
        return t if t in DOCTRINES else "HYBRIDE"
    except Exception:
        return "HYBRIDE"


# ═══════════════════════════════════════════════════════════
# PROMPT TACTIQUE — intelligence pré-calculée pour Claude
# ═══════════════════════════════════════════════════════════

def build_tactical_update(trigger: str) -> str:
    phase   = ETAT.phase()
    doctrine = read_doctrine()

    # Info carte courante
    if _world_name:
        map_info = f"Carte: {_world_name} ({_world_size}x{_world_size}m)"
    else:
        map_info = "Carte: en attente (Arma pas encore lancé)"

    # IDs de groupes valides — affiché EN PREMIER pour que Claude ne les invente jamais
    valid_ids = list(ETAT.opfor.keys())
    id_block = (
        f"⚠ GROUPES COMMANDABLES — utilise CES IDs EXACTEMENT, aucun autre :\n"
        + "\n".join(f'  "{gid}"' for gid in valid_ids)
    ) if valid_ids else "⚠ AUCUN GROUPE OPFOR CONNU — n'émet PAS d'ordre avec groupe_id"

    # Rappel de la mission permanente (toujours visible dans le rapport tactique)
    mission_active = read_directive()
    mission_bloc = []
    if mission_active:
        mission_court = mission_active[:200].replace("\n", " ")
        mission_bloc = [
            f"MISSION DU GÉNÉRAL : \"{mission_court}{'...' if len(mission_active) > 200 else ''}\"",
            "  → Chaque ordre doit faire progresser cette mission.",
            "",
        ]

    # Détection de défaite (tous les effectifs connus à zéro)
    defaite = (
        bool(ETAT.opfor) and
        all(ETAT.effectifs.get(gid, 1) == 0 for gid in ETAT.opfor)
    )

    # Groupes libres (sans mission en cours) — affiché AVANT le reste pour forcer l'attention
    libres = []
    en_mission_gids = []
    for gid in ETAT.opfor:
        eff_g  = ETAT.effectifs.get(gid, 0)
        n_wp_g = ETAT.waypoints.get(gid, 0)
        gar_g  = ETAT.garrison.get(gid, False)
        inv_g  = ETAT.in_vehicle.get(gid, False)
        if eff_g > 0 and not gar_g and not inv_g and n_wp_g <= 1:
            libres.append(gid)
        elif eff_g > 0:
            en_mission_gids.append(gid)

    libres_bloc = []
    if libres:
        libres_bloc = [
            f"🔴 GROUPES SANS MISSION ({len(libres)}/{len(ETAT.opfor)}) — ORDRE IMMÉDIAT OBLIGATOIRE :",
            "  RÈGLE ABSOLUE : chacun de ces groupes DOIT recevoir un ordre ce cycle.",
            "  Un groupe sans mission = effectif perdu = faute de commandement.",
        ] + [f"    → {gid} ({ETAT.effectifs.get(gid,'?')}h) @ {ETAT.opfor[gid]}" for gid in libres] + [""]

    lines = [
        f"=== RAPPORT TACTIQUE | Cycle #{_cycle_count} | {map_info} | Phase: {phase} | Doctrine: {doctrine} | Déclencheur: {trigger} ===",
        "",
    ] + mission_bloc + libres_bloc + [
        id_block,
        "",
        "FORCES OPFOR :",
    ]

    if not ETAT.opfor:
        lines.append("  (en attente — aucune position reçue du RPT)")
    else:
        for gid, pos in ETAT.opfor.items():
            eff      = ETAT.effectifs.get(gid, "?")
            veh      = ETAT.vehicules.get(gid, {"count": 0, "type": None, "dispo": 0})
            dispo    = veh.get("dispo", 0)
            if veh["count"] > 0:
                veh_str = f"veh={veh['count']} {veh.get('type','?')}"
            elif dispo > 0:
                veh_str = f"à pied (+{dispo} véh. vide(s) proches)"
            else:
                veh_str = "à pied"

            near_v, dist_v = _nearest_village(pos)
            threat_d = _min_threat_dist(pos)
            threat_str = f" | menace BLUFOR à {threat_d}m" if threat_d else ""
            adv      = _transport_advice(pos, veh, dist_v)
            adv_str  = f" | {adv}" if adv else ""
            last_ord = _group_orders.get(gid, "aucun")

            # ── Contexte tactique temps réel ────────────────────
            behav   = ETAT.behavior.get(gid, "?")
            inv     = ETAT.in_vehicle.get(gid, False)
            gar     = ETAT.garrison.get(gid, False)
            n_wp    = ETAT.waypoints.get(gid, 0)

            # Statut lisible pour Claude — basé sur waypoints réels, pas juste le mode behaviour
            en_mission = n_wp > 1 or gar or inv
            if behav == "COMBAT" and n_wp > 1:
                etat_str = "⚔ EN COMBAT/APPROCHE"
            elif behav == "COMBAT" and n_wp <= 1:
                etat_str = "⚠ ALERTE (contact récent)"
            elif gar:
                etat_str = "🏠 GARNISON"
            elif inv and n_wp > 1:
                etat_str = "🚗 EN TRANSIT"
            elif n_wp > 1:
                etat_str = "👁 EN MISSION (wp actifs)"
            else:
                etat_str = ">>> LIBRE — SANS MISSION <<<"

            lines.append(
                f"  {'🔴 ' if not en_mission else '  '}{gid} ({eff}h) [{veh_str}] @ [{pos[0]},{pos[1]}]"
                f" | {dist_v}m de {near_v}{threat_str}{adv_str}"
                f" | last: {last_ord} | état: {etat_str}"
            )

    # ── Localisations carte réelles (données en jeu via nearestLocations SQF) ──
    if DISCOVERED_LOCS:
        lines += ["", "LOCALISATIONS CARTE (coordonnées exactes du jeu — prioritaires) :"]
        type_order = {"NameCityCapital": 0, "NameCity": 1, "NameVillage": 2,
                      "Airport": 3, "CityCenter": 4}
        sorted_locs = sorted(
            DISCOVERED_LOCS.items(),
            key=lambda kv: (type_order.get(kv[1]["type"], 9), kv[0])
        )
        for name, info in sorted_locs:
            p = info["pos"]
            t = info["type"].replace("Name", "").replace("City", "Ville").replace("Village", "Village")
            lines.append(f"  {name:<18} [{p[0]:5},{p[1]:5}]  ({t})")
    else:
        # ── MODE DÉGRADÉ : pas encore de données carte ──────────────────────
        lines += [
            "",
            "⚠ LOCALISATIONS CARTE EN ATTENTE (données SQF pas encore reçues — arrivée dans < 3min)",
            "  → En attendant, utilise les positions OPFOR ci-dessus comme base d'action :",
            "    Ces coordonnées sont VALIDES — ce sont de vraies positions en jeu.",
        ]
        if ETAT.opfor:
            lines.append("  POSITIONS OPFOR UTILISABLES IMMÉDIATEMENT :")
            for gid, pos in ETAT.opfor.items():
                eff = ETAT.effectifs.get(gid, "?")
                lines.append(f"    {gid} @ [{pos[0]},{pos[1]}]  ({eff}h) — poste_avance/defendre/recon valides ici")
        lines += [
            "  RÈGLE MODE DÉGRADÉ :",
            "    • poste_avance(groupe, [position_du_groupe])   → tenir sa position actuelle",
            "    • recon(groupe, [position_du_groupe], 500)     → patrouiller autour",
            "    • repositionner(groupe, [x±300, y±300, 0])    → ajustement local de ±300m",
            "    • INTERDICTION ABSOLUE de demander_joueur() pour des coordonnées",
            "      → agis avec ce que tu as, les données arrivent dans moins de 3 minutes.",
        ]

    # Lieux décrits par le joueur (mémoire de session)
    if _lieux_joueur:
        lines += ["", "POSITIONS IDENTIFIÉES PAR LE JOUEUR (utilise ces coordonnées en priorité) :"]
        for ref, info in _lieux_joueur.items():
            p = info["pos"]
            lines.append(f"  grille {ref} → [{p[0]},{p[1]}]  — {info['desc']}")

    # ── Question en attente de réponse ──────────────────────────────────────
    if _pending_question:
        lines += [
            "",
            "⚠ QUESTION EN ATTENTE — LE JOUEUR N'A PAS ENCORE RÉPONDU :",
            f"  Ta question : {_pending_question}",
            "  → Si tu as suffisamment d'infos pour agir, n'attends pas — émet tes ordres.",
            "  → Si tu as absolument besoin de la réponse, rappelle la question via demander_joueur().",
        ]

    # Contrôle des zones
    lines += ["", "CONTRÔLE DES ZONES :"]
    ctrl = _estimate_zone_control()
    if ctrl:
        for vname, status in ctrl.items():
            vpos = VILLAGES[vname]["pos"]
            desc = VILLAGES[vname].get("desc", "")
            lines.append(f"  {vname:<18} [{vpos[0]:5},{vpos[1]:5}]  {status:<25} ({desc})")
    else:
        lines.append("  (en attente des localisations carte — démarrer la mission pour recevoir les données SQF)")

    # Contacts BLUFOR
    lines += ["", "CONTACTS BLUFOR :", ETAT.resume_blufor()]

    # Pertes
    lines += ["", "PERTES :", ETAT.resume_pertes()]

    # Alertes situationnelles
    alerts = []
    if defaite:
        alerts.append(
            "🚨 DÉFAITE IMMINENTE : tous les effectifs OPFOR connus sont à zéro. "
            "Utilise demander_joueur() pour informer le Général et admettre la défaite."
        )
    if ETAT.pertes:
        alerts.append("⚠ PERTES SUBIES — demander renforts au Général ou repositionner les survivants.")
    if phase == "FOB_IDENTIFIEE" and ETAT.fob_pos:
        fob = ETAT.fob_pos
        alerts.append(f"⚠ FOB IDENTIFIÉE @ [{fob[0]},{fob[1]}] — frappe coordonnée possible.")
    if phase == "ENGAGEMENT":
        alerts.append("⚠ CONTACT ACTIF — réagis immédiatement.")
    non_tenus = [v for v, s in ctrl.items() if s == "vide" or s == "⚠ BLUFOR"]
    if non_tenus:
        alerts.append(f"⚠ ZONES NON TENUES : {', '.join(non_tenus)} — sécuriser pour avancer la mission.")
    if alerts:
        lines += [""] + alerts

    # Doctrine active
    doc_text = DOCTRINES.get(doctrine, "")
    if doc_text:
        lines += ["", f"[DOCTRINE ACTIVE : {doctrine}]"]
        lines += [f"  {l}" for l in doc_text.split("\n")]

    # Consignes finales
    no_map = not DISCOVERED_LOCS  # True si on n'a pas encore reçu les localisations carte
    lines += [
        "",
        "CONSIGNES :",
        "  • Raisonne en 2-4 phrases CONCRÈTES : quelle progression vers la mission, quel groupe, pourquoi maintenant.",
        "  • Donne UN ordre différent par groupe — chaque ordre doit servir la MISSION DU GÉNÉRAL.",
        f"  • Groupes disponibles : {', '.join(ETAT.opfor.keys()) if ETAT.opfor else '(aucun — attendre le RPT)'}",
        "  • RENFORTS : renfort_terrestre / insertion / contre_attaque / occuper → DEMANDER AUTORISATION D'ABORD.",
        "    Utilise demander_joueur() avant d'appeler ces outils. Sans autorisation = sans renfort.",
    ]
    if no_map and ETAT.opfor:
        lines += [
            "  • ⚠ LOCALISATIONS CARTE ABSENTES — MODE DÉGRADÉ :",
            "      Les coordonnées [x,y] de tes groupes (section FORCES OPFOR) sont VALIDES et UTILISABLES.",
            "      → poste_avance(groupe, [x,y,0])   utilise exactement la position du groupe",
            "      → recon(groupe, [x,y,0], 500)      patrouille autour de sa position",
            "      → INTERDICTION de demander_joueur() — la réponse n'ajoutera rien, AGIS.",
        ]
    lines += [
        "  • LOGISTIQUE STRICTE :",
        "      [à pied] + destination > 3km → insertion_helico() UNIQUEMENT",
        "      [à pied] + destination 2-3km → renfort_terrestre() ou insertion_helico()",
        "      [à pied] + destination < 2km → repositionner() ou defendre() — PAS d'hélico",
        "      [veh > 0] + destination > 500m → embarquer() OBLIGATOIRE",
        "  • insertion_helico() n'est valide que si la DISTANCE au groupe est > 2km.",
        "  • VARIÉTÉ : si tu as déjà envoyé un groupe en RECON quelque part, envoie le suivant AILLEURS.",
        "  • ÉTAT TEMPS RÉEL (champ 'état') — respecte le statut de chaque groupe :",
        "      💤 STATIQUE       → PRIORITÉ : assigne-lui une mission concrète MAINTENANT",
        "      🚗 EN VÉHICULE    → laisse-le arriver, ne contre-ordonne pas sauf urgence",
        "      👁 EN MOUVEMENT   → confirme ou réoriente selon la situation",
        "      🏠 GARNISON       → ne change pas sauf pression ennemie forte ou directive",
        "      ⚔ EN COMBAT      → renforce avec qrf(), suppression(), ou extrait si pertes graves",
    ]

    return "\n".join(lines)


# ═══════════════════════════════════════════════════════════
# MÉMOIRE MULTI-TOURS
# ═══════════════════════════════════════════════════════════

MAX_HISTORY_TURNS  = 4
_history:           list[dict] = []
_pending_tool_res:  list[dict] = []


# ═══════════════════════════════════════════════════════════
# CONVERSION GRILLES MILITAIRES ARMA 3
# ═══════════════════════════════════════════════════════════

def _convert_spatial_refs(directive: str) -> str:
    """
    Détecte les références de direction relative dans la directive
    (à l'est, au nord, etc.) et ajoute les coordonnées estimées.
    Utilise le groupe en COMBAT comme référence, sinon le premier groupe connu.
    """
    if not ETAT.opfor:
        return directive

    # Ordre important : diagonales avant cardinaux pour éviter match partiel
    DIR_MAP = [
        (r'\bnord[- ]?est\b',   ( 350,  350, "NORD-EST")),
        (r'\bnord[- ]?ouest\b', (-350,  350, "NORD-OUEST")),
        (r'\bsud[- ]?est\b',    ( 350, -350, "SUD-EST")),
        (r'\bsud[- ]?ouest\b',  (-350, -350, "SUD-OUEST")),
        (r'\best\b',            ( 500,    0, "EST")),
        (r'\bouest\b',          (-500,    0, "OUEST")),
        (r'\bnord\b',           (   0,  500, "NORD")),
        (r'\bsud\b',            (   0, -500, "SUD")),
    ]

    matched = []
    for pattern, vec in DIR_MAP:
        if re.search(pattern, directive, re.IGNORECASE):
            matched.append(vec)
    if not matched:
        return directive

    # Groupe de référence : celui en COMBAT en priorité, sinon le premier
    ref_gid = next(
        (gid for gid, beh in ETAT.behavior.items() if beh == "COMBAT"),
        next(iter(ETAT.opfor), None)
    )
    if not ref_gid:
        return directive

    ref_pos = ETAT.opfor[ref_gid]
    additions = []
    for dx, dy, label in matched:
        tx, ty = int(ref_pos[0] + dx), int(ref_pos[1] + dy)
        additions.append(
            f"  '{label}' de {ref_gid} [{ref_pos[0]},{ref_pos[1]}] "
            f"→ cible estimée [{tx},{ty},0]  (±300m selon terrain)"
        )

    return (
        directive
        + "\n\n[DIRECTIONS CONVERTIES EN COORDONNÉES ESTIMÉES]\n"
        + "\n".join(additions)
        + "\nUtilise CES coordonnées comme objectif — qrf() ou attaquer() si 'neutraliser'."
    )


def _convert_grid_refs(directive: str) -> str:
    """
    Détecte les grilles militaires Arma 3 dans la directive et ajoute
    la conversion en coordonnées [x,y,0] pour Claude.

    Formats reconnus (avec tiret ou espace comme séparateur) :
      4-fig : "48-92"  → 2 chiffres × 100 = mètres → [4800, 9200, 0]
      6-fig : "075-105"→ (2 premiers × 100) + (3e × 10) → [750, 1050, 0]

    Référence grille Arma 3 : ex: grille "48-92" = [4800,9200,0]

    Si le joueur décrit un lieu associé à une grille ("grille 52-65 c'est une crête"),
    le lieu est mémorisé dans _lieux_joueur pour les cycles futurs.
    """
    global _lieux_joueur
    conversions = []
    seen: set[str] = set()
    grid_to_pos: dict[str, list] = {}

    # ── 6-figure : "XXX-YYY" (3 chiffres chaque côté) ──────
    for m in re.finditer(r'\b(\d{3})[- ](\d{3})\b', directive):
        ref = m.group(0)
        if ref in seen:
            continue
        seen.add(ref)
        g1, g2 = m.group(1), m.group(2)
        x = int(g1[:2]) * 100 + int(g1[2]) * 10
        y = int(g2[:2]) * 100 + int(g2[2]) * 10
        grid_to_pos[ref] = [x, y, 0]
        conversions.append(f"  grille '{ref}' → [{x},{y},0]")
        log.info(f"[GRID] '{ref}' converti en [{x},{y},0]")

    # ── 4-figure : "XX-YY" (2 chiffres chaque côté) ─────────
    masked = re.sub(r'\b\d{3}[- ]\d{3}\b', '___', directive)
    for m in re.finditer(r'\b(\d{2})[- ](\d{2})\b', masked):
        ref = m.group(0)
        if ref in seen:
            continue
        seen.add(ref)
        g1, g2 = m.group(1), m.group(2)
        x = int(g1) * 100
        y = int(g2) * 100
        grid_to_pos[ref] = [x, y, 0]
        conversions.append(f"  grille '{ref}' → [{x},{y},0]")
        log.info(f"[GRID] '{ref}' converti en [{x},{y},0]")

    # ── Mémoriser les descriptions de lieux ─────────────────
    # Patterns : "grille XX-YY [il y a / c'est / =] <description>"
    #          : "à la grille XX-YY <description>"
    for ref, pos in grid_to_pos.items():
        idx = directive.find(ref)
        if idx < 0:
            continue
        # Chercher la description après la grille (ou avant, ex: "base au nord grille X")
        after = directive[idx + len(ref):idx + len(ref) + 120].strip()
        desc_match = re.match(
            r"[\s,]*(?:c'est|il y a|:|=|→|contient|est)?\s*([^,\.!?\n]{4,80})",
            after, re.IGNORECASE
        )
        if desc_match:
            desc_raw = desc_match.group(1).strip()
            # Chercher aussi un nom avant la grille (ex: "base militaire grille X")
            before = directive[max(0, idx - 60):idx].strip()
            name_match = re.search(r'([A-Za-zÀ-ÿ\s\-\']{4,40})\s*(?:grille|à la grille|coord(?:onnée)?s?)\s*$', before, re.IGNORECASE)
            label = name_match.group(1).strip() if name_match else desc_raw[:40]
            full_desc = f"{label} — {desc_raw}" if name_match else desc_raw
            _lieux_joueur[ref] = {"pos": pos, "desc": full_desc}
            log.info(f"[LIEU] mémorisé '{ref}' = {full_desc} @ {pos[:2]}")

    if not conversions:
        return directive

    return (
        directive
        + "\n\n[GRILLES CONVERTIES EN COORDONNÉES CARTE]\n"
        + "\n".join(conversions)
        + "\nUtilise EXACTEMENT ces coordonnées dans tes ordres."
    )


# ═══════════════════════════════════════════════════════════
# APPEL CLAUDE
# ═══════════════════════════════════════════════════════════

def call_claude(trigger: str) -> tuple[list, dict] | None:
    global _history, _pending_tool_res, _group_orders, _cycle_count, _last_question_cycle

    _cycle_count += 1
    client    = anthropic.Anthropic(api_key=API_KEY)
    directive = read_directive()
    doctrine  = read_doctrine()

    # ── System message (mis en cache API) ──────────────────
    system: list[dict] = [
        {"type": "text", "text": MAP_CONTEXT, "cache_control": {"type": "ephemeral"}}
    ]

    # Doctrine overlay (mis en cache si présent)
    doc_text = DOCTRINES.get(doctrine, "")
    if doc_text:
        system.append({
            "type": "text",
            "text": (
                f"DOCTRINE ACTIVE : {doctrine}\n"
                f"{doc_text}\n\n"
                "Cette doctrine est ton cadre stratégique permanent. "
                "Toutes tes décisions doivent être cohérentes avec elle."
            ),
            "cache_control": {"type": "ephemeral"}
        })

    # Directive joueur — mission permanente (reste active jusqu'à changement)
    if directive:
        # Convertir les grilles militaires Arma 3 en coordonnées [x,y,0]
        directive_proc = _convert_grid_refs(directive)
        # Convertir les directions relatives (est/ouest/nord/sud) en coordonnées estimées
        directive_proc = _convert_spatial_refs(directive_proc)
        system.append({
            "type": "text",
            "text": (
                "MISSION PERMANENTE DU GÉNÉRAL — TON OBJECTIF STRATÉGIQUE :\n"
                f"{directive_proc}\n\n"
                "TERMINOLOGIE : 'ennemi' / 'BLUFOR' = forces OUEST (side west) — ceux que tu combats. "
                "TES troupes = OPFOR (est/indépendant).\n\n"
                "TRADUCTION DES INTENTIONS :\n"
                "  'neutraliser' / 'éliminer' / 'détruire' → qrf(pos) ou attaquer(groupe, pos) — JAMAIS defendre()\n"
                "  'prendre' / 'capturer' / 'tenir' → poste_avance() ou defendre() après avoir attaqué\n"
                "  Direction estimée (EST/NORD/etc.) fournie ci-dessus → utilise CES coordonnées comme objectif\n\n"
                "CADRE DE COMMANDEMENT — RÈGLES ABSOLUES :\n"
                "  1. Cette mission est PERMANENTE. Tu y travailles cycle après cycle jusqu'à accomplissement ou défaite.\n"
                "  2. Chaque cycle : évalue les progrès et ordonne CE QUI FAIT AVANCER la mission.\n"
                "\n"
                "  ══ RÈGLE FONDAMENTALE — UTILISATION DES TROUPES EXISTANTES ══\n"
                "  → TES TROUPES SONT TA PREMIÈRE ET SEULE RESSOURCE PAR DÉFAUT.\n"
                "  → Chaque groupe marqué '🔴 LIBRE — SANS MISSION' DOIT recevoir un ordre ce cycle.\n"
                "  → PROCESSUS OBLIGATOIRE à chaque cycle :\n"
                "     a) Lire la liste 'GROUPES SANS MISSION' dans le rapport.\n"
                "     b) Assigner une mission concrète à CHACUN d'eux (attaque, défense, recon, embuscade...).\n"
                "     c) Seulement ensuite : ajuster les groupes déjà en mission si nécessaire.\n"
                "  → INTERDICTION ABSOLUE de rester spectateur : si tu vois des groupes libres et n'émet pas\n"
                "     d'ordre pour eux, tu as FAILLI à ton rôle de commandant.\n"
                "\n"
                "  3. Sous-missions autorisées : recon préalable, fixation, flanquement, garnison après conquête.\n"
                "  4. RENFORTS (renfort_terrestre, insertion, appui_helico) — SEULEMENT si :\n"
                "     → TOUS tes groupes existants ont déjà une mission en cours ET\n"
                "     → Tu as demandé et obtenu l'autorisation du Général via demander_joueur()\n"
                "     → Sans autorisation = ces outils sont bloqués. Travaille avec ce que tu as.\n"
                "  5. AUTONOMIE TACTIQUE TOTALE — Tu décides seul : manœuvres, pertes, repli.\n"
                "     Tu ne demandes jamais 'Dois-je attaquer ?' ou 'Que faire ?' — tu AGIS.\n"
                "  6. DÉFAITE : si forces à ZÉRO → informer le Général via demander_joueur().\n"
                "  7. Un groupe sans ordre = ressource gaspillée = défaite par inaction.\n\n"
                "FORMAT DE RÉPONSE OBLIGATOIRE :\n"
                "  Commence TOUJOURS ton texte par : INTENTION: [une phrase courte, max 80 caractères]\n"
                "  Cette phrase s'affiche sur le panneau tactique du Général — elle doit être claire et humaine.\n"
                "  Exemples : 'Encerclement du village par l'est pendant fixation frontale'\n"
                "             'QRF nord + insertion helico au flanc ouest'\n"
                "             'Consolidation defensive en attendant les renforts'\n"
                "             'Harcèlement sur les axes puis repli vers les hauteurs'\n"
                "  Ensuite seulement : ton analyse et tes ordres."
            ),
            "cache_control": {"type": "ephemeral"}
        })

    # ── Message utilisateur courant ────────────────────────
    tactical = build_tactical_update(trigger)
    if _pending_tool_res:
        user_content = _pending_tool_res + [{"type": "text", "text": tactical}]
    else:
        user_content = tactical

    user_msg  = {"role": "user", "content": user_content}
    messages  = _history + [user_msg]

    def _api_call(msgs):
        return client.messages.create(
            model=MODEL, max_tokens=4096, system=system,
            tools=TOOLS, tool_choice={"type": "any"},
            messages=msgs,
        )

    try:
        resp = _api_call(messages)
    except Exception as e:
        err = str(e)
        if "tool_use_id" in err or "tool_result" in err:
            log.warning("tool_results orphelins — reset historique et retry")
            _history.clear()
            _pending_tool_res.clear()
            clean_msg = {"role": "user", "content": build_tactical_update(trigger)}
            try:
                resp = _api_call([clean_msg])
                messages = [clean_msg]
                user_msg = clean_msg
            except Exception as e2:
                log.error(f"Erreur API après reset : {e2}")
                return None
        else:
            log.error(f"Erreur API Claude : {e}")
            _history.clear()
            _pending_tool_res.clear()
            return None

    # ── Extraction raisonnement + ordres ──────────────────
    global _pending_question
    raison_parts    = []
    ordres          = []
    new_tool_res    = []
    question_posee: str = ""
    question_bloquee    = False   # True si au moins une question a été refusée par cooldown

    for block in resp.content:
        if block.type == "text" and block.text.strip():
            raison_parts.append(block.text.strip())
        elif block.type == "tool_use":

            # ── Outil spécial : demander_joueur ─────────────────
            if block.name == "demander_joueur":
                # Cooldown anti-harcèlement — allégé pour demandes de renforts
                cycles_depuis = _cycle_count - _last_question_cycle
                q_text = block.input.get("question", "").lower()
                is_renfort_req = any(kw in q_text for kw in [
                    "renfort", "autorisation", "autoriser", "insertion",
                    "contre_attaque", "occuper", "défaite", "defeat", "permission"
                ])
                cooldown_actif = 3 if is_renfort_req else QUESTION_COOLDOWN_CYCLES
                if cycles_depuis < cooldown_actif:
                    log.warning(
                        f"[QUESTION] Bloquée (cooldown {cycles_depuis}/{cooldown_actif} cycles) "
                        f"— {block.input.get('question','')[:60]}"
                    )
                    question_bloquee = True
                    new_tool_res.append({
                        "type": "tool_result",
                        "tool_use_id": block.id,
                        "content": (
                            f"Question refusée (cooldown {cooldown_actif - cycles_depuis} cycles restants). "
                            "Emets maintenant tes ordres tactiques pour chaque groupe — agis."
                        )
                    })
                    continue

                q   = block.input.get("question", "").strip()
                ctx = block.input.get("contexte", "").strip()
                full_q = f"{q}" + (f" ({ctx})" if ctx else "")
                question_posee    = full_q
                _pending_question = full_q
                _last_question_cycle = _cycle_count
                # Écrire dans question.txt pour que web.py l'affiche
                try:
                    QUESTION_PATH.write_text(full_q, encoding="utf-8")
                except Exception:
                    pass
                log.info(f"[QUESTION] Commandant demande : {full_q}")
                log.warning(f"[HDS_QUESTION]{full_q}")
                new_tool_res.append({
                    "type": "tool_result",
                    "tool_use_id": block.id,
                    "content": (
                        "Question transmise au joueur. Elle s'affiche dans l'interface. "
                        "En attendant sa réponse, continue avec les informations disponibles."
                    )
                })
                continue   # ne pas ajouter à ordres

            # ── Ordres tactiques normaux ─────────────────────────
            ordres.append({"name": block.name, "input": block.input})
            log.info(f"  ORDRE {block.name.upper()}: {block.input}")
            new_tool_res.append({
                "type": "tool_result",
                "tool_use_id": block.id,
                "content": "Ordre transmis."
            })
            # Mémoriser l'ordre par groupe
            gid = block.input.get("groupe_id")
            if gid:
                _group_orders[gid] = block.name

    # ── Relance forcée si question bloquée + aucun ordre ──────────────────
    # Claude n'a émis que demander_joueur (bloqué) sans aucun ordre tactique.
    # On réinjecte le tool_result "refusé" immédiatement pour forcer des ordres.
    if not ordres and question_bloquee:
        log.info("[IA] Question bloquee sans ordres — relance forcee dans le meme cycle")
        retry_user = {
            "role": "user",
            "content": new_tool_res + [{
                "type": "text",
                "text": (
                    "Question refusee par le systeme. "
                    "MAINTENANT : emets tes ordres tactiques — un ordre concret par groupe disponible. "
                    "Ne pose aucune question, ne demande aucune confirmation. AGIS selon la mission permanente."
                )
            }]
        }
        retry_messages = messages + [{"role": "assistant", "content": resp.content}, retry_user]
        try:
            resp_r = _api_call(retry_messages)
            new_tool_res_r = []
            for block in resp_r.content:
                if block.type == "text" and block.text.strip():
                    raison_parts.append(block.text.strip())
                elif block.type == "tool_use":
                    if block.name == "demander_joueur":
                        # Bloqué définitivement pour ce cycle
                        new_tool_res_r.append({
                            "type": "tool_result",
                            "tool_use_id": block.id,
                            "content": "Question definitivement refusee ce cycle. Utilise tes outils tactiques."
                        })
                        continue
                    ordres.append({"name": block.name, "input": block.input})
                    log.info(f"  ORDRE(relance) {block.name.upper()}: {block.input}")
                    new_tool_res_r.append({
                        "type": "tool_result",
                        "tool_use_id": block.id,
                        "content": "Ordre transmis."
                    })
                    gid = block.input.get("groupe_id")
                    if gid:
                        _group_orders[gid] = block.name
            new_tool_res = new_tool_res_r
            resp = resp_r   # historique utilise la dernière réponse
        except Exception as e:
            log.warning(f"Relance forcee echouee : {e}")

    raison = " ".join(raison_parts)
    # Si Claude émet seulement des tool_use sans texte libre → synthétiser un résumé
    if not raison and ordres:
        groups = list(dict.fromkeys(
            o["input"].get("groupe_id", "") for o in ordres if o["input"].get("groupe_id")
        ))
        types  = list(dict.fromkeys(o["name"] for o in ordres))
        raison = f"[{' + '.join(types[:4])}] → {', '.join(groups[:6])}"
    # Toujours logguer — c'est ce que web.py affiche dans "Analyse du commandant"
    log.info(f"[IA] {raison}" if raison else "[IA] (aucun ordre émis)")

    # Extraire la ligne INTENTION: si Claude l'a écrite
    idee = ""
    m_intention = re.search(r'INTENTION\s*:\s*(.+)', raison, re.IGNORECASE)
    if m_intention:
        idee = m_intention.group(1).strip()[:120]
        # Couper à la première fin de ligne
        idee = idee.split('\n')[0].strip()[:120]

    if not idee:
        # Fallback : première phrase du raisonnement
        if raison and not raison.startswith("["):
            sent_end = re.search(r'[.!?]', raison)
            if sent_end:
                idee = raison[:sent_end.end()].strip()[:120]
            else:
                idee = raison.strip()[:120]
    if not idee:
        if ordres:
            idee = " + ".join(list(dict.fromkeys(o["name"] for o in ordres))[:4])
        else:
            idee = "RAS"

    plan = {"raisonnement": raison, "idee_manoeuvre": idee, "question": question_posee}

    # ── Validation des IDs de groupes ──────────────────────────────────────
    # Si Claude a utilisé des IDs qui n'existent pas dans ETAT.opfor,
    # l'historique est contaminé → le purger pour éviter de propager les erreurs.
    if ETAT.opfor:
        ids_invalides = [
            o["input"].get("groupe_id") for o in ordres
            if o["input"].get("groupe_id") and o["input"]["groupe_id"] not in ETAT.opfor
        ]
        if ids_invalides:
            log.warning(
                f"[IA] IDs invalides utilisés : {ids_invalides} "
                f"(valides : {list(ETAT.opfor.keys())}) — historique effacé"
            )
            _history.clear()
            _pending_tool_res.clear()
            return ordres, plan  # retourner quand même les ordres (ils échoueront en SQF)

    # Historique glissant
    _history.append(user_msg)
    _history.append({"role": "assistant", "content": resp.content})
    while len(_history) > MAX_HISTORY_TURNS * 2:
        _history.pop(0)

    _pending_tool_res = new_tool_res
    return ordres, plan


# ═══════════════════════════════════════════════════════════
# ÉCRITURE ORDRES.SQF
# ═══════════════════════════════════════════════════════════

def _p3(p: list) -> str:
    return f"[{int(p[0])},{int(p[1])},{int(p[2]) if len(p) > 2 else 0}]"

def _sqf_str(text: str) -> str:
    """Échappe le texte pour insertion sécurisée dans une chaîne SQF délimitée par guillemets.
    Supprime les non-ASCII (évite l'erreur de parsing Arma sur les caractères UTF-8 larges)."""
    safe = text.replace('"', '""').replace("\n", " ").replace("\r", "")
    # Retirer les caractères hors ASCII-étendu (> 0x7E) que le parseur SQF rejette
    safe = "".join(c if ord(c) < 128 else "_" for c in safe)
    return safe

def _tool_to_sqf(name: str, inp: dict) -> str | None:
    try:
        if name == "repositionner":
            return f'    ["REPOSITIONNER", "{inp["groupe_id"]}", {_p3(inp["position"])}, "{inp.get("comportement","AWARE")}"]'
        if name == "defendre":
            return f'    ["DEFENDRE", "{inp["groupe_id"]}", {_p3(inp["position"])}]'
        if name == "recon":
            return f'    ["RECON", "{inp["groupe_id"]}", {_p3(inp["zone"])}, {int(inp.get("rayon",400))}]'
        if name == "embuscade":
            return f'    ["EMBUSCADE", "{inp["groupe_id"]}", {_p3(inp["position"])}]'
        if name == "attaquer":
            return f'    ["ATTAQUER", "{inp["groupe_id"]}", {_p3(inp["objectif"])}]'
        if name == "embarquer":
            return f'    ["EMBARQUER", "{inp["groupe_id"]}", {_p3(inp["destination"])}]'
        if name == "debarquer":
            return f'    ["DEBARQUER", "{inp["groupe_id"]}", {_p3(inp["position"])}]'
        if name == "qrf":
            return f'    ["QRF", {_p3(inp["position"])}, {int(inp.get("taille_min",3))}, "{inp.get("comportement","COMBAT")}"]'
        if name == "renfort_terrestre":
            return f'    ["RENFORT_TERRESTRE", {_p3(inp["position"])}]'
        if name == "contre_attaque":
            return f'    ["CONTRE_ATTAQUE", "{inp["groupe_id"]}", {_p3(inp["position"])}]'
        if name == "insertion":
            return f'    ["INSERTION", {_p3(inp["position"])}]'
        if name == "occuper":
            return f'    ["OCCUPER", "{inp["groupe_id"]}", {_p3(inp["position"])}]'
        # ── Comportements tactiques avancés ────────────────────
        if name == "mission_attaque":
            gids = "[" + ", ".join(f'"{g}"' for g in inp["groupes_ids"]) + "]"
            return f'    ["MISSION_ATTAQUE", {gids}, {_p3(inp["objectif"])}]'
        if name == "insertion_helico":
            return f'    ["INSERTION_HELICO", "{inp["groupe_id"]}", {_p3(inp["destination"])}]'
        if name == "extraction_helico":
            dest = inp.get("destination") or inp.get("position_sure", [0,0,0])
            return f'    ["EXTRACTION_HELICO", "{inp["groupe_id"]}", {_p3(dest)}]'
        if name == "poste_avance":
            return f'    ["POSTE_AVANCE", "{inp["groupe_id"]}", {_p3(inp["position"])}]'
        if name == "suppression":
            return f'    ["SUPPRESSION", "{inp["groupe_id"]}", {_p3(inp["position_cible"])}]'
        if name == "appui_helico":
            return f'    ["APPUI_HELICO", {_p3(inp["position"])}]'
        if name == "regrouper":
            return f'    ["REGROUPER", "{inp["groupe_id"]}", {_p3(inp["position_ralliement"])}]'
    except (KeyError, IndexError, TypeError) as e:
        log.warning(f"Ordre ignoré ({name}) — champ manquant : {e}")
    return None

# Verrou inter-threads — évite deux écritures simultanées sur ordres.sqf
_ordres_lock = threading.Lock()


def _spread_positions(ordres: list) -> list:
    """
    Détecte les ordres qui envoient plusieurs groupes à la même position (< 150m)
    et applique des offsets tactiques pour les disperser.
    Évite le syndrome "3 groupes sur [8173,10114]".
    """
    POS_FIELDS = {
        "repositionner":    "position",
        "defendre":         "position",
        "recon":            "zone",
        "embuscade":        "position",
        "attaquer":         "objectif",
        "embarquer":        "destination",
        "debarquer":        "position",
        "poste_avance":     "position",
        "suppression":      "position_cible",
        "regrouper":        "position_ralliement",
        "mission_attaque":  "objectif",
        "insertion_helico": "destination",
        "extraction_helico":"destination",
    }
    # Offsets cardinaux puis diagonaux — dispersent en éventail
    OFFSETS = [(0,0), (300,0), (0,300), (-300,0), (0,-300), (250,250), (-250,250), (250,-250)]

    # Construire la liste (index_ordre, champ, position)
    indexed = []
    for i, o in enumerate(ordres):
        field = POS_FIELDS.get(o["name"])
        if field and field in o["input"]:
            p = o["input"][field]
            if isinstance(p, list) and len(p) >= 2:
                indexed.append((i, field, list(p)))

    if len(indexed) < 2:
        return ordres

    # Pour chaque position, trouver si un autre ordre est déjà proche (< 150m)
    # et attribuer un offset incrémental.
    cluster_counter: dict[tuple, int] = {}  # (base_x, base_y) -> nb ordres déjà assignés à ce cluster

    result = [dict(o) for o in ordres]

    for i, field, pos in indexed:
        # Chercher un cluster existant
        base_key = None
        for key in cluster_counter:
            if _dist(list(key), pos[:2]) < 150:
                base_key = key
                break

        if base_key is None:
            # Nouvelle position → premier groupe, pas d'offset
            cluster_counter[(pos[0], pos[1])] = 1
            continue

        # Doublon détecté → appliquer l'offset suivant
        off_idx = cluster_counter[base_key]
        cluster_counter[base_key] += 1
        dx, dy = OFFSETS[off_idx % len(OFFSETS)]

        new_pos = [pos[0] + dx, pos[1] + dy] + (pos[2:] if len(pos) > 2 else [0])
        result[i] = dict(ordres[i])
        result[i]["input"] = dict(ordres[i]["input"])
        result[i]["input"][field] = new_pos

        gid = ordres[i]["input"].get("groupe_id", "?")
        log.info(
            f"[SPREAD] {ordres[i]['name']}({gid}): "
            f"[{int(pos[0])},{int(pos[1])}] -> [{int(new_pos[0])},{int(new_pos[1])}] "
            f"(+{dx},+{dy})"
        )

    return result


def write_ordres(ordres: list, plan: dict) -> None:
    # Disperser les groupes envoyés à la même position
    ordres = _spread_positions(ordres)

    ts    = int(time.time())
    idee  = _sqf_str(plan.get("idee_manoeuvre", "Tenir les positions."))
    raison = _sqf_str(plan.get("raisonnement", ""))
    parts = [l for o in ordres if (l := _tool_to_sqf(o["name"], o["input"])) is not None]

    # Pas de caractères UTF-8 larges dans le fichier SQF (Arma parse en ANSI)
    content = (
        f'hds_ia_cycle_temps = {ts};\n'
        f'hds_ia_dernier_cycle = time;\n'
        f'hds_ia_idee_manoeuvre = "{idee}";\n'
        f'hds_ia_raisonnement = "{raison}";\n'
        f'hds_ia_ordres = [\n'
        + ",\n".join(parts)
        + "\n];"
    )

    ORDRES_PATH.parent.mkdir(parents=True, exist_ok=True)
    log.info(f"ordres.sqf <- {idee[:80]}  ({len(parts)} ordre(s))")

    def _try_write(n: int, delay: float, label: str) -> bool:
        """Tente d'écrire n fois avec delay secondes entre chaque essai."""
        for attempt in range(n):
            try:
                with _ordres_lock:
                    with open(ORDRES_PATH, "w", encoding="ascii", errors="replace") as f:
                        f.write(content)
                if attempt > 0:
                    log.info(f"ordres.sqf ecrit apres {attempt * delay:.1f}s ({label})")
                return True
            except (PermissionError, OSError):
                time.sleep(delay)
        return False

    # Chemin rapide : 5 tentatives × 0.1s = 0.5s (ne bloque presque pas la boucle)
    if _try_write(5, 0.1, "sync"):
        return

    # Chemin différé : thread daemon, 600 tentatives × 0.1s = 60s max
    # Le thread tourne en arrière-plan — la boucle principale continue immédiatement.
    log.warning("ordres.sqf verrouille — ecriture en arriere-plan (max 60s)")

    def _bg_write() -> None:
        if _try_write(600, 0.1, "bg"):
            log.info("ordres.sqf ecrit (arriere-plan)")
        else:
            log.error("ordres.sqf inaccessible 60s — ordres abandonnes")

    threading.Thread(target=_bg_write, daemon=True).start()


# ═══════════════════════════════════════════════════════════
# BOUCLE PRINCIPALE
# ═══════════════════════════════════════════════════════════

def main() -> None:
    log.info("=" * 60)
    log.info("HDS Bridge — Commandant IA  [mil-sim doctrine + tool use]")
    log.info(f"  Modèle   : {MODEL}")
    log.info(f"  RPT dir  : {RPT_DIR}")
    log.info(f"  Doctrine : {read_doctrine()}")
    log.info(f"  Mémoire  : {MAX_HISTORY_TURNS} cycles")
    log.info("=" * 60)

    if API_KEY in ("VOTRE_CLE_API_ICI", ""):
        log.error("Renseigne api_key dans config.json !")
        return

    # Générer bridge\hds_config.sqf — transmet le chemin absolu d'ordres à SQF.
    # SQF lit ce fichier via init-scenario.sqf AVANT que h-init.sqf ne s'initialise.
    ordres_abs = str(ORDRES_PATH).replace("\\", "\\\\")
    hds_config_content = (
        f'// Genere par HDS Bridge - NE PAS EDITER MANUELLEMENT\n'
        f'hds_ia_ordres_path = "{ordres_abs}";\n'
    )
    try:
        HDS_CONFIG_PATH.write_text(hds_config_content, encoding="ascii")
        log.info(f"hds_config.sqf -> {ORDRES_PATH}")
    except OSError as e:
        log.warning(f"hds_config.sqf non écrit : {e} — chemin de repli SQF actif")

    rpt_path: Path | None = None
    rpt_pos = 0

    # Initialiser le mtime directive pour ne pas déclencher au démarrage
    _directive_changed()

    while True:
        latest = find_rpt()
        if latest != rpt_path:
            rpt_path = latest
            if rpt_path:
                file_size = rpt_path.stat().st_size
                # Lire les 2 Mo finaux pour peupler ETAT.opfor depuis l'historique récent.
                # Les triggers retournés sont ignorés — on ne rejoue pas les cycles passés.
                BOOT_WINDOW = 2_000_000
                boot_start = max(0, file_size - BOOT_WINDOW)
                try:
                    with open(rpt_path, "r", encoding="utf-8", errors="replace") as _f:
                        _f.seek(boot_start)
                        _boot_lines = _f.read().splitlines()
                    parse_lines(_boot_lines)   # peuple ETAT.opfor/locs/vehicules — triggers ignorés
                    log.info(
                        f"RPT: {rpt_path.name}  "
                        f"(boot-scan {len(_boot_lines)} lignes — "
                        f"{len(ETAT.opfor)} groupe(s) OPFOR, "
                        f"{len(DISCOVERED_LOCS)} lieu(x) chargés)"
                    )
                except Exception as _e:
                    log.warning(f"RPT: {rpt_path.name}  (boot-scan échoué : {_e})")
                # Seek à la FIN pour la suite — on ne rejoue pas les ordres déjà écrits
                rpt_pos = file_size
            else:
                rpt_pos = 0
                log.warning("Aucun RPT trouvé — Arma lancé ?")
                time.sleep(5)
                continue

        new_lines, rpt_pos = read_new(rpt_path, rpt_pos)

        # ── Réponse / directive : vérifiées AVANT le gate RPT ────────────────
        # Ces triggers doivent partir même si Arma est silencieux (pas de contact).
        trigger = None
        if _reponse_changed():
            reponse_txt = read_reponse()
            if reponse_txt:
                trigger = "REPONSE_JOUEUR"
                dir_actuelle = read_directive()
                reponse_injectee = f"[RÉPONSE À TA QUESTION]: {reponse_txt}"
                if dir_actuelle:
                    DIRECTIVE_PATH.write_text(f"{reponse_injectee}\n\n[DIRECTIVE EN COURS]: {dir_actuelle}", encoding="utf-8")
                else:
                    DIRECTIVE_PATH.write_text(reponse_injectee, encoding="utf-8")
                log.info(f">>> Réponse joueur reçue : {reponse_txt[:80]}")
                # Autorisation renfort : si le joueur dit oui, activer le gate SQF
                _reponse_lower = reponse_txt.lower()
                _autorise = any(w in _reponse_lower for w in ["oui", "ok", "autoris", "accord", "vas-y", "go", "affirm"])
                _refus    = any(w in _reponse_lower for w in ["non", "refuse", "pas", "interdit", "stop"])
                if _autorise and not _refus:
                    # Injecter dans les ordres une mise à jour du flag d'autorisation
                    _auth_snippet = "hds_ia_renforts_autorises = true;\n"
                    try:
                        _cur = ORDRES_PATH.read_text(encoding="ascii", errors="replace")
                        if "hds_ia_renforts_autorises" not in _cur:
                            ORDRES_PATH.write_text(_auth_snippet + _cur, encoding="ascii", errors="replace")
                    except Exception:
                        pass
                    log.info(">>> Renfort AUTORISÉ par le joueur — hds_ia_renforts_autorises = true")
                elif _refus:
                    log.info(">>> Renfort REFUSÉ par le joueur")
        elif _directive_changed():
            trigger = "DIRECTIVE"
            log.info(">>> Nouvelle directive joueur — cycle immédiat")

        # ── Gate RPT : skip si rien à lire ET aucun trigger prioritaire ──────
        if not new_lines and trigger is None:
            time.sleep(1)
            continue

        # ── Triggers RPT (contact, cycle stratégique, pertes) ────────────────
        triggers: list[str] = []
        if new_lines:
            triggers = parse_lines(new_lines)
            # Purger les groupes disparus (non vus depuis 3 minutes = probablement détruits)
            ETAT.purge_stale(max_age_s=180)

        if trigger is None:
            if "CYCLE_IA" in triggers:
                trigger = "CYCLE_IA"
            elif "CYCLE_STRATEGIQUE" in triggers:
                trigger = "CYCLE_STRATEGIQUE"
            elif ETAT.pertes and (not hasattr(main, "_last_perte") or time.time() - main._last_perte > 60):  # type: ignore
                trigger = "PERTES"
                main._last_perte = time.time()  # type: ignore

        if trigger is None:
            time.sleep(0.5)
            continue

        # GARDE-FOU : ne jamais appeler Claude sans données OPFOR
        # Sans positions réelles, Claude invente des group IDs qui n'existent pas en jeu.
        # On attend jusqu'à 90s que le RPT livre au moins une ligne OPFOR_POS.
        if not ETAT.opfor:
            log.warning(f">>> Trigger '{trigger}' — aucune position OPFOR, attente des données RPT (max 90s)...")
            _wait_start = time.time()
            while not ETAT.opfor and time.time() - _wait_start < 90:
                time.sleep(2)
                if rpt_path:
                    _extra, rpt_pos = read_new(rpt_path, rpt_pos)
                    if _extra:
                        parse_lines(_extra)
            if not ETAT.opfor:
                # CYCLE_IA / PERTES sans données = probablement Arma pas démarré → annuler
                # DIRECTIVE / CYCLE_STRATEGIQUE = planification sans contact → laisser passer
                if trigger in ("CYCLE_IA", "PERTES"):
                    log.warning(f">>> {trigger} annulé — toujours aucune donnée OPFOR après 90s (Arma démarré ?)")
                    continue
                else:
                    log.warning(f">>> {trigger} — aucune donnée OPFOR, cycle lancé quand même (planification sans contact)")
            else:
                log.info(f">>> Données OPFOR reçues ({len(ETAT.opfor)} groupe(s)) — cycle Claude lancé")

        log.info(f">>> Déclencheur : {trigger} | Phase: {ETAT.phase()} | Doctrine: {read_doctrine()}")
        result = call_claude(trigger)
        if result:
            ordres, plan = result
            if ordres:
                write_ordres(ordres, plan)
            else:
                log.info(f"Claude -> RAS ({plan.get('idee_manoeuvre','')}) — aucun ordre émis")
            ETAT.pertes.clear()

        time.sleep(5)


if __name__ == "__main__":
    main()
