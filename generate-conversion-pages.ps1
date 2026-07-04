$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$BaseUrl = "https://theuniversalconverter.com"
$TargetNewPages = 6512

$prefixes = @(
  @{ Id = "quetta"; Prefix = "Quetta"; Symbol = "Q"; Factor = 1e30 },
  @{ Id = "ronna"; Prefix = "Ronna"; Symbol = "R"; Factor = 1e27 },
  @{ Id = "yotta"; Prefix = "Yotta"; Symbol = "Y"; Factor = 1e24 },
  @{ Id = "zetta"; Prefix = "Zetta"; Symbol = "Z"; Factor = 1e21 },
  @{ Id = "exa"; Prefix = "Exa"; Symbol = "E"; Factor = 1e18 },
  @{ Id = "peta"; Prefix = "Peta"; Symbol = "P"; Factor = 1e15 },
  @{ Id = "tera"; Prefix = "Tera"; Symbol = "T"; Factor = 1e12 },
  @{ Id = "giga"; Prefix = "Giga"; Symbol = "G"; Factor = 1e9 },
  @{ Id = "mega"; Prefix = "Mega"; Symbol = "M"; Factor = 1e6 },
  @{ Id = "kilo"; Prefix = "Kilo"; Symbol = "k"; Factor = 1e3 },
  @{ Id = "hecto"; Prefix = "Hecto"; Symbol = "h"; Factor = 1e2 },
  @{ Id = "deca"; Prefix = "Deca"; Symbol = "da"; Factor = 1e1 },
  @{ Id = ""; Prefix = ""; Symbol = ""; Factor = 1 },
  @{ Id = "deci"; Prefix = "Deci"; Symbol = "d"; Factor = 1e-1 },
  @{ Id = "centi"; Prefix = "Centi"; Symbol = "c"; Factor = 1e-2 },
  @{ Id = "milli"; Prefix = "Milli"; Symbol = "m"; Factor = 1e-3 },
  @{ Id = "micro"; Prefix = "Micro"; Symbol = "u"; Factor = 1e-6 },
  @{ Id = "nano"; Prefix = "Nano"; Symbol = "n"; Factor = 1e-9 },
  @{ Id = "pico"; Prefix = "Pico"; Symbol = "p"; Factor = 1e-12 },
  @{ Id = "femto"; Prefix = "Femto"; Symbol = "f"; Factor = 1e-15 },
  @{ Id = "atto"; Prefix = "Atto"; Symbol = "a"; Factor = 1e-18 },
  @{ Id = "zepto"; Prefix = "Zepto"; Symbol = "z"; Factor = 1e-21 },
  @{ Id = "yocto"; Prefix = "Yocto"; Symbol = "y"; Factor = 1e-24 },
  @{ Id = "ronto"; Prefix = "Ronto"; Symbol = "r"; Factor = 1e-27 },
  @{ Id = "quecto"; Prefix = "Quecto"; Symbol = "q"; Factor = 1e-30 }
)

function Slugify {
  param([string]$Value)
  return ($Value.ToLowerInvariant() -replace "[^a-z0-9]+", "-" -replace "^-+", "" -replace "-+$", "")
}

function Escape-Html {
  param([string]$Value)
  return ($Value -replace "&", "&amp;" -replace "<", "&lt;" -replace ">", "&gt;" -replace '"', "&quot;" -replace "'", "&#039;")
}

function Format-Value {
  param([double]$Value)
  if ($Value -eq 0) { return "0" }
  $formatted = "{0:G15}" -f $Value
  return $formatted.Replace("E+", "e+").Replace("E-", "e-")
}

function New-Unit {
  param(
    [string]$Id,
    [string]$Singular,
    [string]$Plural,
    [string]$Symbol,
    [double]$Factor,
    [string]$Definition,
    [string]$Category
  )

  [pscustomobject]@{
    id = $Id
    singular = $Singular
    plural = $Plural
    symbol = $Symbol
    factor = [double]$Factor
    definition = $Definition
    category = $Category
    slug = (Slugify $Plural)
  }
}

