$projectRoot = (Get-Location).Path
$libPath = Join-Path $projectRoot "lib"
$routesFile = Join-Path $libPath "generated_routes.dart"

$dartFiles = Get-ChildItem -Recurse $libPath -Filter *.dart |
  Where-Object {
    $_.FullName -ne (Join-Path $libPath "main.dart") -and
    $_.Name -ne "generated_routes.dart"
  }

$entries = [System.Collections.Generic.List[string]]::new()
$imports = [System.Collections.Generic.HashSet[string]]::new()

foreach ($file in $dartFiles) {
  $content = Get-Content $file.FullName -Raw
  $classMatches = [regex]::Matches($content, 'class\s+([A-Z][A-Za-z0-9_]*)\s+extends\s+(StatelessWidget|StatefulWidget)')
  if ($classMatches.Count -eq 0) { continue }

  $relPath = $file.FullName.Substring($libPath.Length + 1).Replace('\','/')
  $imports.Add("import '$relPath';") | Out-Null

  foreach ($m in $classMatches) {
    $name = $m.Groups[1].Value
    $hasZeroArg = [regex]::IsMatch($content, "(\bconst\s+)?$name\s*\(\s*\)")
    if (-not $hasZeroArg) { continue }
    $isConst = [regex]::IsMatch($content, "const\s+$name\s*\(\s*\)")
    $ctor = $isConst ? "const $name()" : "$name()"
    $entries.Add("  '/$name': (_) => $ctor,") | Out-Null
  }
}

$importsText = ($imports | Sort-Object) -join "`n"
$entriesText = ($entries | Sort-Object) -join "`n"

$out = @"
// AUTO-GENERATED. Run tools/generate_routes.ps1 to update.
// ignore_for_file: depend_on_referenced_packages, unused_import
import 'package:flutter/widgets.dart';
$importsText

const Map<String, WidgetBuilder> generatedRoutes = {
$entriesText
};
"@

Set-Content -Path $routesFile -Encoding UTF8 -Value $out
Write-Host "Wrote routes to $routesFile"
