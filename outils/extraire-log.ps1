<#
.SYNOPSIS
    Extrait du RPT d'Arma 3 un petit fichier lisible : les lignes HDS
    et les erreurs d'exécution SQF, regroupées par bloc.

.DESCRIPTION
    Le SQF ne peut pas écrire de fichier. Le seul fichier produit par le
    jeu est son RPT, qui mélange tout : chargement des mods, réseau,
    animations, et au milieu les lignes qui nous intéressent.

    Ce script :
      1. trouve le RPT le plus récent
      2. ne garde que les lignes [HDS] et les erreurs SQF du moteur
      3. reconstitue les BLOCS d'erreur et les dédoublonne

    Le point 3 est le coeur de l'affaire. Une erreur SQF n'est pas une
    ligne mais un bloc de trois :

        Error in expression <...le code fautif...>
          Error position: <...l'endroit exact...>
        File ...\mon-script.sqf..., line 27

    Et Arma réémet le bloc entier à chaque passage. Sur un RPT réel,
    deux bugs produisaient 29 blocs. Dédoublonnés : 2 entrées avec leur
    compte. C'est la différence entre un extrait collable et un mur.

    Un résumé en tête du fichier donne fichier:ligne de chaque erreur
    unique, triées par fréquence.

.PARAMETER DossierRpt
    Où chercher. Par défaut %LOCALAPPDATA%\Arma 3.

.PARAMETER Fichier
    RPT précis à lire, au lieu du plus récent.

.PARAMETER Sortie
    Fichier à écrire. Par défaut logs\hds-<horodatage>.log à la racine
    de la mission.

.PARAMETER DernieresLignes
    Ne lire que la fin du RPT. Utile sur un gros fichier. 0 = tout.

.PARAMETER PressePapier
    Met aussi le résultat dans le presse-papier.

.PARAMETER ErreursSeules
    Écarte les lignes [HDS][INFO] et [HDS][DEBUG].

.PARAMETER Chronologique
    Ne dédoublonne pas : garde l'ordre brut, répétitions comprises.

.EXAMPLE
    .\extraire-log.ps1 -PressePapier
    Extrait tout, écrit le fichier et remplit le presse-papier.

.EXAMPLE
    .\extraire-log.ps1 -ErreursSeules -DernieresLignes 20000
    Les erreurs de la fin du RPT seulement.
#>

[CmdletBinding()]
param(
    [string] $DossierRpt = (Join-Path $env:LOCALAPPDATA 'Arma 3'),
    [string] $Fichier = '',
    [string] $Sortie = '',
    [int]    $DernieresLignes = 0,
    [switch] $PressePapier,
    [switch] $ErreursSeules,
    [switch] $Chronologique
)

$ErrorActionPreference = 'Stop'

# ─── Motifs ────────────────────────────────────────────────────
$motifHds = '\[HDS\]'

# Début d'un bloc d'erreur
$motifDebutErreur = 'Error in expression'

# Lignes qui prolongent un bloc d'erreur
$motifSuiteErreur = 'Error position|Error [A-Z][a-z]|Undefined variable|File .*line \d+'

# Erreurs isolées, qui ne forment pas de bloc
$motifErreurSeule = @(
    'Script .*\.sqf not found',
    'is not a value',
    'Suspending not allowed',
    'No entry .*config\.bin',
    'Cannot load',
    'Warning Message',
    'Error: '
) -join '|'

$motifToutErreur = @($motifDebutErreur, $motifSuiteErreur, $motifErreurSeule) -join '|'

# Horodatage en début de ligne RPT, retiré pour comparer les blocs
$motifHorodatage = '^\s*\d+:\d+:\d+\s*'

# ─── Trouver le RPT ────────────────────────────────────────────
if ($Fichier) {
    if (-not (Test-Path -LiteralPath $Fichier)) { throw "Fichier introuvable : $Fichier" }
    $rpt = Get-Item -LiteralPath $Fichier
} else {
    if (-not (Test-Path -LiteralPath $DossierRpt)) { throw "Dossier RPT introuvable : $DossierRpt" }
    $rpt = Get-ChildItem -LiteralPath $DossierRpt -Filter '*.rpt' |
           Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $rpt) { throw "Aucun .rpt dans $DossierRpt — le jeu a-t-il deja tourne ?" }
}