function Expand-MetricUnits {
  param(
    [string]$BaseId,
    [string]$BaseSingular,
    [string]$BasePlural,
    [string]$BaseSymbol,
    [double]$BaseFactor,
    [string]$Definition,
    [string]$Category
  )

  $units = @()
  foreach ($prefix in $prefixes) {
    $id = if ($prefix.Id) { "$($prefix.Id)$BaseId" } else { $BaseId }
    $singular = if ($prefix.Prefix) { "$($prefix.Prefix)$BaseSingular" } else { $BaseSingular }
    $plural = if ($prefix.Prefix) { "$($prefix.Prefix)$BasePlural" } else { $BasePlural }
    $symbol = "$($prefix.Symbol)$BaseSymbol"
    $factor = $BaseFactor * [double]$prefix.Factor
    $unitDefinition = if ($prefix.Id) { "$singular is $($prefix.Factor) $($BasePlural.ToLower()) units." } else { $Definition }
    $units += New-Unit -Id $id -Singular $singular -Plural $plural -Symbol $symbol -Factor $factor -Definition $unitDefinition -Category $Category
  }
  return $units
}

function Expand-SquareMetricUnits {
  param(
    [string]$BaseId,
    [string]$BaseSingular,
    [string]$BasePlural,
    [string]$BaseSymbol,
    [double]$BaseFactor,
    [string]$Definition
  )

  $units = @()
  foreach ($prefix in $prefixes) {
    $id = if ($prefix.Id) { "square_$($prefix.Id)$BaseId" } else { "square_$BaseId" }
    $singular = if ($prefix.Prefix) { "Square $($prefix.Prefix)$BaseSingular" } else { "Square $BaseSingular" }
    $plural = if ($prefix.Prefix) { "Square $($prefix.Prefix)$BasePlural" } else { "Square $BasePlural" }
    $symbol = "$($prefix.Symbol)$BaseSymbol`2"
    $factor = $BaseFactor * [math]::Pow([double]$prefix.Factor, 2)
    $units += New-Unit -Id $id -Singular $singular -Plural $plural -Symbol $symbol -Factor $factor -Definition $Definition -Category "area"
  }
  return $units
}

function Expand-CubicMetricUnits {
  param(
    [string]$BaseId,
    [string]$BaseSingular,
    [string]$BasePlural,
    [string]$BaseSymbol,
    [double]$BaseFactor,
    [string]$Definition
  )

  $units = @()
  foreach ($prefix in $prefixes) {
    $id = if ($prefix.Id) { "cubic_$($prefix.Id)$BaseId" } else { "cubic_$BaseId" }
    $singular = if ($prefix.Prefix) { "Cubic $($prefix.Prefix)$BaseSingular" } else { "Cubic $BaseSingular" }
    $plural = if ($prefix.Prefix) { "Cubic $($prefix.Prefix)$BasePlural" } else { "Cubic $BasePlural" }
    $symbol = "$($prefix.Symbol)$BaseSymbol`3"
    $factor = $BaseFactor * [math]::Pow([double]$prefix.Factor, 3)
    $units += New-Unit -Id $id -Singular $singular -Plural $plural -Symbol $symbol -Factor $factor -Definition $Definition -Category "volume"
  }
  return $units
}

