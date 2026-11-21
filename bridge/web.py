#!/usr/bin/env python3
"""
HDS — Interface web de contrôle du bridge
Lancement : python web.py  →  http://localhost:5150
"""

import sys, os, re, threading, collections, subprocess
from http.server import HTTPServer, BaseHTTPRequestHandler
from pathlib import Path
import json

# ─── État global ───────────────────────────────────────────

bridge_proc  = None
bridge_logs  = collections.deque(maxlen=300)
bridge_lock  = threading.Lock()

last_decision = {"idee": "—", "raisonnement": "—", "type": "—", "heure": "—"}

# Statut live de chaque groupe OPFOR (parsé depuis logs bridge)
opfor_status: dict[str, dict] = {}

# Question en attente du commandant (posée via demander_joueur)
current_question: str = ""

BRIDGE_DIR     = Path(__file__).parent
DIRECTIVE_PATH = BRIDGE_DIR / "directive.txt"
DOCTRINE_PATH  = BRIDGE_DIR / "doctrine.txt"
QUESTION_PATH  = BRIDGE_DIR / "question.txt"
REPONSE_PATH   = BRIDGE_DIR / "reponse.txt"
ORDRES_PATH    = BRIDGE_DIR.parent / "hdssystem" / "modules" / "commandant-ia" / "ordres.sqf"

ORDRES_VIDE = (
    'hds_ia_cycle_temps = -1;\n'
    'hds_ia_idee_manoeuvre = "En attente.";\n'
    'hds_ia_raisonnement = "";\n'
    'hds_ia_ordres = [];\n'
)

DOCTRINES_LIST = ["HYBRIDE", "AGRESSIVE", "DEFENSIVE", "GUERRILLA"]

# BUG FIX : (.+?) au lieu de (\S+) — les group IDs contiennent des espaces ("Alpha 1-1")
_OPFOR_POS_RE   = re.compile(
    r"\[HDS\]\[OPFOR_POS\] (.+?) @ \[(\d+),(\d+)\] (\d+)h (veh=\S+)"
    r"(?:\s+dispo=\d+)?(?:\s+b=(\w+))?(?:\s+inv=([TF]))?(?:\s+gar=([TF]))?(?:\s+wp=(\d+))?"
)
_ORDER_RE       = re.compile(r"ORDRE (\w+): \{.*?'groupe_id'.*?: '([^']+)'")


# ─── Helpers ───────────────────────────────────────────────

def _extract_time(line: str) -> str:
    parts = line.split()
    return parts[0] if parts else "—"

def get_directive() -> str:
    try:    return DIRECTIVE_PATH.read_text(encoding="utf-8").strip()
    except: return ""

def set_directive(text: str) -> None:
    DIRECTIVE_PATH.write_text(text.strip(), encoding="utf-8")

def get_doctrine() -> str:
    try:
        t = DOCTRINE_PATH.read_text(encoding="utf-8").strip().upper()
        return t if t in DOCTRINES_LIST else "HYBRIDE"
    except:
        return "HYBRIDE"

def set_doctrine(text: str) -> None:
    t = text.strip().upper()
    DOCTRINE_PATH.write_text(t if t in DOCTRINES_LIST else "HYBRIDE", encoding="utf-8")


# ─── Lecture output bridge ──────────────────────────────────

