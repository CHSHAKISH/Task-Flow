Add-Type -AssemblyName System.Drawing
$bitmap = New-Object System.Drawing.Bitmap(512, 512)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.Clear([System.Drawing.Color]::White)

# Draw a blue rounded-ish box (actually let's draw a filled circle)
$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 66, 165, 245))
$graphics.FillEllipse($brush, 32, 32, 448, 448)

# Draw a white checkmark
$penCheck = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 48)
$penCheck.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$penCheck.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$graphics.DrawLine($penCheck, 140, 260, 230, 350)
$graphics.DrawLine($penCheck, 230, 350, 380, 160)

$path = 'D:\Projects\task_flow\assets\images\logo.png'
if (-Not (Test-Path -Path (Split-Path $path))) {
    New-Item -ItemType Directory -Force -Path (Split-Path $path) | Out-Null
}
$bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$bitmap.Dispose()
