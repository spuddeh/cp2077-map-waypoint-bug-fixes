# Build the RED4ext plugin with the VS 2022 Build Tools and place it where the mod installs it:
#   red4ext\plugins\MapWaypointBugFixes\MapWaypointBugFixes.dll
$ErrorActionPreference = 'Stop'
$vs = 'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools'
$root = $PSScriptRoot

$env:Path = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer;$vs\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;$vs\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja;$env:Path"
cmd /c "`"$vs\VC\Auxiliary\Build\vcvars64.bat`" >nul && cmake -S `"$root`" -B `"$root\build`" -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo && cmake --build `"$root\build`""
if ($LASTEXITCODE -ne 0) { throw "plugin build failed" }

$out = Join-Path $root 'red4ext\plugins\MapWaypointBugFixes'
New-Item -ItemType Directory -Force $out | Out-Null
Copy-Item "$root\build\MapWaypointBugFixes.dll" $out
Write-Host "Built $out\MapWaypointBugFixes.dll"