function Build-LengthUnits {
  $units = @()
  $units += Expand-MetricUnits -BaseId "meter" -BaseSingular "Meter" -BasePlural "Meters" -BaseSymbol "m" -BaseFactor 1 -Definition "The meter is the SI base unit of length." -Category "length"
  $units += @(
    New-Unit "inch" "Inch" "Inches" "in" 0.0254 "An inch is exactly 0.0254 meters." "length"
    New-Unit "foot" "Foot" "Feet" "ft" 0.3048 "A foot is exactly 0.3048 meters." "length"
    New-Unit "yard" "Yard" "Yards" "yd" 0.9144 "A yard is exactly 0.9144 meters." "length"
    New-Unit "mile" "Mile" "Miles" "mi" 1609.344 "A statute mile is exactly 1,609.344 meters." "length"
    New-Unit "nautical_mile" "Nautical mile" "Nautical miles" "nmi" 1852 "A nautical mile is exactly 1,852 meters." "length"
    New-Unit "survey_foot_us" "US survey foot" "US survey feet" "ftUS" 0.3048006096012192 "The US survey foot is 1200/3937 meters." "length"
    New-Unit "angstrom" "Angstrom" "Angstroms" "A" 1e-10 "An angstrom is 1e-10 meters." "length"
    New-Unit "fathom" "Fathom" "Fathoms" "ftm" 1.8288 "A fathom is six feet." "length"
    New-Unit "chain" "Chain" "Chains" "ch" 20.1168 "A surveyor's chain is 66 feet." "length"
    New-Unit "link" "Link" "Links" "li" 0.201168 "A surveyor's link is 1/100 of a chain." "length"
    New-Unit "rod" "Rod" "Rods" "rd" 5.0292 "A rod is 16.5 feet." "length"
    New-Unit "furlong" "Furlong" "Furlongs" "fur" 201.168 "A furlong is 660 feet." "length"
    New-Unit "league" "League" "Leagues" "lea" 4828.032 "A league is commonly treated as three statute miles." "length"
    New-Unit "hand" "Hand" "Hands" "hh" 0.1016 "A hand is four inches." "length"
    New-Unit "cubit" "Cubit" "Cubits" "cubit" 0.4572 "A common cubit is approximated as 18 inches." "length"
    New-Unit "point" "Point" "Points" "pt" 0.0003527777778 "A desktop publishing point is 1/72 inch." "length"
    New-Unit "pica" "Pica" "Picas" "pc" 0.004233333333 "A pica is 12 points." "length"
    New-Unit "astronomical_unit" "Astronomical unit" "Astronomical units" "AU" 149597870700 "An astronomical unit is the mean Earth-Sun distance." "length"
    New-Unit "light_year" "Light-year" "Light-years" "ly" 9460730472580800 "A light-year is the distance light travels in a Julian year." "length"
    New-Unit "parsec" "Parsec" "Parsecs" "pc" 3.085677581491367e16 "A parsec is about 3.26156 light-years." "length"
  )
  return $units
}

function Build-AreaUnits {
  $units = @()
  $units += Expand-SquareMetricUnits -BaseId "meter" -BaseSingular "Meter" -BasePlural "Meters" -BaseSymbol "m" -BaseFactor 1 -Definition "Square metric area unit."
  $units += @(
    New-Unit "hectare" "Hectare" "Hectares" "ha" 10000 "A hectare is 10,000 square meters." "area"
    New-Unit "acre" "Acre" "Acres" "ac" 4046.8564224 "An international acre is 4,046.8564224 square meters." "area"
    New-Unit "section" "Section" "Sections" "section" 2589988.110336 "A section is one square mile or 640 acres." "area"
    New-Unit "township" "Township" "Townships" "twp" 93239571.972096 "A survey township is 36 square miles." "area"
    New-Unit "square_inch" "Square inch" "Square inches" "in2" 0.00064516 "A square inch is the area of a one-inch square." "area"
    New-Unit "square_foot" "Square foot" "Square feet" "ft2" 0.09290304 "A square foot is exactly 0.09290304 square meters." "area"
    New-Unit "square_yard" "Square yard" "Square yards" "yd2" 0.83612736 "A square yard is exactly 0.83612736 square meters." "area"
    New-Unit "square_mile" "Square mile" "Square miles" "mi2" 2589988.110336 "A square mile is 640 acres." "area"
    New-Unit "are" "Are" "Ares" "a" 100 "An are is 100 square meters." "area"
    New-Unit "barn" "Barn" "Barns" "b" 1e-28 "A barn is a nuclear cross-section unit equal to 1e-28 square meters." "area"
    New-Unit "rood" "Rood" "Roods" "rood" 1011.7141056 "A rood is one quarter of an acre." "area"
  )
  return $units
}

