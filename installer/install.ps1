Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference="Stop"
$root=(Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$app="YouTube AI Agent"

function NodePath {
  $c=Get-Command node.exe -ErrorAction SilentlyContinue
  if($c){ return $c.Source }
  foreach($p in @("$env:ProgramFiles\nodejs\node.exe","$env:LOCALAPPDATA\Programs\nodejs\node.exe")){
    if(Test-Path $p){ return $p }
  }
}
function EnsureNode {
  $n=NodePath
  if($n){
    $m=[int]((& $n --version).TrimStart("v").Split(".")[0])
    if($m -ge 18){ return $n }
  }
  $answer=[System.Windows.Forms.MessageBox]::Show("Node.js 18+ tapılmadı. Node.js LTS quraşdırılsın?",$app,"YesNo","Question")
  if($answer -ne "Yes"){ throw "Node.js quraşdırılmadı." }
  $w=Get-Command winget.exe -ErrorAction SilentlyContinue
  if(-not $w){ throw "winget tapılmadı. Node.js-i manual quraşdırın və installer-i yenidən başladın." }
  Start-Process $w.Source -ArgumentList "install --id OpenJS.NodeJS.LTS -e --source winget --accept-source-agreements --accept-package-agreements --silent" -Wait -NoNewWindow
  $n=NodePath
  if(-not$n){ throw "Node.js quraşdırılmadı." }
  Set-Content (Join-Path $root "installer\.node-installed-by-agent") "1" -Encoding ASCII
  return $n
}
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
function CreateShortcut {
  $desktop=[Environment]::GetFolderPath("Desktop")
  $shortcutPath=Join-Path $desktop "$app.lnk"
  $shell=New-Object -ComObject WScript.Shell
  $shortcut=$shell.CreateShortcut($shortcutPath)
  $shortcut.TargetPath="$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
  $q=[char]34
  $shortcut.Arguments="-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File $q$root\installer\launcher.ps1$q"
  $shortcut.WorkingDirectory=$root
  $shortcut.Description="Start $app"
  $shortcut.Save()
}

$form=New-Object System.Windows.Forms.Form
$form.Text="$app - Quraşdırma"
$form.Size=New-Object System.Drawing.Size(620,330)
$form.StartPosition="CenterScreen"
$form.FormBorderStyle="FixedDialog"
$form.MaximizeBox=$false
$form.MinimizeBox=$false
$title=New-Object System.Windows.Forms.Label
$title.Text="$app"
$title.Font=New-Object System.Drawing.Font("Segoe UI",20,[System.Drawing.FontStyle]::Bold)
$title.Location=New-Object System.Drawing.Point(25,20)
$title.AutoSize=$true
$form.Controls.Add($title)
$info=New-Object System.Windows.Forms.Label
$info.Text="Yalnız runtime və dependency quraşdırılır."+[Environment]::NewLine+"Konfiqurasiya, credentials, database və istifadəçi məlumatlarına toxunulmur."
$info.Location=New-Object System.Drawing.Point(28,65)
$info.AutoSize=$true
$form.Controls.Add($info)
$status=New-Object System.Windows.Forms.Label
$status.Text="Hazır"
$status.Location=New-Object System.Drawing.Point(28,125)
$status.AutoSize=$true
$form.Controls.Add($status)
$install=New-Object System.Windows.Forms.Button
$install.Text="Quraşdır"
$install.Location=New-Object System.Drawing.Point(380,190)
$install.Size=New-Object System.Drawing.Size(190,40)
$form.Controls.Add($install)
$cancel=New-Object System.Windows.Forms.Button
$cancel.Text="Ləğv et"
$cancel.Location=New-Object System.Drawing.Point(270,190)
$cancel.Size=New-Object System.Drawing.Size(95,40)
$cancel.Add_Click({ $form.Close() })
$form.Controls.Add($cancel)
$install.Add_Click({
  $install.Enabled=$false; $cancel.Enabled=$false
  try {
    $status.Text="Node.js yoxlanılır..."
    $n=EnsureNode
    $env:Path=(Split-Path $n -Parent)+";"+$env:Path
    $npm=Get-Command npm.cmd -ErrorAction SilentlyContinue
    if(-not$npm){ throw "npm tapılmadı." }
    $status.Text="İşləyən agent dayandırılır..."
    StopAppProcesses
    $status.Text="Dependency-lər quraşdırılır..."
    $p=Start-Process $npm.Source -ArgumentList "ci --no-audit --no-fund" -WorkingDirectory $root -Wait -PassThru -WindowStyle Hidden
    if($p.ExitCode -ne 0){ throw "npm ci uğursuz oldu. Exit code: $($p.ExitCode)" }
    $status.Text="Desktop shortcut yaradılır..."
    CreateShortcut
    $status.Text="Quraşdırma tamamlandı."
    [System.Windows.Forms.MessageBox]::Show("Quraşdırma tamamlandı."+[Environment]::NewLine+[Environment]::NewLine+"Heç bir AI/API/Google/kanal konfiqurasiyası bu mərhələdə yazılmadı."+[Environment]::NewLine+[Environment]::NewLine+"Konfiqurasiyanı proqramın Settings bölməsindən daxil edin.",$app,"OK","Information") | Out-Null
    $form.Close()
  } catch {
    $status.Text="Xəta"
    [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,"Quraşdırma xətası","OK","Error") | Out-Null
    $install.Enabled=$true; $cancel.Enabled=$true
  }
})
[void]$form.ShowDialog()