def read_output(proc):
    """Thread : lit stdout du bridge, parse et enrichit l'état global."""
    global last_decision, opfor_status, current_question

    for raw in proc.stdout:
        line = raw.decode("utf-8", errors="ignore").rstrip()

        # ── Logs console ──
        with bridge_lock:
            bridge_logs.append(line)

            # Raisonnement Claude
            if "] INFO  [IA] " in line:
                last_decision["raisonnement"] = line.split("] INFO  [IA] ", 1)[-1].strip()
                last_decision["heure"]        = _extract_time(line)

            # Ordres écrits
            elif "ordres.sqf <-" in line:
                part = line.split("ordres.sqf <- ", 1)[-1]
                last_decision["idee"]  = part.split("(")[0].strip()
                last_decision["type"]  = "ORDRES"
                last_decision["heure"] = _extract_time(line)

            # RAS
            elif "Claude -> RAS" in line:
                last_decision["idee"]  = line.split("RAS (", 1)[-1].split(")")[0] if "RAS (" in line else "RAS"
                last_decision["type"]  = "RAS"
                last_decision["heure"] = _extract_time(line)

            # Question du commandant → stocker pour affichage web
            elif "[HDS_QUESTION]" in line:
                q = line.split("[HDS_QUESTION]", 1)[-1].strip()
                current_question = q
                last_decision["type"] = "QUESTION"

        # ── Statut OPFOR (position + véhicule + contexte tactique depuis RPT) ──
        m = _OPFOR_POS_RE.search(line)
        if m:
            gid = m.group(1)
            pos = [int(m.group(2)), int(m.group(3))]
            eff = int(m.group(4))
            veh_raw = m.group(5)
            vm = re.match(r"veh=(\d+)(?:\((\w+)\))?", veh_raw)
            veh_str = "à pied"
            if vm and int(vm.group(1)) > 0:
                veh_str = f"veh={vm.group(1)} {vm.group(2) or '?'}"
            # Contexte tactique temps réel
            behav = m.group(6) or "?"
            inv   = m.group(7) == "T" if m.group(7) else False
            gar   = m.group(8) == "T" if m.group(8) else False
            wp    = int(m.group(9)) if m.group(9) else 0

            # Statut basé sur la réalité : waypoints actifs = en mission, pas juste le mode behaviour
            # wp > 1  = a des waypoints a executer = EN MISSION
            # gar     = en garnison fixe
            # inv     = dans un vehicule en transit
            # behav COMBAT + wp > 1 = approche combat ou engagement
            # behav COMBAT + wp <= 1 = en alerte (contact recent)
            if   gar:                        etat = "🏠 GARNISON"
            elif inv and wp > 1:             etat = "🚗 EN TRANSIT"
            elif inv:                        etat = "🚗 MONTE"
            elif behav == "COMBAT" and wp > 1: etat = "✖ EN COMBAT"
            elif behav == "COMBAT":          etat = "⚠ ALERTE"
            elif behav == "AWARE" and wp > 1: etat = "👁 EN MOUVEMENT"
            elif behav == "SAFE"  and wp > 1: etat = "👣 EN DÉPLACEMENT"
            elif behav == "AWARE":           etat = "👁 EN VIGILANCE"
            else:                            etat = "💤 STATIQUE"

            with bridge_lock:
                if gid not in opfor_status:
                    opfor_status[gid] = {}
                opfor_status[gid].update({
                    "pos": pos, "eff": eff, "veh": veh_str,
                    "behav": behav, "inv": inv, "gar": gar, "wp": wp, "etat": etat,
                })

        # ── Ordres individuels par groupe ──
        m2 = _ORDER_RE.search(line)
        if m2:
            order_type, gid = m2.group(1), m2.group(2)
            with bridge_lock:
                if gid not in opfor_status:
                    opfor_status[gid] = {}
                opfor_status[gid]["last_order"] = order_type
                opfor_status[gid]["order_time"] = _extract_time(line)


# ─── HTML ──────────────────────────────────────────────────