function Build-VolumeUnits {
  $units = @()
  $units += Expand-CubicMetricUnits -BaseId "meter" -BaseSingular "Meter" -BasePlural "Meters" -BaseSymbol "m" -BaseFactor 1 -Definition "Cubic metric volume unit."
  $units += Expand-MetricUnits -BaseId "liter" -BaseSingular "Liter" -BasePlural "Liters" -BaseSymbol "L" -BaseFactor 0.001 -Definition "A liter is one cubic decimeter." -Category "volume"
  $units += @(
    New-Unit "gallon_us" "Gallon" "Gallons" "gal" 0.003785411784 "A US liquid gallon is exactly 3.785411784 liters." "volume"
    New-Unit "gallon_imperial" "Imperial gallon" "Imperial gallons" "imp gal" 0.00454609 "An imperial gallon is exactly 4.54609 liters." "volume"
    New-Unit "quart_us" "Quart" "Quarts" "qt" 0.000946352946 "A US liquid quart is one quarter of a US gallon." "volume"
    New-Unit "quart_imperial" "Imperial quart" "Imperial quarts" "imp qt" 0.0011365225 "An imperial quart is one quarter of an imperial gallon." "volume"
    New-Unit "pint_us" "Pint" "Pints" "pt" 0.000473176473 "A US liquid pint is one eighth of a US gallon." "volume"
    New-Unit "pint_imperial" "Imperial pint" "Imperial pints" "imp pt" 0.00056826125 "An imperial pint is one eighth of an imperial gallon." "volume"
    New-Unit "fluid_ounce_us" "Fluid ounce" "Fluid ounces" "fl oz" 0.0000295735295625 "A US fluid ounce is 1/128 of a US gallon." "volume"
    New-Unit "fluid_ounce_imperial" "Imperial fluid ounce" "Imperial fluid ounces" "imp fl oz" 0.0000284130625 "An imperial fluid ounce is 1/160 of an imperial gallon." "volume"
    New-Unit "cup_us" "Cup" "Cups" "cup" 0.0002365882365 "A US customary cup is 236.5882365 milliliters." "volume"
    New-Unit "cup_metric" "Metric cup" "Metric cups" "metric cup" 0.00025 "A metric cup is 250 milliliters." "volume"
    New-Unit "tablespoon_us" "Tablespoon" "Tablespoons" "tbsp" 0.00001478676478125 "A US tablespoon is half a US fluid ounce." "volume"
    New-Unit "tablespoon_metric" "Metric tablespoon" "Metric tablespoons" "metric tbsp" 0.000015 "A metric tablespoon is 15 milliliters." "volume"
    New-Unit "teaspoon_us" "Teaspoon" "Teaspoons" "tsp" 0.00000492892159375 "A US teaspoon is one third of a US tablespoon." "volume"
    New-Unit "teaspoon_metric" "Metric teaspoon" "Metric teaspoons" "metric tsp" 0.000005 "A metric teaspoon is 5 milliliters." "volume"
    New-Unit "barrel_oil" "Oil barrel" "Oil barrels" "bbl" 0.158987294928 "An oil barrel is 42 US gallons." "volume"
    New-Unit "bushel_us" "Bushel" "Bushels" "bu" 0.03523907016688 "A US bushel is about 35.239 liters." "volume"
    New-Unit "cubic_inch" "Cubic inch" "Cubic inches" "in3" 0.000016387064 "A cubic inch is the volume of a one-inch cube." "volume"
    New-Unit "cubic_foot" "Cubic foot" "Cubic feet" "ft3" 0.028316846592 "A cubic foot is exactly 0.028316846592 cubic meters." "volume"
    New-Unit "cubic_yard" "Cubic yard" "Cubic yards" "yd3" 0.764554857984 "A cubic yard is exactly 0.764554857984 cubic meters." "volume"
  )
  return $units
}

function Build-PageSlug {
  param([string]$FromPlural, [string]$ToPlural)
  return "$(Slugify $FromPlural)-to-$(Slugify $ToPlural)"
}

