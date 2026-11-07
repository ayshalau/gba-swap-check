$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$size = 512
$bmp = New-Object System.Drawing.Bitmap($size, $size)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$g.Clear([System.Drawing.Color]::Transparent)

# background rounded square with vertical teal gradient
$bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.Rectangle(0, 0, $size, $size)),
    [System.Drawing.Color]::FromArgb(255, 181, 230, 233),
    [System.Drawing.Color]::FromArgb(255, 161, 227, 230),
    90.0
)
$path = New-Object System.Drawing.Drawing2D.GraphicsPath
$r = 96
$path.AddArc(0, 0, $r, $r, 180, 90)
$path.AddArc($size - $r, 0, $r, $r, 270, 90)
$path.AddArc($size - $r, $size - $r, $r, $r, 0, 90)
$path.AddArc(0, $size - $r, $r, $r, 90, 90)
$path.CloseFigure()
$g.FillPath($bg, $path)

$ink = [System.Drawing.Color]::FromArgb(255, 10, 92, 99)
$inkSoft = [System.Drawing.Color]::FromArgb(255, 15, 127, 136)

# two swap arrows forming a circular exchange
$pen = New-Object System.Drawing.Pen($ink, 34)
$pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round

$cx = 256.0
$cy = 240.0
$rad = 118.0

$g.DrawArc($pen, ($cx - $rad), ($cy - $rad), ($rad * 2), ($rad * 2), 200, 110)
$g.DrawArc($pen, ($cx - $rad), ($cy - $rad), ($rad * 2), ($rad * 2), 20, 110)

# arrow heads
function Add-Triangle($gr, $pts, $color) {
    $b = New-Object System.Drawing.SolidBrush -ArgumentList $color
    $gr.FillPolygon($b, [System.Drawing.PointF[]]$pts)
    $b.Dispose()
}

# upper arrow head (points right/down at end of first arc)
Add-Triangle $g @(
    (New-Object System.Drawing.PointF(374, 175)),
    (New-Object System.Drawing.PointF(372, 262)),
    (New-Object System.Drawing.PointF(300, 205))
) $ink

# lower arrow head (points left/up at end of second arc)
Add-Triangle $g @(
    (New-Object System.Drawing.PointF(138, 305)),
    (New-Object System.Drawing.PointF(140, 218)),
    (New-Object System.Drawing.PointF(212, 275))
) $inkSoft

# checklist badge bottom-right
$bx = 356.0
$by = 356.0
$badge = New-Object System.Drawing.Drawing2D.GraphicsPath
$br = 74
$badge.AddArc($bx - $br, $by - $br, $br * 2, $br * 2, 0, 360)
$fill = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
$g.FillPath($fill, $badge)
$bp = New-Object System.Drawing.Pen($ink, 14)
$g.DrawEllipse($bp, ($bx - $br), ($by - $br), ($br * 2), ($br * 2))

$chk = New-Object System.Drawing.Pen($ink, 20)
$chk.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$chk.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$g.DrawLines($chk, @(
    (New-Object System.Drawing.PointF(322, 356)),
    (New-Object System.Drawing.PointF(346, 380)),
    (New-Object System.Drawing.PointF(392, 330))
))

$out = Join-Path $PSScriptRoot "swap-icon.png"
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)

$pen.Dispose()
$bp.Dispose()
$chk.Dispose()
$fill.Dispose()
$bg.Dispose()
$path.Dispose()
$badge.Dispose()
$g.Dispose()
$bmp.Dispose()
Write-Output "Wrote $out"