HTML = r"""<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>HDS — Commandant IA</title>
<style>
* { box-sizing: border-box; margin: 0; padding: 0; }
body {
  background:#0d1117; color:#c9d1d9;
  font-family:'Segoe UI',system-ui,sans-serif;
  min-height:100vh; display:flex; flex-direction:column;
  align-items:center; padding:32px 16px; gap:20px;
}
header { display:flex; align-items:center; gap:14px; width:100%; max-width:920px; }
header h1 { font-size:1.4rem; font-weight:700; color:#f0f6fc; letter-spacing:1px; }
header .sub { font-size:0.78rem; color:#8b949e; margin-top:2px; }

.status-pill {
  display:inline-flex; align-items:center; gap:8px; padding:5px 14px;
  border-radius:999px; font-size:0.8rem; font-weight:600; letter-spacing:0.5px;
  transition:all 0.3s; margin-left:auto;
}
.status-pill.running { background:#0d3321; color:#3fb950; border:1px solid #238636; }
.status-pill.stopped { background:#2d1515; color:#f85149; border:1px solid #6e2020; }
.status-dot { width:8px; height:8px; border-radius:50%; }
.running .status-dot { background:#3fb950; animation:pulse 1.5s infinite; }
.stopped .status-dot { background:#f85149; }
@keyframes pulse { 0%,100%{opacity:1}50%{opacity:0.4} }

.card {
  background:#161b22; border:1px solid #30363d; border-radius:12px;
  padding:20px 24px; width:100%; max-width:920px;
}
.card-title {
  font-size:0.72rem; text-transform:uppercase; letter-spacing:1.2px;
  color:#8b949e; margin-bottom:14px; font-weight:600;
}

.btn-row { display:flex; gap:12px; }
button {
  flex:1; padding:11px 16px; border:none; border-radius:8px;
  font-size:0.9rem; font-weight:700; cursor:pointer;
  transition:opacity 0.2s,transform 0.1s; letter-spacing:0.5px;
}
button:hover  { opacity:0.85; }
button:active { transform:scale(0.97); }
button:disabled { opacity:0.35; cursor:not-allowed; transform:none; }
#btn-start { background:#238636; color:#fff; }
#btn-stop  { background:#6e2020; color:#fff; }
#btn-reset { background:#4a2080; color:#fff; flex:0 0 auto; padding:11px 20px; }

/* Doctrine */
.doctrine-grid { display:grid; grid-template-columns:1fr 1fr; gap:10px; }
@media(max-width:600px){.doctrine-grid{grid-template-columns:1fr;}}
.doc-btn {
  flex:none; display:flex; flex-direction:column; align-items:flex-start; gap:4px;
  padding:14px 16px; background:#1c2128; border:2px solid #30363d;
  border-radius:10px; cursor:pointer; transition:border-color 0.2s,background 0.2s;
  text-align:left; width:100%;
}
.doc-btn:hover { border-color:#388bfd; background:#1e2d40; }
.doc-btn.active { border-color:#388bfd; background:#0d2133; }
.doc-btn .d-name {
  font-size:0.9rem; font-weight:700; color:#f0f6fc;
  display:flex; align-items:center; gap:8px;
}
.doc-btn.active .d-name { color:#58a6ff; }
.doc-btn .d-desc { font-size:0.75rem; color:#8b949e; line-height:1.4; }
.doc-btn .d-badge {
  font-size:0.62rem; padding:2px 8px; border-radius:999px;
  background:#388bfd22; color:#58a6ff; border:1px solid #388bfd55;
  font-weight:700; letter-spacing:0.5px; display:none;
}
.doc-btn.active .d-badge { display:inline-block; }
.doctrine-status { margin-top:10px; font-size:0.75rem; color:#484f58; transition:color 0.4s; }
.doctrine-status.sent { color:#3fb950; }

/* Directive */
.directive-area {
  width:100%; background:#010409; border:1px solid #30363d; border-radius:8px;
  padding:12px 14px; color:#e6c84f; font-family:'Segoe UI',system-ui,sans-serif;
  font-size:0.9rem; line-height:1.55; resize:vertical; min-height:70px;
  transition:border-color 0.2s;
}
.directive-area:focus { outline:none; border-color:#e6c84f; }
.directive-area::placeholder { color:#484f58; font-style:italic; }
.dir-row { display:flex; gap:10px; margin-top:10px; align-items:center; }
.btn-send { background:#c9962a; color:#0d1117; padding:9px 20px; flex:none; font-size:0.9rem; border-radius:8px; font-weight:700; border:none; cursor:pointer; }
.btn-send:hover { opacity:0.85; }
.btn-clear { background:transparent; color:#8b949e; padding:9px 14px; flex:none; font-size:0.9rem; border-radius:8px; font-weight:600; border:1px solid #30363d; cursor:pointer; }
.btn-clear:hover { color:#f85149; border-color:#6e2020; }
.dir-status { font-size:0.75rem; color:#484f58; transition:color 0.5s; margin-left:auto; }
.dir-status.sent { color:#3fb950; }

/* Analyse */
.decision-header { display:flex; align-items:center; gap:12px; margin-bottom:12px; }
.decision-type { padding:3px 12px; border-radius:999px; font-size:0.72rem; font-weight:700; letter-spacing:1px; text-transform:uppercase; }
.decision-type.ordres    { background:#0d3321; color:#3fb950; border:1px solid #238636; }
.decision-type.ras       { background:#1c2128; color:#8b949e; border:1px solid #30363d; }
.decision-type.vide      { background:#1c2128; color:#484f58; border:1px solid #21262d; }
.decision-type.question  { background:#1a1200; color:#e3b341; border:1px solid #e3b34155; animation:pulse 1.5s infinite; }
.decision-idee  { font-size:1rem; font-weight:700; color:#e6c84f; letter-spacing:0.5px; }
.decision-heure { margin-left:auto; font-size:0.72rem; color:#484f58; }
.raisonnement-box {
  background:#010409; border-left:3px solid #388bfd; border-radius:0 8px 8px 0;
  padding:12px 16px; font-size:0.88rem; color:#adbac7; line-height:1.65;
  min-height:52px; font-style:italic;
}

/* Tableau OPFOR */
.opfor-table { width:100%; border-collapse:collapse; font-size:0.82rem; }
.opfor-table th { text-align:left; padding:6px 10px; color:#484f58; font-size:0.68rem; text-transform:uppercase; letter-spacing:0.8px; border-bottom:1px solid #21262d; }
.opfor-table td { padding:8px 10px; border-bottom:1px solid #161b22; }
.opfor-table tr:last-child td { border-bottom:none; }
.opfor-table tr:hover td { background:#1c2128; }
.gid-cell { font-weight:700; color:#f0f6fc; font-family:monospace; font-size:0.85rem; }
.veh-badge { display:inline-block; padding:2px 9px; border-radius:999px; font-size:0.68rem; font-weight:700; letter-spacing:0.4px; }
.veh-land { background:#1a2633; color:#79c0ff; border:1px solid #1f406066; }
.veh-air  { background:#1a2620; color:#7ee787; border:1px solid #1f403066; }
.veh-foot { background:#1c1c1c; color:#484f58; border:1px solid #30363d; }
.order-badge { display:inline-block; padding:2px 9px; border-radius:4px; font-size:0.7rem; font-weight:700; letter-spacing:0.3px; font-family:monospace; }
.ord-DEFENDRE       { background:#0d2a1a; color:#3fb950; }
.ord-RECON          { background:#0d2033; color:#58a6ff; }
.ord-EMBUSCADE      { background:#2a1a0d; color:#e3b341; }
.ord-ATTAQUER       { background:#2d0f0f; color:#f85149; }
.ord-EMBARQUER      { background:#1a1a2d; color:#a371f7; }
.ord-REPOSITIONNER  { background:#1c2128; color:#adbac7; }
.ord-QRF            { background:#2d200d; color:#ffa657; }
.ord-RENFORT_TERRESTRE { background:#2a0d2a; color:#f778ba; }
.ord-INSERTION      { background:#0d2a2a; color:#39c5cf; }
.ord-CONTRE_ATTAQUE { background:#2d1515; color:#f85149; }
.ord-OCCUPER        { background:#1a2d1a; color:#7ee787; }
.ord-none           { color:#484f58; font-style:italic; font-size:0.72rem; font-family:normal; }

/* Question commandant */
.question-card {
  display:none; width:100%; max-width:920px;
  background:#1a1200; border:2px solid #e3b341; border-radius:12px;
  padding:20px 24px; animation:fadeIn 0.4s ease;
}
.question-card.visible { display:block; }
@keyframes fadeIn { from{opacity:0;transform:translateY(-8px)} to{opacity:1;transform:translateY(0)} }
.question-header {
  display:flex; align-items:center; gap:10px; margin-bottom:14px;
}
.question-icon { font-size:1.4rem; }
.question-title { font-size:0.95rem; font-weight:700; color:#e3b341; letter-spacing:0.5px; }
.question-blink {
  width:10px; height:10px; border-radius:50%; background:#e3b341;
  animation:pulse 1s infinite; margin-left:auto;
}
.question-text {
  background:#0d0900; border-left:3px solid #e3b341; border-radius:0 8px 8px 0;
  padding:14px 18px; font-size:0.95rem; color:#f0e6c0; line-height:1.65;
  margin-bottom:16px; font-style:italic;
}
.reponse-area {
  width:100%; background:#010409; border:1px solid #e3b34155; border-radius:8px;
  padding:12px 14px; color:#f0f6fc; font-family:'Segoe UI',system-ui,sans-serif;
  font-size:0.9rem; line-height:1.55; resize:vertical; min-height:60px;
  transition:border-color 0.2s;
}
.reponse-area:focus { outline:none; border-color:#e3b341; }
.reponse-area::placeholder { color:#484f58; font-style:italic; }
.reponse-row { display:flex; gap:10px; margin-top:10px; align-items:center; }
.btn-repondre {
  background:#e3b341; color:#0d1117; padding:9px 22px;
  flex:none; font-size:0.9rem; border-radius:8px; font-weight:700;
  border:none; cursor:pointer; transition:opacity 0.2s;
}
.btn-repondre:hover { opacity:0.85; }
.reponse-status { font-size:0.75rem; color:#484f58; margin-left:auto; transition:color 0.5s; }
.reponse-status.sent { color:#3fb950; }

/* Console */
.console {
  background:#010409; border:1px solid #21262d; border-radius:8px;
  padding:12px; height:300px; overflow-y:auto;
  font-family:'Cascadia Code','Fira Code','Consolas',monospace;
  font-size:0.78rem; line-height:1.6;
}
.line { white-space:pre-wrap; word-break:break-all; }
.line.info    { color:#8b949e; }
.line.success { color:#3fb950; }
.line.warn    { color:#e3b341; }
.line.error   { color:#f85149; }
.line.order   { color:#79c0ff; font-weight:600; }
.line.ia      { color:#adbac7; font-style:italic; border-left:2px solid #388bfd; padding-left:6px; }
.line.ras     { color:#484f58; }

.meta { font-size:0.72rem; color:#484f58; text-align:center; }
</style>
</head>
<body>

<header>
  <div>
    <h1>⚔ HDS — Commandant IA</h1>
    <div class="sub">Bridge Arma 3 ↔ Claude  |  Malden 2035</div>
  </div>
  <div id="pill" class="status-pill stopped">
    <span class="status-dot"></span>
    <span id="pill-label">HORS LIGNE</span>
  </div>
</header>

<!-- Contrôle -->
<div class="card">
  <div class="card-title">Contrôle bridge</div>
  <div class="btn-row">
    <button id="btn-start" onclick="doAction('start')">▶ Démarrer</button>
    <button id="btn-stop"  onclick="doAction('stop')" disabled>■ Arrêter</button>
    <button id="btn-reset" onclick="doReset()">⟳ Reset mission</button>
  </div>
</div>

<!-- Doctrine -->
<div class="card">
  <div class="card-title">Doctrine tactique du commandant</div>
  <div class="doctrine-grid">
    <button class="doc-btn" id="doc-HYBRIDE" onclick="setDoctrine('HYBRIDE')">
      <div class="d-name">⚡ HYBRIDE <span class="d-badge">ACTIF</span></div>
      <div class="d-desc">Adaptation dynamique. Défense en phase passive, attaque aggressive en engagement. Toujours une réserve mobile.</div>
    </button>
    <button class="doc-btn" id="doc-AGRESSIVE" onclick="setDoctrine('AGRESSIVE')">
      <div class="d-name">⚔ AGRESSIVE <span class="d-badge">ACTIF</span></div>
      <div class="d-desc">Chercher et détruire. QRF immédiat à chaque contact, occuper toutes les zones vides, pression constante sur BLUFOR.</div>
    </button>
    <button class="doc-btn" id="doc-DEFENSIVE" onclick="setDoctrine('DEFENSIVE')">
      <div class="d-name">🛡 DÉFENSIVE <span class="d-badge">ACTIF</span></div>
      <div class="d-desc">Défense en profondeur. Garnisons sur Kavala/Montignac/La Trinité, réserve mobile, contre-attaque dès une perte.</div>
    </button>
    <button class="doc-btn" id="doc-GUERRILLA" onclick="setDoctrine('GUERRILLA')">
      <div class="d-name">🌿 GUÉRILLA <span class="d-badge">ACTIF</span></div>
      <div class="d-desc">Harcèlement et mobilité. Embuscades sur D14/D18, repositionnement constant, jamais deux fois au même endroit.</div>
    </button>
  </div>
  <div class="doctrine-status" id="doctrine-status">—</div>
</div>

<!-- Directive -->
<div class="card">
  <div class="card-title">Directive joueur (priorité absolue)</div>
  <textarea id="directive" class="directive-area"
    placeholder="Ex : Renforce immédiatement Kavala avec deux groupes motorisés. Place des embuscades sur D14 au sud de Montignac. Tiens La Trinité coûte que coûte..."></textarea>
  <div class="dir-row">
    <button class="btn-send" onclick="sendDirective()">📡 Transmettre</button>
    <button class="btn-clear" onclick="clearDirective()">Effacer</button>
    <span class="dir-status" id="dir-status">Pas de directive active</span>
  </div>
</div>

<!-- Analyse commandant -->
<div class="card">
  <div class="card-title">Analyse du commandant IA</div>
  <div class="decision-header">
    <span class="decision-type vide" id="decision-type">—</span>
    <span class="decision-idee" id="decision-idee">En attente du premier cycle...</span>
    <span class="decision-heure" id="decision-heure">—</span>
  </div>
  <div class="raisonnement-box" id="raisonnement">Le commandant analyse la situation...</div>
</div>

<!-- Question commandant IA -->
<div class="question-card" id="question-card">
  <div class="question-header">
    <span class="question-icon">📢</span>
    <span class="question-title">LE COMMANDANT VOUS POSE UNE QUESTION</span>
    <span class="question-blink"></span>
  </div>
  <div class="question-text" id="question-text">...</div>
  <textarea id="reponse-input" class="reponse-area"
    placeholder="Votre réponse au commandant..."></textarea>
  <div class="reponse-row">
    <button class="btn-repondre" onclick="envoyerReponse()">📡 Répondre</button>
    <button class="btn-clear" onclick="document.getElementById('reponse-input').value=''">Effacer</button>
    <span class="reponse-status" id="reponse-status"></span>
  </div>
</div>

<!-- Forces OPFOR -->
<div class="card">
  <div class="card-title">État des forces OPFOR</div>
  <table class="opfor-table">
    <thead>
      <tr>
        <th>Groupe</th><th>Effectif</th><th>Mobilité</th><th>Position</th><th>État</th><th>Mission en cours</th>
      </tr>
    </thead>
    <tbody id="opfor-tbody">
      <tr><td colspan="6" style="color:#484f58;text-align:center;padding:20px;">
        En attente des positions OPFOR (premier cycle ~30s)...
      </td></tr>
    </tbody>
  </table>
</div>

<!-- Console -->
<div class="card">
  <div class="card-title">Console bridge</div>
  <div class="console" id="console"></div>
</div>

<div class="meta">Rafraîchissement toutes les 2s</div>

<script>
let lastLogCount = 0;
let autoScroll   = true;
let curDoctrine  = "";

const con = document.getElementById('console');
con.addEventListener('scroll', () => {
  autoScroll = con.scrollTop + con.clientHeight >= con.scrollHeight - 20;
});

function classifyLine(l) {
  if (l.includes('ERROR') || l.includes('Erreur'))      return 'error';
  if (l.includes('[IA] '))                               return 'ia';
  if (l.includes('Claude -> RAS'))                       return 'ras';
  if (l.includes('ordres.sqf') || l.includes('ORDRE ')) return 'order';
  if (l.includes('WARNING') || l.includes('Aucun'))     return 'warn';
  if (l.includes('Bridge') || l.includes('RPT') || l.includes('▶') || l.includes('démarré')) return 'success';
  return 'info';
}

function vehBadge(v) {
  if (!v || v === 'à pied')        return '<span class="veh-badge veh-foot">à pied</span>';
  if (v.includes('air'))           return `<span class="veh-badge veh-air">${v}</span>`;
  return `<span class="veh-badge veh-land">${v}</span>`;
}

function etatBadge(e) {
  if (!e) return '<span style="color:#484f58">—</span>';
  if (e.includes('COMBAT'))    return `<span style="color:#f85149;font-weight:700;font-size:0.8rem">${e}</span>`;
  if (e.includes('GARNISON'))  return `<span style="color:#3fb950;font-size:0.8rem">${e}</span>`;
  if (e.includes('TRANSIT'))   return `<span style="color:#79c0ff;font-size:0.8rem">${e}</span>`;
  if (e.includes('MOUVEMENT')) return `<span style="color:#adbac7;font-size:0.8rem">${e}</span>`;
  if (e.includes('STATIQUE'))  return `<span style="color:#e3b341;font-weight:600;font-size:0.8rem">${e}</span>`;
  return `<span style="color:#484f58;font-size:0.8rem">${e}</span>`;
}

function orderBadge(o) {
  if (!o) return '<span class="ord-none">—</span>';
  return `<span class="order-badge ord-${o}">${o}</span>`;
}

function refreshDoctrine(doc) {
  if (doc === curDoctrine) return;
  curDoctrine = doc;
  ['HYBRIDE','AGRESSIVE','DEFENSIVE','GUERRILLA'].forEach(d => {
    document.getElementById('doc-'+d).classList.toggle('active', d === doc);
  });
  document.getElementById('doctrine-status').textContent = 'Doctrine active : ' + doc;
  document.getElementById('doctrine-status').className = 'doctrine-status sent';
}

async function setDoctrine(doc) {
  await fetch('/doctrine', {
    method:'POST', headers:{'Content-Type':'text/plain; charset=utf-8'}, body:doc
  });
  refreshDoctrine(doc);
}

async function poll() {
  try {
    const r = await fetch('/status');
    const d = await r.json();

    // Pill
    const pill = document.getElementById('pill');
    pill.className = 'status-pill ' + (d.running ? 'running' : 'stopped');
    document.getElementById('pill-label').textContent = d.running ? 'EN LIGNE' : 'HORS LIGNE';
    document.getElementById('btn-start').disabled = d.running;
    document.getElementById('btn-stop').disabled  = !d.running;

    // Doctrine
    if (d.doctrine) refreshDoctrine(d.doctrine);

    // Analyse
    if (d.decision) {
      const dec = d.decision;
      const tEl = document.getElementById('decision-type');
      if (dec.type==='ORDRES')   { tEl.textContent='▶ Ordres émis'; tEl.className='decision-type ordres'; }
      else if (dec.type==='RAS') { tEl.textContent='— RAS'; tEl.className='decision-type ras'; }
      else if (dec.type==='QUESTION') { tEl.textContent='❓ Question'; tEl.className='decision-type question'; }
      else { tEl.textContent='—'; tEl.className='decision-type vide'; }
      if (dec.idee && dec.idee!=='—') document.getElementById('decision-idee').textContent = dec.idee;
      if (dec.heure && dec.heure!=='—') document.getElementById('decision-heure').textContent = dec.heure;
      if (dec.raisonnement && dec.raisonnement!=='—') {
        document.getElementById('raisonnement').textContent = dec.raisonnement;
      }
    }

    // Question commandant
    const qCard = document.getElementById('question-card');
    const qText = document.getElementById('question-text');
    if (d.question && d.question.trim()) {
      qText.textContent = d.question;
      qCard.classList.add('visible');
    } else {
      qCard.classList.remove('visible');
    }

    // Directive
    const ds = document.getElementById('dir-status');
    if (d.directive) { ds.textContent='✔ Directive active'; ds.className='dir-status sent'; }
    else             { ds.textContent='Pas de directive active'; ds.className='dir-status'; }

    // Forces OPFOR
    if (d.opfor && Object.keys(d.opfor).length > 0) {
      const rows = Object.entries(d.opfor).sort(([a],[b])=>a.localeCompare(b)).map(([gid, info]) => {
        const eff = info.eff ? info.eff+'h' : '?';
        const pos = info.pos ? `[${info.pos[0]},${info.pos[1]}]` : '—';
        return `<tr>
          <td class="gid-cell">${gid}</td>
          <td style="color:#adbac7">${eff}</td>
          <td>${vehBadge(info.veh)}</td>
          <td style="font-family:monospace;color:#8b949e;font-size:0.78rem">${pos}</td>
          <td>${etatBadge(info.etat)}</td>
          <td>${orderBadge(info.last_order)}</td>
        </tr>`;
      }).join('');
      document.getElementById('opfor-tbody').innerHTML = rows;
    }

    // Console
    if (d.logs.length > lastLogCount) {
      d.logs.slice(lastLogCount).forEach(line => {
        const el = document.createElement('div');
        el.className = 'line ' + classifyLine(line);
        el.textContent = line;
        con.appendChild(el);
      });
      lastLogCount = d.logs.length;
      if (autoScroll) con.scrollTop = con.scrollHeight;
    }
  } catch(e) {}
}

async function doAction(action) {
  document.getElementById('btn-start').disabled = true;
  document.getElementById('btn-stop').disabled  = true;
  try { await fetch('/'+action, {method:'POST'}); } catch(e) {}
  setTimeout(poll, 500);
}

async function doReset() {
  if (!confirm('Reset la mission ?\n• Vider ordres.sqf\n• Effacer contacts/pertes\n• Redémarrer le bridge')) return;
  const btn = document.getElementById('btn-reset');
  btn.disabled = true; btn.textContent = '⟳ Reset...';
  lastLogCount = 0;
  document.getElementById('console').innerHTML = '';
  document.getElementById('opfor-tbody').innerHTML = '<tr><td colspan="6" style="color:#484f58;text-align:center">Reset...</td></tr>';
  document.getElementById('decision-idee').textContent = 'Reset en cours...';
  try { await fetch('/reset', {method:'POST'}); } catch(e) {}
  setTimeout(() => { btn.disabled = false; btn.textContent = '⟳ Reset mission'; poll(); }, 1200);
}

async function sendDirective() {
  const txt = document.getElementById('directive').value;
  await fetch('/directive', {
    method:'POST', headers:{'Content-Type':'text/plain; charset=utf-8'}, body:txt
  });
  const s = document.getElementById('dir-status');
  s.textContent = '✔ Directive transmise !'; s.className = 'dir-status sent';
  setTimeout(poll, 300);
}

async function clearDirective() {
  document.getElementById('directive').value = '';
  await fetch('/directive', {
    method:'POST', headers:{'Content-Type':'text/plain; charset=utf-8'}, body:''
  });
  document.getElementById('dir-status').textContent = 'Directive effacée';
  document.getElementById('dir-status').className   = 'dir-status';
}

async function envoyerReponse() {
  const txt = document.getElementById('reponse-input').value.trim();
  if (!txt) return;
  const btn = document.querySelector('.btn-repondre');
  btn.disabled = true; btn.textContent = '⏳ Envoi...';
  await fetch('/reponse', {
    method:'POST', headers:{'Content-Type':'text/plain; charset=utf-8'}, body:txt
  });
  const s = document.getElementById('reponse-status');
  s.textContent = '✔ Réponse transmise !'; s.className = 'reponse-status sent';
  document.getElementById('reponse-input').value = '';
  document.getElementById('question-card').classList.remove('visible');
  setTimeout(() => { btn.disabled = false; btn.textContent = '📡 Répondre'; s.textContent = ''; s.className = 'reponse-status'; }, 3000);
  setTimeout(poll, 400);
}

poll();
setInterval(poll, 2000);
</script>
</body>
</html>
"""