function Make-OrderedPairs {
  param([object[]]$Units, [string]$CategoryId, [string]$CategoryName)
  $pairs = @()
  for ($i = 0; $i -lt $Units.Count; $i++) {
    for ($j = 0; $j -lt $Units.Count; $j++) {
      if ($i -eq $j) { continue }
      $pairs += [pscustomobject]@{
        category = [pscustomobject]@{ id = $CategoryId; name = $CategoryName }
        from = $Units[$i]
        to = $Units[$j]
      }
    }
  }
  return $pairs
}

function Make-UnorderedPairs {
  param([object[]]$Units, [string]$CategoryId, [string]$CategoryName)
  $pairs = @()
  for ($i = 0; $i -lt $Units.Count; $i++) {
    for ($j = $i + 1; $j -lt $Units.Count; $j++) {
      $pairs += [pscustomobject]@{
        category = [pscustomobject]@{ id = $CategoryId; name = $CategoryName }
        from = $Units[$i]
        to = $Units[$j]
      }
    }
  }
  return $pairs
}

function Write-CategoryPage {
  param(
    [string]$CategoryId,
    [string]$CategoryName,
    [object[]]$SamplePairs
  )

  $folder = Join-Path $Root $CategoryId
  $pagePath = Join-Path $folder "index.html"
  New-Item -ItemType Directory -Force -Path $folder | Out-Null

  $title = "$CategoryName Pages - Universal Converter"
  $description = "Browse the $($CategoryName.ToLower()) page library and open fast calculator pages on Universal Converter."
  $canonical = "$BaseUrl/$CategoryId/"
  $featured = $SamplePairs | Select-Object -First 1
  $featuredSlug = if ($featured) { Build-PageSlug -FromPlural $featured.from.plural -ToPlural $featured.to.plural } else { "" }
  $links = ($SamplePairs | Select-Object -First 8 | ForEach-Object {
    $slug = Build-PageSlug -FromPlural $_.from.plural -ToPlural $_.to.plural
    $href = "/converter?category=$($CategoryId)&from=$($_.from.id)&to=$($_.to.id)&value=1&slug=$slug#converter"
    "<li><a href=\"$href\">$($_.from.plural) to $($_.to.plural)</a></li>"
  }) -join ""

  $html = @"
<!doctype html>
<html lang="en" data-theme="light">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$title</title>
  <meta name="description" content="$description">
  <link rel="canonical" href="$canonical">
  <meta property="og:title" content="$title">
  <meta property="og:description" content="$description">
  <meta property="og:type" content="website">
  <meta property="og:url" content="$canonical">
  <link rel="icon" href="/favicon.svg" type="image/svg+xml">
  <link rel="manifest" href="/site.webmanifest">
  <link rel="stylesheet" href="/styles.css">
</head>
<body>
  <header class="site-header"><a class="brand" href="/"><img src="/logo.svg" alt="Universal Converter logo" width="38" height="38"><span>Universal Converter</span></a><nav class="top-nav"><a href="/#converter">Converter</a><a href="/guides.html">Guides</a><a href="/sitemap.html">Sitemap</a><a href="/about.html">About</a></nav></header>
  <main class="page-shell">
    <section class="page-hero">
      <p class="eyebrow">$CategoryName</p>
      <h1>$CategoryName Pages</h1>
      <p>$description</p>
    </section>
    <section class="page-card" id="seoConverter" data-slug="$CategoryId" data-category="$CategoryId" data-from="$($featured.from.id)" data-to="$($featured.to.id)" data-value="1"></section>
    <section class="page-card">
      <h2>Featured conversions</h2>
      <ul>$links</ul>
    </section>
  </main>
</body>
</html>
"@

  [System.IO.File]::WriteAllText($pagePath, $html, [System.Text.UTF8Encoding]::new($false))
  return $true
}

