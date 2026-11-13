# Mechanical runtime exports of the owner's approved logo; no redesign or source mutation.
# Code: MIT. Artwork: see ASSET-LICENSE.md and assets/PROVENANCE.md.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$lumenRoot = Split-Path $PSScriptRoot -Parent
$lumenMaster = Join-Path $lumenRoot 'assets/branding/LumenShift-master.png'
$lumenSource = [System.Drawing.Bitmap]::FromFile($lumenMaster)
try {
    foreach ($lumenSize in @(256, 400)) {
        $lumenBitmap = [System.Drawing.Bitmap]::new($lumenSize, $lumenSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $lumenGraphics = [System.Drawing.Graphics]::FromImage($lumenBitmap)
            try {
                $lumenGraphics.Clear([System.Drawing.Color]::Transparent)
                $lumenGraphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
                $lumenGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $lumenGraphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $lumenGraphics.DrawImage($lumenSource, [System.Drawing.Rectangle]::new(0, 0, $lumenSize, $lumenSize))
            } finally { $lumenGraphics.Dispose() }
            if ($lumenSize -eq 400) {
                $lumenBitmap.Save((Join-Path $lumenRoot 'assets/logo-400.png'), [System.Drawing.Imaging.ImageFormat]::Png)
            } else {
                $lumenStream = [System.IO.File]::Create((Join-Path $lumenRoot 'addon/LumenShift/Media/logo.tga'))
                $lumenWriter = [System.IO.BinaryWriter]::new($lumenStream)
                try {
                    # Uncompressed true-color TGA, 32-bit BGRA, top-left origin and 8 alpha bits.
                    $lumenWriter.Write([byte[]]@(0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 32, 40))
                    for ($lumenY = 0; $lumenY -lt $lumenSize; $lumenY++) {
                        for ($lumenX = 0; $lumenX -lt $lumenSize; $lumenX++) {
                            $lumenPixel = $lumenBitmap.GetPixel($lumenX, $lumenY)
                            $lumenWriter.Write([byte[]]@($lumenPixel.B, $lumenPixel.G, $lumenPixel.R, $lumenPixel.A))
                        }
                    }
                } finally { $lumenWriter.Dispose() }
            }
        } finally { $lumenBitmap.Dispose() }
    }
} finally { $lumenSource.Dispose() }
$lumenManifestPath = Join-Path $lumenRoot 'assets/manifest.json'
$lumenManifest = Get-Content -LiteralPath $lumenManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
$lumenManifest.files['Media/logo.tga'] = (Get-FileHash -LiteralPath (Join-Path $lumenRoot 'addon/LumenShift/Media/logo.tga') -Algorithm SHA256).Hash.ToLowerInvariant()
$lumenManifest.creator = 'Northern Lights Labs; owner-supplied logo plus original project geometry and audio synthesis'
$lumenManifest.source_recipe = 'tools/create_assets.py; tools/export_logo.ps1'
$lumenManifest.borrowed_media = $null
$lumenManifest['logo_source'] = @{
    file = 'assets/branding/LumenShift-master.png'
    sha256 = (Get-FileHash -LiteralPath $lumenMaster -Algorithm SHA256).Hash.ToLowerInvariant()
    approved = '2026-11-07'
    provenance = 'Owner supplied and designated as the new logo; creation tool/artist not supplied'
}
$lumenManifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $lumenManifestPath -Encoding utf8
Write-Output 'Exported approved logo to runtime TGA and preview PNG; source unchanged.'
