Add-Type -AssemblyName System.Drawing

$srcFile = Join-Path $PSScriptRoot 'logo.png'
$tempFolder = Join-Path $env:TEMP ('favicon-' + [guid]::NewGuid().ToString('N').Substring(0,8))
New-Item -ItemType Directory -Path $tempFolder | Out-Null

# ───────────────────────────────────────────────────────────
# 1. Cargar el logo y detectar el bounding box del contenido
#    (todo lo que no sea "blanco" o transparente)
# ───────────────────────────────────────────────────────────
$srcImage = New-Object System.Drawing.Bitmap($srcFile)
$w = $srcImage.Width
$h = $srcImage.Height

$whiteThreshold = 235  # pixeles con R, G y B > 235 se consideran blancos
$minX = $w; $minY = $h; $maxX = 0; $maxY = 0

for ($y = 0; $y -lt $h; $y++) {
    for ($x = 0; $x -lt $w; $x++) {
        $p = $srcImage.GetPixel($x, $y)
        $isWhite = ($p.A -lt 20) -or ($p.R -gt $whiteThreshold -and $p.G -gt $whiteThreshold -and $p.B -gt $whiteThreshold)
        if (-not $isWhite) {
            if ($x -lt $minX) { $minX = $x }
            if ($y -lt $minY) { $minY = $y }
            if ($x -gt $maxX) { $maxX = $x }
            if ($y -gt $maxY) { $maxY = $y }
        }
    }
}

# Asegurar bbox cuadrado (para que el logo no se deforme)
$cropW = $maxX - $minX + 1
$cropH = $maxY - $minY + 1
$cropSize = [Math]::Max($cropW, $cropH)
$centerX = ($minX + $maxX) / 2
$centerY = ($minY + $maxY) / 2
$cropX = [int]($centerX - $cropSize / 2)
$cropY = [int]($centerY - $cropSize / 2)
if ($cropX -lt 0) { $cropX = 0 }
if ($cropY -lt 0) { $cropY = 0 }
if (($cropX + $cropSize) -gt $w) { $cropSize = $w - $cropX }
if (($cropY + $cropSize) -gt $h) { $cropSize = $h - $cropY }

Write-Host "Bounding box del logo: ($minX,$minY) -> ($maxX,$maxY)"
Write-Host "Recortando a ${cropSize}x${cropSize} desde ($cropX,$cropY)"

# ───────────────────────────────────────────────────────────
# 2. Recortar y convertir blanco a transparente
# ───────────────────────────────────────────────────────────
$cleanBitmap = New-Object System.Drawing.Bitmap($cropSize, $cropSize)
for ($y = 0; $y -lt $cropSize; $y++) {
    for ($x = 0; $x -lt $cropSize; $x++) {
        $p = $srcImage.GetPixel($cropX + $x, $cropY + $y)
        $isWhite = ($p.A -lt 20) -or ($p.R -gt $whiteThreshold -and $p.G -gt $whiteThreshold -and $p.B -gt $whiteThreshold)
        if ($isWhite) {
            $cleanBitmap.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
        } else {
            $cleanBitmap.SetPixel($x, $y, $p)
        }
    }
}

$cleanFile = Join-Path $PSScriptRoot 'logo-clean.png'
$cleanBitmap.Save($cleanFile, [System.Drawing.Imaging.ImageFormat]::Png)
Write-Host "Creado: logo-clean.png"

# ───────────────────────────────────────────────────────────
# 3. Generar los favicons a distintos tamaños desde el limpio
#    Cambiamos el sufijo a "-v3" para evitar choques con OneDrive
# ───────────────────────────────────────────────────────────
$sizes = @(16, 32, 48, 64, 180, 192, 512)
foreach ($size in $sizes) {
    $bitmap = New-Object System.Drawing.Bitmap($size, $size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
    $graphics.DrawImage($cleanBitmap, 0, 0, $size, $size)

    $finalFile = Join-Path $PSScriptRoot "icon-$size.png"
    if (Test-Path $finalFile) {
        try { [System.IO.File]::Delete($finalFile) } catch {}
        Start-Sleep -Milliseconds 200
    }
    $bitmap.Save($finalFile, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host "Creado: icon-$size.png"

    $graphics.Dispose()
    $bitmap.Dispose()
}

$cleanBitmap.Dispose()
$srcImage.Dispose()
Remove-Item $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Listo."
