$ErrorActionPreference="SilentlyContinue"
$root=(Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$url="http://localhost:3456"
function Ready { try { $r=Invoke-WebRequest -Uri "$url/health" -UseBasicParsing -TimeoutSec 2; return $true } catch { return $false } }
if(Ready){Start-Process $url;exit 0}
$node=Get-Command node.exe -ErrorAction SilentlyContinue
if(-not $node -and (Test-Path "$env:ProgramFiles\nodejs\node.exe")){$node=Get-Item "$env:ProgramFiles\nodejs\node.exe"}
if(-not $node){Add-Type -AssemblyName System.Windows.Forms;[System.Windows.Forms.MessageBox]::Show("Node.js tapılmadı. Installer-i yenidən başladın.","YouTube AI Agent")|Out-Null;exit 1}
$nodeDir=if($node.Source){Split-Path $node.Source -Parent}else{Split-Path $node.FullName -Parent}
$env:Path="$nodeDir;$env:Path"
$npm=Get-Command npm.cmd -ErrorAction SilentlyContinue
if(-not $npm){exit 1}
$p=Start-Process $npm.Source -ArgumentList "start" -WorkingDirectory $root -WindowStyle Hidden -PassThru
for($i=0;$i-lt 60;$i++){Start-Sleep -Milliseconds 500;if(Ready){Start-Process $url;exit 0};if($p.HasExited){break}}
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show("Dashboard başlatıla bilmədi. Port: 3456","YouTube AI Agent")|Out-Null