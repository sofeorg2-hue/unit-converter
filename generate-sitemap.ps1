$ErrorActionPreference = "Stop"

$BaseUrl = "https://theuniversalconverter.com"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$SitemapPath = Join-Path $Root "sitemap.xml"

function Encode-QueryValue {
  param([string]$Value)
  if ([string]::IsNullOrWhiteSpace($Value)) { return "" }
  return [System.Uri]::EscapeDataString($Value)
}

$urls = New-Object System.Collections.Generic.List[string]
$seoRegistryPath = Join-Path $Root "seo-registry.json"
$seoRoutes = @{}
if (Test-Path $seoRegistryPath) {
  $seoEntries = Get-Content $seoRegistryPath | ConvertFrom-Json
  foreach ($entry in $seoEntries) {
    if ($entry.slug -and $entry.category -and $entry.from -and $entry.to) {
      $query = "category=$(Encode-QueryValue $entry.category)&from=$(Encode-QueryValue $entry.from)&to=$(Encode-QueryValue $entry.to)&value=1&slug=$(Encode-QueryValue $entry.slug)"
      $url = "$BaseUrl/converter?$query"
      $seoRoutes[$entry.slug] = $url
      $seoRoutes["$($entry.category)/$($entry.slug)"] = $url
    }
  }
}

Get-ChildItem $Root -Recurse -File | Where-Object {
  $_.Extension -eq ".html"
} | Sort-Object FullName | ForEach-Object {
  $relative = $_.FullName.Substring($Root.Length).TrimStart([char[]]@("\", "/")) -replace "\\", "/"
  if ($relative -eq "404.html" -or $relative.StartsWith("convert/")) {
    return
  }

  $routeKey = if ($relative -like "*/index.html") { $relative.Substring(0, $relative.Length - "index.html".Length).TrimEnd("/") } else { $relative }
  if ($seoRoutes.ContainsKey($routeKey)) {
    return
  }

  if ($relative -eq "index.html") {
    $urls.Add("$BaseUrl/")
  } elseif ($relative.EndsWith("/index.html")) {
    $urls.Add("$BaseUrl/" + $relative.Substring(0, $relative.Length - "index.html".Length))
  } else {
    $urls.Add("$BaseUrl/$relative")
  }
}

foreach ($seoRoute in $seoRoutes.GetEnumerator() | Select-Object -Unique Value) {
  $urls.Add($seoRoute.Value)
}

$xml = New-Object System.Text.StringBuilder
[void]$xml.AppendLine('<?xml version="1.0" encoding="UTF-8"?>')
[void]$xml.AppendLine('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
$urls | Sort-Object -Unique | ForEach-Object {
  [void]$xml.AppendLine("  <url><loc>$([System.Security.SecurityElement]::Escape($_))</loc><lastmod>2026-07-02</lastmod><changefreq>weekly</changefreq></url>")
}
[void]$xml.AppendLine('</urlset>')
[System.IO.File]::WriteAllText($SitemapPath, $xml.ToString(), [System.Text.UTF8Encoding]::new($false))
Write-Host "Generated sitemap.xml with $(($urls | Sort-Object -Unique).Count) URLs."
