Add-Type -AssemblyName System.Drawing

$srcFolder = Join-Path $PSScriptRoot 'fotos'
$finalFolder = Join-Path $PSScriptRoot 'fotos-web'
$tempFolder = Join-Path $env:TEMP ('photo-compress-' + [guid]::NewGuid().ToString('N').Substring(0,8))
$maxWidth = 1000
$quality = 55

New-Item -ItemType Directory -Path $tempFolder | Out-Null
if (Test-Path $finalFolder) { Remove-Item $finalFolder -Recurse -Force -ErrorAction SilentlyContinue }
Start-Sleep -Milliseconds 500
New-Item -ItemType Directory -Path $finalFolder -ErrorAction SilentlyContinue | Out-Null

$dstFolder = $tempFolder

$jpegEncoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$quality)

$totalBefore = 0
$totalAfter = 0
$index = 1

Get-ChildItem -Path $srcFolder -File | Where-Object { $_.Extension -match '\.(jpe?g|png)$' } | Sort-Object Name | ForEach-Object {
    $srcFile = $_.FullName
    $sizeBefore = $_.Length
    $totalBefore += $sizeBefore

    $image = [System.Drawing.Image]::FromFile($srcFile)

    $w = $image.Width
    $h = $image.Height
    if ($w -gt $maxWidth) {
        $ratio = $maxWidth / $w
        $newW = $maxWidth
        $newH = [int]($h * $ratio)
    } else {
        $newW = $w
        $newH = $h
    }

    $bitmap = New-Object System.Drawing.Bitmap($newW, $newH)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.DrawImage($image, 0, 0, $newW, $newH)

    $dstName = "trabajo-{0:D2}.jpg" -f $index
    $dstFile = Join-Path $dstFolder $dstName
    $bitmap.Save($dstFile, $jpegEncoder, $encoderParams)

    $graphics.Dispose()
    $bitmap.Dispose()
    $image.Dispose()

    $sizeAfter = (Get-Item $dstFile).Length
    $totalAfter += $sizeAfter

    $beforeKb = [math]::Round($sizeBefore/1024, 0)
    $afterKb = [math]::Round($sizeAfter/1024, 0)
    Write-Host "$dstName -> $beforeKb KB -> $afterKb KB"

    $index++
}

Get-ChildItem -Path $tempFolder -File | ForEach-Object {
    Copy-Item $_.FullName -Destination (Join-Path $finalFolder $_.Name) -Force
}
Remove-Item $tempFolder -Recurse -Force -ErrorAction SilentlyContinue

$totalBeforeMb = [math]::Round($totalBefore/1MB, 2)
$totalAfterMb = [math]::Round($totalAfter/1MB, 2)
$saved = [math]::Round((1 - $totalAfter/$totalBefore) * 100, 1)
Write-Host ""
Write-Host "Total antes: $totalBeforeMb MB"
Write-Host "Total despues: $totalAfterMb MB"
Write-Host "Ahorro: $saved %"
