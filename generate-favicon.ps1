Add-Type -AssemblyName System.Drawing

$srcFile = Join-Path $PSScriptRoot 'logo.png'
$tempFolder = Join-Path $env:TEMP ('favicon-' + [guid]::NewGuid().ToString('N').Substring(0,8))
New-Item -ItemType Directory -Path $tempFolder | Out-Null

$sizes = @(16, 32, 48, 64, 180, 192, 512)

$image = [System.Drawing.Image]::FromFile($srcFile)

foreach ($size in $sizes) {
    $bitmap = New-Object System.Drawing.Bitmap($size, $size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.DrawImage($image, 0, 0, $size, $size)

    $tempFile = Join-Path $tempFolder "favicon-$size.png"
    $bitmap.Save($tempFile, [System.Drawing.Imaging.ImageFormat]::Png)

    $finalFile = Join-Path $PSScriptRoot "favicon-$size.png"
    Copy-Item $tempFile -Destination $finalFile -Force
    Write-Host "Creado: favicon-$size.png"

    $graphics.Dispose()
    $bitmap.Dispose()
}

$image.Dispose()
Remove-Item $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Listo."