# ─── Serveur HTTP ───────────────────────────────────────────

class Handler(BaseHTTPRequestHandler):

    def log_message(self, *a): pass

    def send_json(self, data, code=200):
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", len(body))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/":
            body = HTML.encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", len(body))
            self.end_headers()
            self.wfile.write(body)

        elif self.path == "/status":
            running = bridge_proc is not None and bridge_proc.poll() is None
            with bridge_lock:
                logs       = list(bridge_logs)
                decision   = dict(last_decision)
                opfor_snap = {gid: dict(info) for gid, info in opfor_status.items()}
                q          = current_question
            # Lire aussi question.txt si existant (persistance entre redémarrages)
            if not q:
                try:
                    q = QUESTION_PATH.read_text(encoding="utf-8").strip()
                except Exception:
                    q = ""
            self.send_json({
                "running":   running,
                "logs":      logs,
                "decision":  decision,
                "directive": get_directive(),
                "doctrine":  get_doctrine(),
                "opfor":     opfor_snap,
                "question":  q,
            })

        else:
            self.send_response(404); self.end_headers()

    def do_POST(self):
        global bridge_proc, last_decision, opfor_status

        length = int(self.headers.get("Content-Length", 0))
        body   = self.rfile.read(length).decode("utf-8", errors="replace") if length else ""

        if self.path == "/start":
            if bridge_proc is None or bridge_proc.poll() is not None:
                try: import importlib; importlib.import_module("anthropic")
                except ImportError:
                    with bridge_lock: bridge_logs.append("⏳ Installation de 'anthropic'...")
                    subprocess.check_call(
                        [sys.executable, "-m", "pip", "install", "anthropic"],
                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
                    )
                bridge_proc = subprocess.Popen(
                    [sys.executable, "-u", "main.py"],
                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                    cwd=str(BRIDGE_DIR),
                )
                threading.Thread(target=read_output, args=(bridge_proc,), daemon=True).start()
                with bridge_lock:
                    bridge_logs.append(f"▶ Bridge démarré  |  Doctrine: {get_doctrine()}")
            self.send_json({"ok": True})

        elif self.path == "/stop":
            if bridge_proc and bridge_proc.poll() is None:
                bridge_proc.terminate()
                with bridge_lock: bridge_logs.append("■ Bridge arrêté")
            self.send_json({"ok": True})

        elif self.path == "/reset":
            if bridge_proc and bridge_proc.poll() is None:
                bridge_proc.terminate()
                try: bridge_proc.wait(timeout=3)
                except: pass
            try: ORDRES_PATH.write_text(ORDRES_VIDE, encoding="utf-8")
            except: pass
            with bridge_lock:
                bridge_logs.clear()
                bridge_logs.append("⟳ Reset — état effacé")
            last_decision.update({"idee":"—","raisonnement":"—","type":"—","heure":"—"})
            with bridge_lock: opfor_status.clear()
            bridge_proc = subprocess.Popen(
                [sys.executable, "-u", "main.py"],
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                cwd=str(BRIDGE_DIR),
            )
            threading.Thread(target=read_output, args=(bridge_proc,), daemon=True).start()
            with bridge_lock:
                bridge_logs.append(f"▶ Bridge redémarré  |  Doctrine: {get_doctrine()}")
            self.send_json({"ok": True})

        elif self.path == "/directive":
            set_directive(body)
            with bridge_lock:
                if body.strip():
                    bridge_logs.append(f"📡 Directive : {body.strip()[:80]}{'...' if len(body.strip())>80 else ''}")
                else:
                    bridge_logs.append("📡 Directive effacée")
            self.send_json({"ok": True})

        elif self.path == "/doctrine":
            doctrine = body.strip().upper()
            if doctrine not in DOCTRINES_LIST: doctrine = "HYBRIDE"
            set_doctrine(doctrine)
            with bridge_lock:
                bridge_logs.append(f"⚙ Doctrine → {doctrine}")
            self.send_json({"ok": True, "doctrine": doctrine})

        elif self.path == "/reponse":
            # Réponse du joueur à une question du commandant
            global current_question
            txt = body.strip()
            if txt:
                try:
                    REPONSE_PATH.write_text(txt, encoding="utf-8")
                except Exception:
                    pass
                with bridge_lock:
                    bridge_logs.append(f"💬 Réponse joueur : {txt[:80]}{'...' if len(txt)>80 else ''}")
                    current_question = ""   # effacer la question affichée
                # Effacer question.txt
                try: QUESTION_PATH.unlink(missing_ok=True)
                except Exception: pass
            self.send_json({"ok": True})

        else:
            self.send_response(404); self.end_headers()


# ─── Main ──────────────────────────────────────────────────

if __name__ == "__main__":
    PORT = 5150
    if not DIRECTIVE_PATH.exists(): DIRECTIVE_PATH.write_text("", encoding="utf-8")
    if not DOCTRINE_PATH.exists():  DOCTRINE_PATH.write_text("HYBRIDE", encoding="utf-8")

    server = HTTPServer(("0.0.0.0", PORT), Handler)
    print()
    print("  ╔═══════════════════════════════════╗")
    print("  ║   HDS — Commandant IA Bridge      ║")
    print(f"  ║   http://localhost:{PORT}         ║")
    print(f"  ║   Doctrine : {get_doctrine():<21}║")
    print("  ╚═══════════════════════════════════╝")
    print("  Ctrl+C pour quitter")
    print()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        if bridge_proc and bridge_proc.poll() is None: bridge_proc.terminate()
        print("\nServeur arrêté.")
