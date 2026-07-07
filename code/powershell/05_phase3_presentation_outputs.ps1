param(
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$culture = [System.Globalization.CultureInfo]::InvariantCulture
$figureDir = Join-Path $ProjectRoot 'outputs\figures'
$tableDir = Join-Path $ProjectRoot 'outputs\tables'
$modelDir = Join-Path $ProjectRoot 'outputs\models'
$dataPath = Join-Path $ProjectRoot 'data\processed\lac_poverty_informality_social_protection_panel.csv'
New-Item -ItemType Directory -Force -Path $figureDir, $tableDir | Out-Null

function D([object]$x) {
  if ($null -eq $x) { return $null }
  $s = [string]$x
  if ([string]::IsNullOrWhiteSpace($s) -or $s -eq 'NA') { return $null }
  return [double]::Parse($s, $culture)
}

function Fmt([double]$x, [int]$digits = 3) {
  return $x.ToString('F' + $digits, $culture)
}

function HtmlEscape([string]$s) {
  return [System.Net.WebUtility]::HtmlEncode($s)
}

function TexEscape([string]$s) {
  return ($s -replace '\\','\textbackslash{}' -replace '_','\_' -replace '&','\&' -replace '%','\%' -replace '#','\#')
}

function ColorFromHex([string]$hex) {
  $h = $hex.TrimStart('#')
  return [System.Drawing.Color]::FromArgb(
    [Convert]::ToInt32($h.Substring(0,2),16),
    [Convert]::ToInt32($h.Substring(2,2),16),
    [Convert]::ToInt32($h.Substring(4,2),16)
  )
}

function FontObj([float]$size, [string]$style = 'Regular') {
  $fontStyle = [System.Drawing.FontStyle]::$style
  return New-Object System.Drawing.Font('Segoe UI', $size, $fontStyle, [System.Drawing.GraphicsUnit]::Pixel)
}

function DrawText([System.Drawing.Graphics]$g, [string]$text, [float]$x, [float]$y, [float]$size, [string]$hex = '#222222', [string]$style = 'Regular') {
  $font = FontObj $size $style
  $brush = New-Object System.Drawing.SolidBrush((ColorFromHex $hex))
  $g.DrawString($text, $font, $brush, $x, $y)
  $brush.Dispose(); $font.Dispose()
}

function DrawTextRight([System.Drawing.Graphics]$g, [string]$text, [float]$x, [float]$y, [float]$size, [string]$hex = '#222222') {
  $font = FontObj $size 'Regular'
  $brush = New-Object System.Drawing.SolidBrush((ColorFromHex $hex))
  $fmt = New-Object System.Drawing.StringFormat
  $fmt.Alignment = [System.Drawing.StringAlignment]::Far
  $g.DrawString($text, $font, $brush, $x, $y, $fmt)
  $fmt.Dispose(); $brush.Dispose(); $font.Dispose()
}

function DrawTextCenter([System.Drawing.Graphics]$g, [string]$text, [float]$x, [float]$y, [float]$size, [string]$hex = '#222222', [string]$style = 'Regular') {
  $font = FontObj $size $style
  $brush = New-Object System.Drawing.SolidBrush((ColorFromHex $hex))
  $fmt = New-Object System.Drawing.StringFormat
  $fmt.Alignment = [System.Drawing.StringAlignment]::Center
  $g.DrawString($text, $font, $brush, $x, $y, $fmt)
  $fmt.Dispose(); $brush.Dispose(); $font.Dispose()
}

function SavePng([System.Drawing.Bitmap]$bmp, [string]$path) {
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
}

$phase2 = Import-Csv (Join-Path $modelDir 'phase2_twfe_inference_comparison.csv')
$mech = Import-Csv (Join-Path $modelDir 'mechanism_robustness_twfe_comparison.csv')
$joint = Import-Csv (Join-Path $modelDir 'mechanism_robustness_joint_twfe_comparison.csv')

$methodMeta = @(
  [pscustomobject]@{method='Cluster'; se='cluster_std.error'; p='cluster_p.value'; color='#440154'},
  [pscustomobject]@{method='Wild bootstrap'; se='wild_bootstrap_std.error'; p='wild_bootstrap_p.value'; color='#21918c'},
  [pscustomobject]@{method='Driscoll-Kraay'; se='dk_std.error'; p='dk_p.value'; color='#fde725'}
)

$specRows = New-Object System.Collections.Generic.List[object]
function AddSpecCurveRows([string]$variable, [string]$model, [object]$row, [string]$coefficientRole, [string]$termLabel, [string]$sourceFile) {
  if ($null -eq $row) {
    throw "Missing precomputed row for $variable / $model / $termLabel"
  }
  foreach ($m in $methodMeta) {
    $est = D $row.estimate; $se = D $row.($m.se); $p = D $row.($m.p)
    $specRows.Add([pscustomobject]@{
      variable = $variable; model = ($model -replace 'TWFE ', ''); coefficient_role = $coefficientRole; term_label = $termLabel; inference = $m.method
      estimate = $est; std_error = $se; p_value = $p
      ci_low = $est - 1.96 * $se; ci_high = $est + 1.96 * $se
      n_obs = if ($row.PSObject.Properties.Name -contains 'n_obs') { $row.n_obs } else { '' }
      n_countries = if ($row.PSObject.Properties.Name -contains 'n_countries') { $row.n_countries } else { '' }
      color = $m.color; source = $sourceFile
    })
  }
}
foreach ($model in @('TWFE baseline','TWFE interaction')) {
  $term = if ($model -eq 'TWFE baseline') { 'social_protection_coverage' } else { 'labor_informality:social_protection_coverage' }
  $role = if ($model -eq 'TWFE baseline') { 'Main effect' } else { 'Interaction term' }
  $label = if ($model -eq 'TWFE baseline') { 'Social protection coverage' } else { 'Labor informality x social protection' }
  $row = $phase2 | Where-Object { $_.model -eq $model -and $_.term -eq $term } | Select-Object -First 1
  AddSpecCurveRows 'All social protection' $model $row $role $label 'phase2_twfe_inference_comparison.csv'
}
foreach ($variable in @('Social assistance coverage','Social insurance coverage')) {
  foreach ($model in @('TWFE baseline','TWFE interaction')) {
    $termLabel = if ($model -eq 'TWFE baseline') { 'Mechanism coverage' } else { 'Labor informality x mechanism' }
    $role = if ($model -eq 'TWFE baseline') { 'Main effect' } else { 'Interaction term' }
    $shortVariable = ($variable -replace ' coverage','')
    $label = if ($model -eq 'TWFE baseline') { $variable } else { 'Labor informality x ' + $shortVariable.ToLowerInvariant() }
    $row = $mech | Where-Object { $_.mechanism -eq $variable -and $_.model -eq $model -and $_.term_label -eq $termLabel } | Select-Object -First 1
    AddSpecCurveRows $shortVariable $model $row $role $label 'mechanism_robustness_twfe_comparison.csv'
  }
}
$specRowsSorted = @($specRows | Sort-Object estimate, variable, model, inference)
$specRowsSorted | Select-Object variable,model,coefficient_role,term_label,inference,estimate,std_error,p_value,ci_low,ci_high,n_obs,n_countries,source | Export-Csv (Join-Path $figureDir 'phase3_figure_17_specification_curve_data.csv') -NoTypeInformation

# Specification curve plot
$w = 2400; $h = 1600
$bmp = New-Object System.Drawing.Bitmap($w, $h)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
$g.Clear([System.Drawing.Color]::White)
$left = 230; $right = 80; $top = 160; $plotH = 760; $matrixTop = 1010; $matrixH = 390; $bottom = 90
$plotW = $w - $left - $right
DrawText $g 'Specification curve: social protection main effects and interactions' 90 45 42 '#111111' 'Bold'
DrawText $g 'Precomputed TWFE estimates only: baseline rows show main effects; interaction rows show labor-informality interactions' 92 96 24 '#555555'
$allLow = ($specRowsSorted | ForEach-Object { $_.ci_low })
$allHigh = ($specRowsSorted | ForEach-Object { $_.ci_high })
$yMin = [Math]::Floor((($allLow | Measure-Object -Minimum).Minimum - 0.05) * 10) / 10
$yMax = [Math]::Ceiling((($allHigh | Measure-Object -Maximum).Maximum + 0.05) * 10) / 10
if ($yMin -gt -0.8) { $yMin = -0.8 }
if ($yMax -lt 0.4) { $yMax = 0.4 }
function XSpec([int]$i, [int]$n) { return $left + ($i + 0.5) * ($plotW / $n) }
function YSpec([double]$v) { return $top + ($yMax - $v) / ($yMax - $yMin) * $plotH }
$axisPen = New-Object System.Drawing.Pen((ColorFromHex '#333333'), 2)
$gridPen = New-Object System.Drawing.Pen((ColorFromHex '#e6e6e6'), 1)
$zeroPen = New-Object System.Drawing.Pen((ColorFromHex '#555555'), 2)
$zeroPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
for ($tick = $yMin; $tick -le $yMax + 0.0001; $tick += 0.2) {
  $yy = YSpec $tick
  $g.DrawLine($gridPen, $left, $yy, $left + $plotW, $yy)
  DrawTextRight $g (Fmt $tick 1) ($left - 16) ($yy - 13) 21 '#555555'
}
$g.DrawLine($zeroPen, $left, (YSpec 0), $left + $plotW, (YSpec 0))
$g.DrawLine($axisPen, $left, $top, $left, $top + $plotH)
$g.DrawLine($axisPen, $left, $top + $plotH, $left + $plotW, $top + $plotH)
DrawText $g 'Coefficient estimate (95% interval using displayed SE)' 82 125 23 '#333333'
$n = $specRowsSorted.Count
for ($i = 0; $i -lt $n; $i++) {
  $r = $specRowsSorted[$i]
  $x = XSpec $i $n
  $ci1 = YSpec $r.ci_low; $ci2 = YSpec $r.ci_high; $y = YSpec $r.estimate
  $pen = New-Object System.Drawing.Pen((ColorFromHex $r.color), 4)
  $brush = New-Object System.Drawing.SolidBrush((ColorFromHex $r.color))
  $g.DrawLine($pen, $x, $ci1, $x, $ci2)
  $g.DrawLine($pen, $x - 13, $ci1, $x + 13, $ci1)
  $g.DrawLine($pen, $x - 13, $ci2, $x + 13, $ci2)
  $g.FillEllipse($brush, $x - 10, $y - 10, 20, 20)
  $brush.Dispose(); $pen.Dispose()
}
# Legend
$legendX = 1550; $legendY = 55
foreach ($m in $methodMeta) {
  $brush = New-Object System.Drawing.SolidBrush((ColorFromHex $m.color))
  $g.FillEllipse($brush, $legendX, $legendY + 6, 18, 18)
  DrawText $g $m.method ($legendX + 30) $legendY 22 '#333333'
  $legendY += 35
  $brush.Dispose()
}
# matrix
DrawText $g 'Specification matrix' 90 ($matrixTop - 70) 30 '#111111' 'Bold'
$matrixRows = @('All SP','Assistance','Insurance','Main effect','Interaction term','Cluster','Wild','DK')
$rowGap = $matrixH / ($matrixRows.Count + 1)
for ($ridx=0; $ridx -lt $matrixRows.Count; $ridx++) {
  $yy = $matrixTop + ($ridx + 1) * $rowGap
  DrawTextRight $g $matrixRows[$ridx] ($left - 18) ($yy - 14) 22 '#333333'
  $g.DrawLine($gridPen, $left, $yy, $left + $plotW, $yy)
}
for ($i = 0; $i -lt $n; $i++) {
  $r = $specRowsSorted[$i]
  $x = XSpec $i $n
  $g.DrawLine($gridPen, $x, $top, $x, $matrixTop + $matrixH)
  $active = @()
  if ($r.variable -eq 'All social protection') { $active += 'All SP' }
  if ($r.variable -eq 'Social assistance') { $active += 'Assistance' }
  if ($r.variable -eq 'Social insurance') { $active += 'Insurance' }
  if ($r.coefficient_role -eq 'Main effect') { $active += 'Main effect' } else { $active += 'Interaction term' }
  if ($r.inference -eq 'Cluster') { $active += 'Cluster' }
  if ($r.inference -eq 'Wild bootstrap') { $active += 'Wild' }
  if ($r.inference -eq 'Driscoll-Kraay') { $active += 'DK' }
  foreach ($label in $active) {
    $ridx = [Array]::IndexOf($matrixRows, $label)
    $yy = $matrixTop + ($ridx + 1) * $rowGap
    $dotColor = if ($label -in @('Cluster','Wild','DK')) { $r.color } else { '#333333' }
    $brush = New-Object System.Drawing.SolidBrush((ColorFromHex $dotColor))
    $g.FillEllipse($brush, $x - 9, $yy - 9, 18, 18)
    $brush.Dispose()
  }
}
$g.DrawRectangle($axisPen, $left, $matrixTop + 15, $plotW, $matrixH - 10)
DrawText $g 'Sources: phase2_twfe_inference_comparison.csv and mechanism_robustness_twfe_comparison.csv. Estimates are not re-run.' 90 1510 20 '#666666'
$g.Dispose(); SavePng $bmp (Join-Path $figureDir 'phase3_figure_17_specification_curve.png')

# Bolivia timeline
$panel = Import-Csv $dataPath
$auditPath = Join-Path $ProjectRoot 'outputs\data_quality\equity_lab_fallback_audit.csv'
$excludedPoverty = New-Object 'System.Collections.Generic.HashSet[string]'
$exclusionReasons = @{}
if (Test-Path $auditPath) {
  foreach ($a in (Import-Csv $auditPath)) {
    if ($a.decision -like 'exclude:*') {
      $key = $a.iso3 + '|' + [int]$a.year + '|' + $a.variable
      [void]$excludedPoverty.Add($key)
      $exclusionReasons[$key] = $a.decision
    }
  }
}
$bolivia = @($panel | Where-Object { $_.iso3 -eq 'BOL' -and [int]$_.year -ge 2000 -and [int]$_.year -le 2012 } | Sort-Object { [int]$_.year } | ForEach-Object {
  $year = [int]$_.year
  $monKey = 'BOL|' + $year + '|monetary_poverty'
  $extKey = 'BOL|' + $year + '|extreme_poverty'
  $lagKey = 'BOL|' + ($year - 1) + '|monetary_poverty'
  $excludeMonetary = $excludedPoverty.Contains($monKey)
  $excludeExtreme = $excludedPoverty.Contains($extKey)
  $lagFromExcludedYear = $excludedPoverty.Contains($lagKey)
  $monetaryRaw = D $_.monetary_poverty
  $extremeRaw = D $_.extreme_poverty
  $lagRaw = D $_.poverty_lag1
  $moderateWdi = D $_.poverty_moderate_wdi
  $moderateEquity = D $_.poverty_moderate_equity
  $povertySource = if ($null -ne $moderateWdi) { 'WDI' } elseif ($null -ne $moderateEquity) { 'Equity Lab fallback' } else { 'Missing' }
  $monetaryPlot = if ($excludeMonetary) { $null } else { $monetaryRaw }
  $extremePlot = if ($excludeExtreme) { $null } else { $extremeRaw }
  $lagPlot = if ($lagFromExcludedYear) { $null } else { $lagRaw }
  $reason = if ($excludeMonetary) { $exclusionReasons[$monKey] } else { '' }
  $extremeReason = if ($excludeExtreme) { $exclusionReasons[$extKey] } else { '' }
  $lagReason = if ($lagFromExcludedYear) { 'Lagged poverty is derived from an excluded monetary_poverty fallback year.' } else { '' }
  [pscustomobject]@{
    year = $year
    monetary_poverty_raw = $monetaryRaw
    extreme_poverty_raw = $extremeRaw
    poverty_lag1_raw = $lagRaw
    monetary_poverty = $monetaryPlot
    extreme_poverty = $extremePlot
    poverty_lag1 = $lagPlot
    poverty_source = $povertySource
    monetary_poverty_current_excluded = $excludeMonetary
    extreme_poverty_current_excluded = $excludeExtreme
    poverty_lag1_excluded = $lagFromExcludedYear
    monetary_exclusion_reason = $reason
    extreme_exclusion_reason = $extremeReason
    lag_exclusion_reason = $lagReason
    social_assistance_coverage_aspire = D $_.social_assistance_coverage_aspire
  }
})
$bolivia | Export-Csv (Join-Path $figureDir 'phase3_figure_18_bolivia_policy_timeline_data.csv') -NoTypeInformation
$w = 2400; $h = 1450
$bmp = New-Object System.Drawing.Bitmap($w, $h)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
$g.Clear([System.Drawing.Color]::White)
$left = 170; $right = 120; $top = 165; $plotW = $w - $left - $right; $plotH = 940
$xMin = 2000; $xMax = 2012; $yMin = 0; $yMax = 100
function XYear([double]$yr) { return $left + ($yr - $xMin) / ($xMax - $xMin) * $plotW }
function YPct([double]$v) { return $top + ($yMax - $v) / ($yMax - $yMin) * $plotH }
DrawText $g 'Bolivia policy timeline: poverty and social assistance coverage' 90 45 40 '#111111' 'Bold'
DrawText $g 'Country-year panel values; flagged Equity Lab fallback poverty points are shown as missing in the line' 92 96 24 '#555555'
$gridPen = New-Object System.Drawing.Pen((ColorFromHex '#e6e6e6'), 1)
$axisPen = New-Object System.Drawing.Pen((ColorFromHex '#333333'), 2)
for ($tick=0; $tick -le 100; $tick += 10) {
  $yy = YPct $tick
  $g.DrawLine($gridPen, $left, $yy, $left + $plotW, $yy)
  DrawTextRight $g $tick.ToString($culture) ($left - 14) ($yy - 13) 21 '#555555'
}
for ($yr=$xMin; $yr -le $xMax; $yr++) {
  $xx = XYear $yr
  if ($yr % 2 -eq 0) { DrawTextCenter $g $yr.ToString() $xx ($top + $plotH + 22) 21 '#555555' }
  $g.DrawLine($gridPen, $xx, $top, $xx, $top + $plotH)
}
$g.DrawLine($axisPen, $left, $top, $left, $top + $plotH)
$g.DrawLine($axisPen, $left, $top + $plotH, $left + $plotW, $top + $plotH)
DrawText $g 'Percent (%)' 72 133 23 '#333333'
function DrawSeries($rows, $col, $hex, $label, $yLegend) {
  $pen = New-Object System.Drawing.Pen((ColorFromHex $hex), 6)
  $brush = New-Object System.Drawing.SolidBrush((ColorFromHex $hex))
  $last = $null
  foreach ($r in $rows) {
    $val = $r.$col
    if ($null -ne $val) {
      $pt = [pscustomobject]@{x=(XYear $r.year); y=(YPct $val); year=$r.year}
      if ($null -ne $last -and ($r.year - $last.year) -le 1) { $g.DrawLine($pen, $last.x, $last.y, $pt.x, $pt.y) }
      $g.FillEllipse($brush, $pt.x - 10, $pt.y - 10, 20, 20)
      $last = $pt
    } else { $last = $null }
  }
  $g.FillRectangle($brush, 1610, $yLegend + 8, 34, 12)
  DrawText $g $label 1660 $yLegend 24 '#333333'
  $pen.Dispose(); $brush.Dispose()
}
$policyPen = New-Object System.Drawing.Pen((ColorFromHex '#666666'), 3)
$policyPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
foreach ($policy in @([pscustomobject]@{year=2006; label='2006 Bono Juancito Pinto'}, [pscustomobject]@{year=2008; label='2008 Renta Dignidad'})) {
  $xx = XYear $policy.year
  $g.DrawLine($policyPen, $xx, $top, $xx, $top + $plotH)
  DrawTextCenter $g $policy.label $xx ($top - 44) 22 '#333333' 'Bold'
}
DrawSeries $bolivia 'monetary_poverty' '#440154' 'Monetary poverty' 1135
DrawSeries $bolivia 'social_assistance_coverage_aspire' '#21918c' 'Social assistance coverage (ASPIRE)' 1175
DrawText $g 'Note: no microdata are used; excluded fallback points are retained as raw fields and flagged in the backing CSV.' 90 1365 20 '#666666'
$policyPen.Dispose(); $g.Dispose(); SavePng $bmp (Join-Path $figureDir 'phase3_figure_18_bolivia_policy_timeline.png')

# Robustness dashboard
$dashboard = New-Object System.Collections.Generic.List[object]
function AddDashRow([string]$block, [string]$coefficient, [object]$row, [string]$estimateCol = 'estimate') {
  $cluster = D $row.'cluster_p.value'; $wild = D $row.'wild_bootstrap_p.value'; $dk = D $row.'dk_p.value'; $est = D $row.$estimateCol
  $count = 0; foreach ($p in @($cluster,$wild,$dk)) { if ($null -ne $p -and $p -lt 0.05) { $count++ } }
  $class = if ($count -eq 3) { 'Green: 3/3 methods' } elseif ($count -gt 0) { 'Amber: 1-2 methods' } else { 'Red: 0 methods' }
  $dashboard.Add([pscustomobject]@{ block=$block; coefficient=$coefficient; estimate=$est; cluster_p=$cluster; wild_p=$wild; dk_p=$dk; significant_methods=$count; robustness=$class })
}
AddDashRow 'TWFE principal' 'Labor informality' ($phase2 | Where-Object { $_.model -eq 'TWFE baseline' -and $_.term -eq 'labor_informality' } | Select-Object -First 1)
AddDashRow 'TWFE principal' 'Social protection coverage' ($phase2 | Where-Object { $_.model -eq 'TWFE baseline' -and $_.term -eq 'social_protection_coverage' } | Select-Object -First 1)
AddDashRow 'TWFE interaction' 'Labor informality' ($phase2 | Where-Object { $_.model -eq 'TWFE interaction' -and $_.term -eq 'labor_informality' } | Select-Object -First 1)
AddDashRow 'TWFE interaction' 'Social protection coverage' ($phase2 | Where-Object { $_.model -eq 'TWFE interaction' -and $_.term -eq 'social_protection_coverage' } | Select-Object -First 1)
AddDashRow 'TWFE interaction' 'Informality x social protection' ($phase2 | Where-Object { $_.model -eq 'TWFE interaction' -and $_.term -eq 'labor_informality:social_protection_coverage' } | Select-Object -First 1)
foreach ($mechanism in @('Social assistance coverage','Social insurance coverage')) {
  AddDashRow 'Component separate baseline' $mechanism ($mech | Where-Object { $_.mechanism -eq $mechanism -and $_.model -eq 'TWFE baseline' -and $_.term_label -eq 'Mechanism coverage' } | Select-Object -First 1)
  AddDashRow 'Component separate interaction' $mechanism ($mech | Where-Object { $_.mechanism -eq $mechanism -and $_.model -eq 'TWFE interaction' -and $_.term_label -eq 'Mechanism coverage' } | Select-Object -First 1)
  AddDashRow 'Component separate interaction' ('Informality x ' + ($mechanism -replace ' coverage','').ToLowerInvariant()) ($mech | Where-Object { $_.mechanism -eq $mechanism -and $_.model -eq 'TWFE interaction' -and $_.term_label -eq 'Labor informality x mechanism' } | Select-Object -First 1)
}
foreach ($term in @('Social assistance coverage','Social insurance coverage','Labor informality x social assistance','Labor informality x social insurance')) {
  AddDashRow 'Component joint interaction' $term ($joint | Where-Object { $_.term_label -eq $term } | Select-Object -First 1)
}
$dashboard | Export-Csv (Join-Path $tableDir 'phase3_table_3_robustness_dashboard.csv') -NoTypeInformation

function StatusClass([int]$count) { if ($count -eq 3) { 'green' } elseif ($count -gt 0) { 'amber' } else { 'red' } }
function PClass([double]$p) { if ($p -lt 0.05) { 'sig' } else { 'nonsig' } }
$html = New-Object System.Collections.Generic.List[string]
$html.Add('<!doctype html>')
$html.Add('<html lang="en"><head><meta charset="utf-8"><title>Phase 3 Robustness Dashboard</title>')
$html.Add('<style>body{font-family:Segoe UI,Arial,sans-serif;margin:28px;color:#222}table{border-collapse:collapse;width:100%;font-size:14px}caption{text-align:left;font-weight:700;font-size:20px;margin-bottom:10px}th,td{border:1px solid #d8dee4;padding:8px 10px;text-align:left}th{background:#f6f8fa}.num{text-align:right;font-variant-numeric:tabular-nums}.green{background:#d8f3dc}.amber{background:#fff3bf}.red{background:#f8d7da}.sig{background:#d8f3dc}.nonsig{background:#f8d7da}.note{margin-top:12px;color:#555;max-width:1100px}</style></head><body>')
$html.Add('<table><caption>Table 3. Robustness dashboard for key Phase 2 coefficients</caption><thead><tr><th>Block</th><th>Coefficient</th><th>Estimate</th><th>Cluster p</th><th>Wild p</th><th>DK p</th><th>Robustness</th></tr></thead><tbody>')
foreach ($r in $dashboard) {
  $status = StatusClass $r.significant_methods
  $html.Add(('<tr><td>{0}</td><td>{1}</td><td class="num">{2}</td><td class="num {3}">{4}</td><td class="num {5}">{6}</td><td class="num {7}">{8}</td><td class="{9}">{10}</td></tr>' -f (HtmlEscape $r.block),(HtmlEscape $r.coefficient),(Fmt $r.estimate 4),(PClass $r.cluster_p),(Fmt $r.cluster_p 3),(PClass $r.wild_p),(Fmt $r.wild_p 3),(PClass $r.dk_p),(Fmt $r.dk_p 3),$status,(HtmlEscape $r.robustness)))
}
$html.Add('</tbody></table>')
$html.Add('<p class="note"><strong>Rule.</strong> Green means significant at 5% under all three inference methods; amber means significant under one or two methods; red means significant under none. These are precomputed Phase 2 estimates reorganized for presentation, not re-estimated models.</p>')
$html.Add('</body></html>')
[IO.File]::WriteAllLines((Join-Path $tableDir 'phase3_table_3_robustness_dashboard.html'), [string[]]$html, [System.Text.UTF8Encoding]::new($false))

$tex = New-Object System.Collections.Generic.List[string]
$tex.Add('\begin{table}')
$tex.Add('\centering')
$tex.Add('\definecolor{robustgreen}{HTML}{D8F3DC}')
$tex.Add('\definecolor{robustamber}{HTML}{FFF3BF}')
$tex.Add('\definecolor{robustred}{HTML}{F8D7DA}')
$tex.Add('\caption{Robustness dashboard for key Phase 2 coefficients}')
$tex.Add('\begin{tabular}{llrrrrl}')
$tex.Add('\hline')
$tex.Add('Block & Coefficient & Estimate & Cluster p & Wild p & DK p & Robustness \\')
$tex.Add('\hline')
foreach ($r in $dashboard) {
  $color = if ($r.significant_methods -eq 3) { 'robustgreen' } elseif ($r.significant_methods -gt 0) { 'robustamber' } else { 'robustred' }
  $tex.Add(('{0} & {1} & {2} & {3} & {4} & {5} & \cellcolor{{{6}}}{7}/3 \\' -f (TexEscape $r.block),(TexEscape $r.coefficient),(Fmt $r.estimate 4),(Fmt $r.cluster_p 3),(Fmt $r.wild_p 3),(Fmt $r.dk_p 3),$color,$r.significant_methods))
}
$tex.Add('\hline')
$tex.Add('\end{tabular}')
$tex.Add('\begin{minipage}{0.95\linewidth}')
$tex.Add('\footnotesize Notes: Green indicates significance at the 5 percent level under all three inference methods; amber indicates significance under one or two methods; red indicates significance under none. Estimates are precomputed Phase 2 outputs reorganized for presentation.')
$tex.Add('\end{minipage}')
$tex.Add('\end{table}')
[IO.File]::WriteAllLines((Join-Path $tableDir 'phase3_table_3_robustness_dashboard.tex'), [string[]]$tex, [System.Text.UTF8Encoding]::new($false))

# Update figure catalog
$catalogCsv = Join-Path $figureDir 'phase3_figure_catalog.csv'
$catalog = Import-Csv $catalogCsv
$newRows = @(
  [pscustomobject]@{figure='Figure 17'; file='phase3_figure_17_specification_curve.png'; description='Specification curve for social-protection coefficients across model form, protection measure, and inference method.'},
  [pscustomobject]@{figure='Figure 18'; file='phase3_figure_18_bolivia_policy_timeline.png'; description='Bolivia aggregate country-year timeline for monetary poverty, social assistance coverage, and 2006/2008 policy markers.'}
)
$catalog = @($catalog | Where-Object { $_.figure -notin @('Figure 17','Figure 18') }) + $newRows
$catalog | Export-Csv $catalogCsv -NoTypeInformation
$catalogMd = Join-Path $figureDir 'phase3_figure_catalog.md'
$md = New-Object System.Collections.Generic.List[string]
$md.Add('|figure|file|description|')
$md.Add('|:--|:--|:--|')
foreach ($r in $catalog) { $md.Add(('|{0}|{1}|{2}|' -f $r.figure,$r.file,$r.description)) }
[IO.File]::WriteAllLines($catalogMd, [string[]]$md, [System.Text.UTF8Encoding]::new($false))

Write-Host 'Generated presentation outputs:'
Write-Host (Join-Path $figureDir 'phase3_figure_17_specification_curve.png')
Write-Host (Join-Path $figureDir 'phase3_figure_18_bolivia_policy_timeline.png')
Write-Host (Join-Path $tableDir 'phase3_table_3_robustness_dashboard.html')
Write-Host (Join-Path $tableDir 'phase3_table_3_robustness_dashboard.tex')