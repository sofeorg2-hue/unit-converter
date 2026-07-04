$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

function Get-AttributeValue {
    param (
        [string]$Text,
        [string]$Name
    )

    $patterns = @(
        [regex]::new($Name + '="([^"]+)"'),
        [regex]::new($Name + "='([^']+)'")
    )

    foreach ($pattern in $patterns) {
        $match = $pattern.Match($Text)
        if ($match.Success) { return $match.Groups[1].Value }
    }

    return ''
}

function Add-EntryIfMissing {
    param(
        [System.Collections.Generic.List[object]]$Entries,
        [pscustomobject]$Entry
    )

    if (-not $Entry.slug) { return }

    $existing = $Entries | Where-Object { $_.slug -eq $Entry.slug }
    if ($existing) {
        $existing.category = $Entry.category
        $existing.from = $Entry.from
        $existing.to = $Entry.to
        $existing.defaultValue = if ($Entry.defaultValue) { $Entry.defaultValue } else { $existing.defaultValue }
        if ($Entry.title) { $existing.title = $Entry.title }
        return
    }

    $Entries.Add($Entry)
}

function Get-ConversionEntriesFromAppJs {
    param([string]$RootPath)

    $entries = [System.Collections.Generic.List[object]]::new()
    $appJsPath = Join-Path $RootPath 'app.js'
    if (-not (Test-Path $appJsPath)) { return $entries }

    $content = Get-Content -Raw -Path $appJsPath
    $pattern = [regex]::new('\{\s*slug:\s*"([^"]+)"\s*,\s*categoryId:\s*"([^"]+)"\s*,\s*from:\s*"([^"]+)"\s*,\s*to:\s*"([^"]+)"', [System.Text.RegularExpressions.RegexOptions]::Multiline)

    foreach ($match in $pattern.Matches($content)) {
        $entries.Add([pscustomobject]@{
            slug = $match.Groups[1].Value
            category = $match.Groups[2].Value
            from = $match.Groups[3].Value
            to = $match.Groups[4].Value
            defaultValue = 1
            title = $null
        })
    }

    return $entries
}

$entries = [System.Collections.Generic.List[object]]::new()
foreach ($entry in (Get-ConversionEntriesFromAppJs -RootPath $Root)) {
    Add-EntryIfMissing -Entries $entries -Entry $entry
}

Get-ChildItem -Path $Root -Recurse -Filter *.html | ForEach-Object {
    $text = Get-Content -Raw -Path $_.FullName
    if ($text -match 'id="seoConverter"' -or $text -match "id='seoConverter'") {
        $slug = Get-AttributeValue -Text $text -Name 'data-slug'
        if (-not $slug) { return }

        $category = Get-AttributeValue -Text $text -Name 'data-category'
        $from = Get-AttributeValue -Text $text -Name 'data-from'
        $to = Get-AttributeValue -Text $text -Name 'data-to'
        $title = ''

        if ($text -match '<title>([^<]+)</title>') {
            $title = $matches[1].Trim()
        }
        else {
            $title = ($slug -replace '-', ' ').ToUpper()
        }

        Add-EntryIfMissing -Entries $entries -Entry ([pscustomobject]@{
            slug = $slug
            category = $category
            from = $from
            to = $to
            defaultValue = 1
            title = $title
        })
    }
}

$entries = $entries | Sort-Object slug
$outputPath = Join-Path $Root 'seo-registry.json'
$entries | ConvertTo-Json -Depth 10 | Set-Content -Path $outputPath -Encoding utf8
Write-Host "Created $($entries.Count) SEO registry entries at $outputPath"
