#requires -Version 5
<#
.SYNOPSIS
  Generate a daily newsfeed page from a news-scan JSON file and rebuild the index.
.EXAMPLE
  pwsh -NoProfile -File generate.ps1 -DataFile news-scan.json
#>
param(
  [Parameter(Mandatory = $true)][string]$DataFile,
  [string]$OutDir,
  [string]$Date,
  [string]$SiteTitle = "Craig's Daily Newsfeed"
)
$ErrorActionPreference = 'Stop'
if (-not $OutDir) { $OutDir = Join-Path $PSScriptRoot 'docs' }

# Normalize any text: decode existing HTML entities, then re-encode safely.
function Enc([object]$s) {
  if ($null -eq $s) { return '' }
  return [System.Net.WebUtility]::HtmlEncode([System.Net.WebUtility]::HtmlDecode([string]$s))
}

$data = Get-Content -Raw -LiteralPath $DataFile | ConvertFrom-Json
if (-not $Date) {
  if ($data.generatedAt) { $Date = ([datetimeoffset]$data.generatedAt).ToString('yyyy-MM-dd') }
  else { throw 'No -Date supplied and no generatedAt in data.' }
}
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$css = @'
<style>
:root{color-scheme:light dark}
body{font:16px/1.6 system-ui,-apple-system,Segoe UI,Roboto,sans-serif;max-width:760px;margin:0 auto;padding:1.5rem;color:#111;background:#fff}
a{color:#1a56db}.src{color:#666;font-size:.8rem;margin:.1rem 0}.muted{color:#888;font-size:.85rem}
@media (prefers-color-scheme:dark){body{color:#e6e6e6;background:#16181c}a{color:#8ab4f8}.src,.muted{color:#9aa0a6}}
h1{font-size:1.6rem;margin:.2rem 0}h2{margin-top:2rem;border-bottom:1px solid #8883;padding-bottom:.2rem}
h3{margin:.9rem 0 .1rem;font-size:1.05rem}article{margin:.6rem 0 1rem}nav{margin:.5rem 0 1.5rem}
ul{padding-left:1.2rem}li{margin:.3rem 0}
</style>
'@

# --- Day page ---
$body = [System.Text.StringBuilder]::new()
$count = 0
foreach ($prop in $data.categories.PSObject.Properties) {
  $items = @($prop.Value)
  if ($items.Count -eq 0) { continue }
  [void]$body.AppendLine("<section><h2>$(Enc $prop.Name) <span class='muted'>($($items.Count))</span></h2>")
  foreach ($it in $items) {
    $count++
    $u = [System.Net.WebUtility]::HtmlEncode([string]$it.link)
    [void]$body.AppendLine("<article><h3><a href=""$u"" target=""_blank"" rel=""noopener"">$(Enc $it.title)</a></h3>")
    if ($it.source)  { [void]$body.AppendLine("<p class=""src"">$(Enc $it.source)</p>") }
    if ($it.summary) { [void]$body.AppendLine("<p>$(Enc $it.summary)</p>") }
    [void]$body.AppendLine('</article>')
  }
  [void]$body.AppendLine('</section>')
}

$page = @"
<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>$(Enc $SiteTitle) &mdash; $Date</title>$css</head><body>
<h1>$(Enc $SiteTitle)</h1>
<nav><a href="index.html">&larr; All days</a></nav>
<p class="muted">$Date &middot; $count items</p>
$($body.ToString())
<footer class="muted"><hr>Generated automatically from the daily news loop.</footer>
</body></html>
"@
Set-Content -LiteralPath (Join-Path $OutDir "$Date.html") -Value $page -Encoding UTF8

# --- Rebuild index ---
$days = Get-ChildItem -LiteralPath $OutDir -Filter '*.html' |
  Where-Object { $_.Name -ne 'index.html' } |
  Sort-Object Name -Descending
$list = [System.Text.StringBuilder]::new()
foreach ($d in $days) {
  $name = [System.IO.Path]::GetFileNameWithoutExtension($d.Name)
  [void]$list.AppendLine("<li><a href=""$($d.Name)"">$(Enc $name)</a></li>")
}
$index = @"
<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>$(Enc $SiteTitle)</title>$css</head><body>
<h1>$(Enc $SiteTitle)</h1>
<p class="muted">A fresh list of notable items every day, with links and one-paragraph summaries.</p>
<ul>
$($list.ToString())</ul>
<footer class="muted"><hr>Generated automatically from the daily news loop.</footer>
</body></html>
"@
Set-Content -LiteralPath (Join-Path $OutDir 'index.html') -Value $index -Encoding UTF8
Write-Output "Wrote $Date.html ($count items) and rebuilt index.html in $OutDir ($($days.Count) day(s))."