function Write-ConversionPage {
  param(
    [object]$Pair,
    [int]$Index,
    [object[]]$AllPairs
  )

  $categoryId = $Pair.category.id
  $categoryName = $Pair.category.name
  $from = $Pair.from
  $to = $Pair.to
  $slug = Build-PageSlug -FromPlural $from.plural -ToPlural $to.plural
  $folder = Join-Path (Join-Path $Root $categoryId) $slug
  $pagePath = Join-Path $folder "index.html"
  New-Item -ItemType Directory -Force -Path $folder | Out-Null

  $canonical = "$BaseUrl/$categoryId/$slug/"
  $categoryLabel = $categoryName -replace " Converter$", ""
  $title = "$categoryLabel $($from.plural) to $($to.plural) Converter"
  $description = "Convert $($from.plural.ToLower()) to $($to.plural.ToLower()) on the $($categoryLabel.ToLower()) page with formula, table, FAQ, and related conversions."
  $factor = [double]$from.factor / [double]$to.factor
  $formattedFactor = Format-Value $factor
  $reverseSlug = Build-PageSlug -FromPlural $to.plural -ToPlural $from.plural
  $categoryLink = "/$categoryId/"
  $related = New-Object System.Collections.Generic.List[string]
  $related.Add($reverseSlug)
  $related.Add($categoryLink)
  if ($Index -gt 0) {
    $prev = $AllPairs[$Index - 1]
    $related.Add((Build-PageSlug -FromPlural $prev.from.plural -ToPlural $prev.to.plural))
  }
  if ($Index -lt ($AllPairs.Count - 1)) {
    $next = $AllPairs[$Index + 1]
    $related.Add((Build-PageSlug -FromPlural $next.from.plural -ToPlural $next.to.plural))
  }
  $related = $related | Select-Object -Unique

  $tableRows = (1, 5, 10, 25, 100 | ForEach-Object {
    $result = Format-Value ($_ * $factor)
    "<tr><td>$_</td><td>$result $($to.plural)</td></tr>"
  }) -join ""

  $faq1 = "How do you convert $($from.plural.ToLower()) to $($to.plural.ToLower())?"
  $faq2 = "What is one $($from.singular.ToLower()) in $($to.plural.ToLower())?"
  $faq1a = "Multiply the source value by $formattedFactor to convert from $($from.plural.ToLower()) to $($to.plural.ToLower())."
  $faq2a = "One $($from.singular.ToLower()) equals $formattedFactor $($to.plural.ToLower())."

  $relatedHtml = ($related | ForEach-Object {
    if ($_ -eq $reverseSlug) {
      "<li><a href=\"/converter?category=$categoryId&from=$($to.id)&to=$($from.id)&value=1&slug=$reverseSlug#converter\">Reverse conversion</a></li>"
    } elseif ($_ -eq $categoryLink) {
      "<li><a href=\"$categoryLink\">Parent category</a></li>"
    } else {
      $relatedSlug = $_
      $relatedConfig = $AllPairs | Where-Object {
        (Build-PageSlug -FromPlural $_.from.plural -ToPlural $_.to.plural) -eq $relatedSlug
      } | Select-Object -First 1
      if ($relatedConfig) {
        "<li><a href=\"/converter?category=$categoryId&from=$($relatedConfig.from.id)&to=$($relatedConfig.to.id)&value=1&slug=$relatedSlug#converter\">$($relatedSlug -replace '-', ' ')</a></li>"
      } else {
        "<li><a href=\"/converter?category=$categoryId&from=$($from.id)&to=$($to.id)&value=1&slug=$relatedSlug#converter\">$($relatedSlug -replace '-', ' ')</a></li>"
      }
    }
  }) -join ""

  $sourceUses = switch ($categoryId) {
    "length" { "travel, construction, surveying, maps, and everyday measuring" }
    "area" { "land records, floor plans, mapping, agriculture, and planning" }
    "volume" { "cooking, fuel, logistics, packaging, and lab work" }
    default { "professional, scientific, and everyday calculations" }
  }

  $breadcrumbSchema = [pscustomobject]@{
    "@context" = "https://schema.org"
    "@type" = "BreadcrumbList"
    itemListElement = @(
      [pscustomobject]@{ "@type" = "ListItem"; position = 1; name = "Home"; item = "$BaseUrl/" },
      [pscustomobject]@{ "@type" = "ListItem"; position = 2; name = $CategoryName; item = "$BaseUrl/$categoryId/" },
      [pscustomobject]@{ "@type" = "ListItem"; position = 3; name = $title; item = $canonical }
    )
  } | ConvertTo-Json -Depth 6 -Compress
  $faqSchema = [pscustomobject]@{
    "@context" = "https://schema.org"
    "@type" = "FAQPage"
    mainEntity = @(
      [pscustomobject]@{
        "@type" = "Question"
        name = $faq1
        acceptedAnswer = [pscustomobject]@{ "@type" = "Answer"; text = $faq1a }
      },
      [pscustomobject]@{
        "@type" = "Question"
        name = $faq2
        acceptedAnswer = [pscustomobject]@{ "@type" = "Answer"; text = $faq2a }
      }
    )
  } | ConvertTo-Json -Depth 6 -Compress

  $html = @"
<!doctype html>
<html lang="en" data-theme="light">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$(Escape-Html $title) | Universal Converter</title>
  <meta name="description" content="$(Escape-Html $description)">
  <meta name="keywords" content="$(Escape-Html $from.plural.ToLower()), $(Escape-Html $to.plural.ToLower()), $(Escape-Html $categoryId) converter, unit converter, online calculator, measurement converter">
  <meta name="robots" content="index, follow">
  <meta name="google-adsense-account" content="ca-pub-2057098005458261">
  <link rel="canonical" href="$canonical">
  <meta property="og:title" content="$(Escape-Html $title)">
  <meta property="og:description" content="$(Escape-Html $description)">
  <meta property="og:type" content="website">
  <meta property="og:url" content="$canonical">
  <meta property="og:image" content="../logo.svg">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="theme-color" content="#0f9f9a">
  <link rel="icon" href="/favicon.svg" type="image/svg+xml">
  <link rel="manifest" href="/site.webmanifest">
  <link rel="stylesheet" href="/styles.css">
  <script src="/adsense-config.js" defer></script>
  <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-2057098005458261" crossorigin="anonymous"></script>
  <script src="/adsense.js" defer></script>
  <script type="application/ld+json">$breadcrumbSchema</script>
  <script type="application/ld+json">$faqSchema</script>
</head>
<body>
  <header class="site-header">
    <a class="brand" href="/"><img src="/logo.svg" alt="Universal Converter logo" width="38" height="38"><span>Universal Converter</span></a>
    <nav class="top-nav"><a href="/#converter">Converter</a><a href="/guides.html">Guides</a><a href="/sitemap.html">Sitemap</a><a href="/about.html">About</a></nav>
    <button class="theme-toggle" id="themeToggle" type="button"><span class="theme-dot"></span><span id="themeText">Dark</span></button>
  </header>
  <section class="ad-band header-ad" data-ad-placement="header" aria-label="Header advertisement placeholder"><span>Advertisement</span><strong>Header ad slot</strong><p>Reserved responsive banner space.</p></section>
  <main class="page-shell">
    <nav class="breadcrumb" aria-label="Breadcrumb">
      <a href="/">Home</a> <span>/</span>
      <a href="$categoryLink">$categoryLabel</a> <span>/</span>
      <span>$(Escape-Html $title)</span>
    </nav>
    <section class="page-hero">
      <p class="eyebrow">$categoryLabel</p>
      <h1>$(Escape-Html $title)</h1>
      <p>Convert $($from.plural.ToLower()) to $($to.plural.ToLower()) with formulas, examples, FAQ, and a fast interactive converter.</p>
      <p><a href="/converter?category=$categoryId&from=$($to.id)&to=$($from.id)&value=1&slug=$reverseSlug#converter">Reverse conversion</a> | <a href="$categoryLink">Category page</a> | <a href="/">Universal Converter</a></p>
    </section>
    <section class="page-card" id="seoConverter" data-slug="$slug" data-category="$categoryId" data-from="$($from.id)" data-to="$($to.id)" data-value="1"></section>
    <section class="converter-ad-slot" data-ad-placement="converter" aria-label="Converter advertisement placeholder"><span>Advertisement</span><strong>Converter ad slot</strong><p>Placed below the converter result before formula explanations.</p></section>
    <section class="page-grid">
      <article class="page-card"><h2>Formula</h2><p>1 $($from.plural.ToLower()) = $formattedFactor $($to.plural.ToLower()).</p></article>
      <article class="page-card"><h2>Conversion table</h2><table><thead><tr><th>$($from.singular)</th><th>$($to.singular)</th></tr></thead><tbody>$tableRows</tbody></table></article>
      <article class="page-card"><h2>Source unit</h2><p>$($from.definition)</p><p>Common uses: $sourceUses</p></article>
      <article class="page-card"><h2>Destination unit</h2><p>$($to.definition)</p><p>Common uses: $sourceUses</p></article>
      <article class="page-card"><h2>FAQ</h2><div class="faq-item"><h3>$faq1</h3><p>$faq1a</p></div><div class="faq-item"><h3>$faq2</h3><p>$faq2a</p></div></article>
      <article class="page-card"><h2>Related conversions</h2><ul>$relatedHtml<li><a href="/">Universal Converter</a></li></ul></article>
    </section>
  </main>
  <footer class="site-footer">
    <div><a class="brand footer-brand" href="/"><img src="/logo.svg" alt="" width="32" height="32"><span>Universal Converter</span></a><p>Fast global conversions and calculators.</p></div>
    <nav><a href="/privacy.html">Privacy</a><a href="/terms.html">Terms</a><a href="/contact.html">Contact</a></nav>
  </footer>
  <script src="/analytics-config.js" defer></script>
  <script src="/google-analytics.js" defer></script>
  <script src="/app.js" defer></script>
</body>
</html>
"@

  [System.IO.File]::WriteAllText($pagePath, $html, [System.Text.UTF8Encoding]::new($false))
  return $true
}

