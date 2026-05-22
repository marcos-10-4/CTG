$libPath = "C:\Users\PC\Desktop\CtgApp\lib"
$encoding = New-Object System.Text.UTF8Encoding($false)

function Resolve-ImportPath {
    param([string[]]$baseParts, [string]$relPath)
    $relParts = $relPath -split "/" | Where-Object { $_ }
    $result = [System.Collections.Generic.List[string]]::new()
    foreach ($p in $baseParts) { if ($p) { $result.Add($p) } }
    foreach ($p in $relParts) {
        if ($p -eq "..") {
            if ($result.Count -gt 0) { $result.RemoveAt($result.Count - 1) }
        } elseif ($p -ne ".") {
            $result.Add($p)
        }
    }
    return $result -join "/"
}

$files = Get-ChildItem -Path $libPath -Recurse -Filter "*.dart" |
    Where-Object { $_.Name -notmatch '\.(freezed|g)\.dart$' }

$totalFixes = 0

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName, $encoding)
    $relDir = $file.DirectoryName.Substring($libPath.Length).TrimStart('\').Replace('\', '/')
    $dirParts = if ($relDir) { $relDir -split "/" | Where-Object { $_ } } else { @() }
    $parentParts = if ($dirParts.Count -gt 1) { $dirParts[0..($dirParts.Count-2)] } else { @() }

    $fixCount = 0
    $newContent = $content

    # Case 1: Fix broken package:ctg_app/ imports (where lib/X doesn't exist or has ../)
    $pkgPattern = [regex]"import '(package:ctg_app/([^']+))';"
    foreach ($m in $pkgPattern.Matches($content)) {
        $fullStatement = $m.Value
        $importPath = $m.Groups[2].Value
        $libFilePath = [System.IO.Path]::Combine($libPath, $importPath.Replace('/', '\'))
        $isBroken = $importPath.Contains('../') -or (-not [System.IO.File]::Exists($libFilePath))
        if ($isBroken) {
            $fixedPath = Resolve-ImportPath -baseParts $parentParts -relPath $importPath
            $fixedStatement = "import 'package:ctg_app/$fixedPath';"
            if ($fixedStatement -ne $fullStatement) {
                $newContent = $newContent.Replace($fullStatement, $fixedStatement)
                $fixCount++
                Write-Host "  [pkg] $importPath -> $fixedPath"
            }
        }
    }

    # Case 2: Fix remaining relative imports (no package: prefix, no ://)
    $relPattern = [regex]"import '(?!package:|dart:|//)[^:]*';"
    foreach ($m in $relPattern.Matches($content)) {
        $fullStatement = $m.Value
        $importPath = $m.Value -replace "^import '", "" -replace "';$", ""
        # Resolve from file's own directory
        $fixedPath = Resolve-ImportPath -baseParts $dirParts -relPath $importPath
        $fixedStatement = "import 'package:ctg_app/$fixedPath';"
        if ($fixedStatement -ne $fullStatement) {
            $newContent = $newContent.Replace($fullStatement, $fixedStatement)
            $fixCount++
            Write-Host "  [rel] $importPath -> $fixedPath"
        }
    }

    if ($fixCount -gt 0) {
        [System.IO.File]::WriteAllText($file.FullName, $newContent, $encoding)
        Write-Host "Fixed $fixCount imports in: $relDir/$($file.Name)"
        $totalFixes += $fixCount
    }
}

Write-Host "`nTotal: $totalFixes imports fixed"
