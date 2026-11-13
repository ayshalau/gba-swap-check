# Builds the app icons from Logo.png: the GBA tail fin, drawn square on the
# app's pale-teal wash. Run from anywhere - the files land beside the script.
#
#   icon-192.png          launcher and browser tab
#   icon-512.png          install prompt and splash
#   icon-maskable-512.png Android adaptive icon - the fin stays inside the 80%
#                         safe circle, so no launcher shape ever clips it
#   apple-touch-icon.png  iPhone and iPad home screen
#
# Every icon is opaque: iOS paints transparency black behind a home-screen icon.

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$here = $PSScriptRoot
if (-not $here) { $here = Split-Path -Parent $MyInvocation.MyCommand.Path }
$src = [System.Drawing.Bitmap]::FromFile((Join-Path $here "Logo.png"))

# The artwork keeps transparent padding in the file; it must not count towards
# the centring, so the visible fin is measured first.
$minX = $src.Width
$minY = $src.Height
$maxX = -1
$maxY = -1
for ($y = 0; $y -lt $src.Height; $y++) {
    for ($x = 0; $x -lt $src.Width; $x++) {
        if ($src.GetPixel($x, $y).A -gt 8) {
            if ($x -lt $minX) { $minX = $x }
            if ($x -gt $maxX) { $maxX = $x }
            if ($y -lt $minY) { $minY = $y }
            if ($y -gt $maxY) { $maxY = $y }
        }
    }
}
$cropW = $maxX - $minX + 1
$cropH = $maxY - $minY + 1

function New-Icon([int]$size, [double]$ratio, [string]$name) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

    # soft brand wash: white at the top, the app's pale teal at the bottom
    $rect = New-Object System.Drawing.Rectangle(0, 0, $size, $size)
    $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect,
        [System.Drawing.Color]::FromArgb(255, 255, 255, 255),
        [System.Drawing.Color]::FromArgb(255, 226, 245, 246),
        90.0
    )
    $g.FillRectangle($bg, $rect)

    # the fin is centred and scaled to the width the icon needs
    $w = [int][math]::Round($size * $ratio)
    $h = [int][math]::Round($w * ($cropH / $cropW))
    $x = [int][math]::Round(($size - $w) / 2)
    $y = [int][math]::Round(($size - $h) / 2)
    $dst = New-Object System.Drawing.Rectangle($x, $y, $w, $h)
    $g.DrawImage($src, $dst, $minX, $minY, $cropW, $cropH, [System.Drawing.GraphicsUnit]::Pixel)

    $g.Dispose()
    $bmp.Save((Join-Path $here $name), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    $bg.Dispose()
    Write-Output "Wrote $name ($size x $size)"
}

New-Icon 192 0.68 "icon-192.png"
New-Icon 512 0.68 "icon-512.png"
New-Icon 512 0.54 "icon-maskable-512.png"
New-Icon 180 0.68 "apple-touch-icon.png"

$src.Dispose()
