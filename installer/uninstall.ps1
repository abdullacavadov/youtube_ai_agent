Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference="Stop"
$root=(Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$app="YouTube AI Agent"

function StopAppProcesses {
  $rootFull=$root.TrimEnd("\")
  $all=Get-CimInstance Win32_Process -ErrorAction SilentlyContinue
  $targets=@{}
  foreach($p in $all){
    if($p.ProcessId -eq $PID){ continue }
    if($p.CommandLine -and ($p.CommandLine -like "*$rootFull*" -or $p.CommandLine -like "*youtube_ai_agent*")){ $targets[$p.ProcessId]=$true }
  }
  $changed=$true
  while($changed){
    $changed=$false
    foreach($p in $all){
      if($targets.ContainsKey($p.ParentProcessId) -and -not $targets.ContainsKey($p.ProcessId)){ $targets[$p.ProcessId]=$true; $changed=$true }
    }
  }
  foreach($p in $all | Where-Object { $targets.ContainsKey($_.ProcessId) }){ try { Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop } catch {} }
  Start-Sleep -Seconds 2
}
function RemovePath($path) {
  if(Test-Path -LiteralPath $path){ Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction Stop }
}

$form=New-Object System.Windows.Forms.Form
$form.Text="$app - Uninstall"
$form.Size=New-Object System.Drawing.Size(650,390)
$form.StartPosition="CenterScreen"
$form.FormBorderStyle="FixedDialog"
$form.MaximizeBox=$false
$form.MinimizeBox=$false
$title=New-Object System.Windows.Forms.Label
$title.Text="$app  Uninstall"
$title.Font=New-Object System.Drawing.Font("Segoe UI",20,[System.Drawing.FontStyle]::Bold)
$title.Location=New-Object System.Drawing.Point(25,20)
$title.AutoSize=$true
$form.Controls.Add($title)
$info=New-Object System.Windows.Forms.Label
$info.Text="Yalnz installer-in quradrd dependency v shortcut silinir."+[Environment]::NewLine+"stifadi konfiqurasiyas v mlumatlar qorunur."
$info.Location=New-Object System.Drawing.Point(28,65)
$info.AutoSize=$true
$form.Controls.Add($info)

$nodeMarker=Join-Path $root "installer\.node-installed-by-agent"
$nodeOwned=Test-Path $nodeMarker
$nodeCb=New-Object System.Windows.Forms.CheckBox
$nodeCb.Text="Node.js-i sil (yalnz bu installer quradrbsa)"
$nodeCb.Checked=$false
$nodeCb.Enabled=$nodeOwned
$nodeCb.Location=New-Object System.Drawing.Point(35,125)
$nodeCb.AutoSize=$true
$form.Controls.Add($nodeCb)
$nodeInfo=New-Object System.Windows.Forms.Label
if($nodeOwned){ $nodeInfo.Text="Node.js bu installer trfindn quradrlb." } else { $nodeInfo.Text="Node.js sistemd mvcuddur v installer trfindn silinmyck." }
$nodeInfo.Location=New-Object System.Drawing.Point(55,150)
$nodeInfo.AutoSize=$true
$form.Controls.Add($nodeInfo)
$warning=New-Object System.Windows.Forms.Label
$warning.Text="Qorunacaq: .env, config, data, logs, temp, uploads, database, credentials v digr istifadi fayllar."
$warning.Location=New-Object System.Drawing.Point(28,190)
$warning.MaximumSize=New-Object System.Drawing.Size(575,0)
$warning.AutoSize=$true
$form.Controls.Add($warning)
$status=New-Object System.Windows.Forms.Label
$status.Text="Hazr"
$status.Location=New-Object System.Drawing.Point(28,245)
$status.AutoSize=$true
$form.Controls.Add($status)
$cancel=New-Object System.Windows.Forms.Button
$cancel.Text="Lv et"
$cancel.Location=New-Object System.Drawing.Point(315,285)
$cancel.Size=New-Object System.Drawing.Size(95,40)
$cancel.Add_Click({ $form.Close() })
$form.Controls.Add($cancel)
$uninstall=New-Object System.Windows.Forms.Button
$uninstall.Text="Uninstall"
$uninstall.Location=New-Object System.Drawing.Point(420,285)
$uninstall.Size=New-Object System.Drawing.Size(150,40)
$form.Controls.Add($uninstall)

$uninstall.Add_Click({
  $uninstall.Enabled=$false; $cancel.Enabled=$false
  try {
    $status.Text="Agent proseslri dayandrlr..."
    StopAppProcesses
    $nodeModules=Join-Path $root "node_modules"
    if(Test-Path $nodeModules){ $status.Text="Dependency-lr silinir..."; RemovePath $nodeModules }
    $desktop=[Environment]::GetFolderPath("Desktop")
    $shortcut=Join-Path $desktop "$app.lnk"
    if(Test-Path $shortcut){ $status.Text="Desktop shortcut silinir..."; Remove-Item -LiteralPath $shortcut -Force -ErrorAction Stop }
    if($nodeCb.Checked -and $nodeOwned){
      $winget=Get-Command winget.exe -ErrorAction SilentlyContinue
      if(-not$winget){ throw "Node.js silinmsi n winget taplmad." }
      $status.Text="Installer-in quradrd Node.js silinir..."
      $p=Start-Process $winget.Source -ArgumentList "uninstall --id OpenJS.NodeJS.LTS -e --silent" -Wait -PassThru -NoNewWindow
      if($p.ExitCode -ne 0){ throw "Node.js uninstall uursuz oldu. Exit code: $($p.ExitCode)" }
      RemovePath $nodeMarker
    }
    $status.Text="Uninstall tamamland."
    [System.Windows.Forms.MessageBox]::Show("Uninstall tamamland."+[Environment]::NewLine+[Environment]::NewLine+"Qorunan mlumatlar: .env, config, data, logs, temp, uploads, database v credentials.",$app,"OK","Information") | Out-Null
    $form.Close()
  } catch {
    $status.Text="Xta"
    [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,"Uninstall xtas","OK","Error") | Out-Null
    $uninstall.Enabled=$true; $cancel.Enabled=$true
  }
})
[void]$form.ShowDialog()
