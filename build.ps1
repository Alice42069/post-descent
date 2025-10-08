$ErrorActionPreference = "Stop"

Write-Host "Cleaning dist folder..."

$distFolder = Join-Path -Path (Get-Location) -ChildPath "dist"
if (Test-Path $distFolder) { Remove-Item -Path $distFolder -Recurse -Force }
New-Item -ItemType Directory -Path $distFolder | Out-Null

Write-Host "Copying rebind.ahk..."

Copy-Item -Path "rebind.ahk" -Destination $distFolder -Force

python -m PyInstaller `
    --onefile `
    --noconsole `
    --manifest revive.manifest `
    --add-binary "./Lib/vgamepad/win/vigem/client/x64/ViGEmClient.dll;vgamepad/win/vigem/client/x64" `
    revive.py

Write-Host "Copying Lib folder and README.md..."

Copy-Item -Path "Lib" -Destination (Join-Path $distFolder "Lib") -Recurse -Force

Copy-Item -Path "README.md" -Destination $distFolder -Force

Write-Host "Build complete! Exe and dependencies are in 'dist' folder."
