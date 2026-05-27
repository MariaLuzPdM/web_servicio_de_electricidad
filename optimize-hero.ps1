Add-Type -AssemblyName System.Drawing

$srcFile = Join-Path $PSScriptRoot 'fotos\INICIO .jpg'
$dstFile = Join-Path $PSScriptRoot 'fotos-web\inicio.jpg'
$maxWidth = 1800
$quality = 75

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

$jpegEncoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$quality)

if (Test-Path $dstFile) {
    try { [System.IO.File]::Delete($dstFile) } catch {}
    Start-Sleep -Milliseconds 200
}

$bitmap.Save($dstFile, $jpegEncoder, $encoderParams)

$graphics.Dispose()
$bitmap.Dispose()
$image.Dispose()

$srcKb = [math]::Round((Get-Item $srcFile).Length / 1KB, 0)
$dstKb = [math]::Round((Get-Item $dstFile).Length / 1KB, 0)
Write-Host "Origen:  ${srcKb} KB (${w}x${h})"
Write-Host "Destino: ${dstKb} KB (${newW}x${newH})"
Write-Host "Guardado en: fotos-web/inicio.jpg"