Write-Host "RPT     : $($rpt.FullName)"
Write-Host "Taille  : $([math]::Round($rpt.Length / 1MB, 2)) Mo"
Write-Host "Modifie : $($rpt.LastWriteTime)"

# ─── Lire, même si le jeu tourne et garde le fichier ouvert ────
$lignes = [System.Collections.Generic.List[string]]::new()
$flux = [System.IO.File]::Open(
    $rpt.FullName, [System.IO.FileMode]::Open,
    [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
try {
    $lecteur = [System.IO.StreamReader]::new($flux)
    try { while ($null -ne ($l = $lecteur.ReadLine())) { $lignes.Add($l) } }
    finally { $lecteur.Dispose() }
} finally { $flux.Dispose() }

$nbLues = $lignes.Count
Write-Host "Lignes  : $nbLues"

if ($DernieresLignes -gt 0 -and $lignes.Count -gt $DernieresLignes) {
    $lignes = $lignes.GetRange($lignes.Count - $DernieresLignes, $DernieresLignes)
    Write-Host "          (limite aux $DernieresLignes dernieres)"
}

# ─── Filtrer ───────────────────────────────────────────────────
$retenues = [System.Collections.Generic.List[string]]::new()
foreach ($l in $lignes) {
    $estErreur = $l -match $motifToutErreur
    $estHds    = $l -match $motifHds
    if ($ErreursSeules) {
        if ($estErreur -or ($estHds -and $l -match '\[(ERREUR|ALERTE)\]')) { $retenues.Add($l) }
    } else {
        if ($estErreur -or $estHds) { $retenues.Add($l) }
    }
}

if ($retenues.Count -eq 0) {
    Write-Host ''
    Write-Host 'Rien a extraire : aucune ligne HDS ni erreur dans ce RPT.' -ForegroundColor Green
    return
}

# ─── Reconstituer les blocs ────────────────────────────────────
# Une entree = soit un bloc d'erreur de plusieurs lignes, soit une
# ligne seule. On dedoublonne ensuite sur l'entree entiere.
$entrees = [System.Collections.Generic.List[hashtable]]::new()
$i = 0
while ($i -lt $retenues.Count) {
    $l = $retenues[$i]

    if ($l -match $motifDebutErreur) {
        $bloc = [System.Collections.Generic.List[string]]::new()
        $bloc.Add($l)
        $j = $i + 1
        # Au plus 5 lignes de suite : au-dela, ce n'est plus un bloc
        while ($j -lt $retenues.Count -and $bloc.Count -lt 5) {
            $suite = $retenues[$j]
            if ($suite -match $motifSuiteErreur) {
                $bloc.Add($suite)
                $j++
                # La ligne File termine le bloc
                if ($suite -match 'File .*line \d+') { break }
            } else { break }
        }
        $entrees.Add(@{ Lignes = $bloc.ToArray(); Erreur = $true })
        $i = $j
    } else {
        $entrees.Add(@{ Lignes = @($l); Erreur = ($l -match $motifToutErreur) })
        $i++
    }
}

# ─── Dédoublonner ──────────────────────────────────────────────
$final = [System.Collections.Generic.List[hashtable]]::new()

if ($Chronologique) {
    foreach ($e in $entrees) { $e.Nb = 1; $final.Add($e) }
} else {
    $vus = [System.Collections.Generic.Dictionary[string, hashtable]]::new()
    foreach ($e in $entrees) {
        $cle = (($e.Lignes | ForEach-Object { $_ -replace $motifHorodatage, '' }) -join '|')
        if ($vus.ContainsKey($cle)) {
            $vus[$cle].Nb++
        } else {
            $e.Nb = 1
            $vus[$cle] = $e
            $final.Add($e)
        }
    }
}

# ─── Résumé des erreurs uniques ────────────────────────────────
$erreursUniques = @($final | Where-Object { $_.Erreur }) | Sort-Object { -$_.Nb }

$resume = [System.Collections.Generic.List[string]]::new()
if ($erreursUniques.Count -gt 0) {
    $resume.Add('----- ERREURS UNIQUES, les plus fréquentes d''abord -----')
    $rang = 0
    foreach ($e in $erreursUniques) {
        $rang++
        $ou = 'origine inconnue'
        $quoi = ''
        foreach ($li in $e.Lignes) {
            if ($li -match 'File (.+?)\.\.\., line (\d+)') {
                $ou = ('{0}  ligne {1}' -f (Split-Path -Leaf $Matches[1]), $Matches[2])
            }
            if ($li -match 'Error position: <(.+)$')     { $quoi = $Matches[1].Trim() }
            elseif ($quoi -eq '' -and $li -match 'Error in expression <(.+)$') { $quoi = $Matches[1].Trim() }
            elseif ($quoi -eq '' -and $li -match ($motifErreurSeule)) { $quoi = ($li -replace $motifHorodatage, '') }
        }
        $resume.Add(('{0,2}. x{1,-5} {2}' -f $rang, $e.Nb, $ou))
        if ($quoi) { $resume.Add(('     -> {0}' -f $quoi)) }
    }
    $resume.Add('')
}

# ─── En-tête ───────────────────────────────────────────────────
$entete = @(
    '===== EXTRAIT RPT HDS =====',
    ("source    : {0}" -f $rpt.Name),
    ("modifie   : {0}" -f $rpt.LastWriteTime),
    ("extrait   : {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')),
    ("lignes    : {0} retenues sur {1} lues" -f $retenues.Count, $nbLues),
    ("entrees   : {0} dont {1} erreur(s) unique(s)" -f $final.Count, $erreursUniques.Count),
    ("filtre    : {0}{1}" -f `
        $(if ($ErreursSeules) { 'erreurs seules' } else { 'HDS + erreurs' }),
        $(if ($Chronologique) { ', ordre brut' } else { ', repetitions regroupees' })),
    '===========================',
    ''
)

# ─── Corps ─────────────────────────────────────────────────────
$corps = [System.Collections.Generic.List[string]]::new()
foreach ($e in $final) {
    $suffixe = if ($e.Nb -gt 1) { ("    <<< x{0} >>>" -f $e.Nb) } else { '' }
    for ($k = 0; $k -lt $e.Lignes.Count; $k++) {
        if ($k -eq ($e.Lignes.Count - 1)) {
            $corps.Add($e.Lignes[$k] + $suffixe)
        } else {
            $corps.Add($e.Lignes[$k])
        }
    }
}

$texte = ($entete + $resume + $corps) -join [Environment]::NewLine

# ─── Écrire ────────────────────────────────────────────────────
if (-not $Sortie) {
    $racine = Split-Path -Parent $PSScriptRoot
    $dossierLogs = Join-Path $racine 'logs'
    if (-not (Test-Path -LiteralPath $dossierLogs)) {
        New-Item -ItemType Directory -Path $dossierLogs -Force | Out-Null
    }
    $Sortie = Join-Path $dossierLogs ("hds-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
}

Set-Content -LiteralPath $Sortie -Value $texte -Encoding utf8

Write-Host ''
Write-Host ("Retenues: {0} lignes -> {1} entrees" -f $retenues.Count, $final.Count)
Write-Host "Ecrit   : $Sortie" -ForegroundColor Green

if ($PressePapier) {
    Set-Clipboard -Value $texte
    Write-Host "Presse-papier rempli." -ForegroundColor Green
}

# ─── Aperçu console ────────────────────────────────────────────
Write-Host ''
if ($erreursUniques.Count -gt 0) {
    Write-Host "$($erreursUniques.Count) erreur(s) unique(s) :" -ForegroundColor Yellow
    $resume | Select-Object -Skip 1 -First 20 | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host 'Aucune erreur dans cet extrait.' -ForegroundColor Green
}