$lengthUnits = Build-LengthUnits
$areaUnits = Build-AreaUnits
$volumeUnits = Build-VolumeUnits

$lengthPairs = Make-OrderedPairs -Units $lengthUnits -CategoryId "length" -CategoryName "Length Converter"
$areaPairs = Make-OrderedPairs -Units $areaUnits -CategoryId "area" -CategoryName "Area Converter"
$volumeUnordered = Make-UnorderedPairs -Units $volumeUnits -CategoryId "volume" -CategoryName "Volume Converter"
$volumeSelected = $volumeUnordered | Select-Object -First 1636
$volumePairs = @()
foreach ($pair in $volumeSelected) {
  $volumePairs += [pscustomobject]@{ category = $pair.category; from = $pair.from; to = $pair.to }
  $volumePairs += [pscustomobject]@{ category = $pair.category; from = $pair.to; to = $pair.from }
}

if (($lengthPairs.Count + $areaPairs.Count + $volumePairs.Count) -ne $TargetNewPages) {
  throw "Expected to generate $TargetNewPages conversion pages, but built $($lengthPairs.Count + $areaPairs.Count + $volumePairs.Count)."
}

Write-CategoryPage -CategoryId "length" -CategoryName "Length Converter" -SamplePairs $lengthPairs | Out-Null
Write-CategoryPage -CategoryId "area" -CategoryName "Area Converter" -SamplePairs $areaPairs | Out-Null
Write-CategoryPage -CategoryId "volume" -CategoryName "Volume Converter" -SamplePairs $volumePairs | Out-Null

$allPairs = @($lengthPairs + $areaPairs + $volumePairs)
$created = 0
for ($i = 0; $i -lt $allPairs.Count; $i++) {
  if (Write-ConversionPage -Pair $allPairs[$i] -Index $i -AllPairs $allPairs) {
    $created++
  }
}

Write-Host "Generated $created missing conversion pages."
