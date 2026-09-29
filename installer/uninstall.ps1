Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
try { [System.Windows.Forms.Application]::SetUnhandledExceptionMode([System.Windows.Forms.UnhandledExceptionMode]::CatchException) } catch {}
[System.Windows.Forms.Application]::add_ThreadException({ param($s,$e) try { Add-Content -LiteralPath $logFile -Value ("GÖZLƏNILMƏZ XƏTA: "+$e.Exception.ToString()) -Encoding UTF8 } catch {}; [System.Windows.Forms.MessageBox]::Show($e.Exception.Message,"Gözlənilməz xəta","OK","Error") | Out-Null })
$ErrorActionPreference="Stop"
$root=(Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$app="YouTube AI Agent"
$logFile=Join-Path $PSScriptRoot "uninstall.log"
$script:busy=$false

function Pump { [System.Windows.Forms.Application]::DoEvents() }
function Log($t){ $log.AppendText($t+[Environment]::NewLine); try { Add-Content -LiteralPath $logFile -Value $t -Encoding UTF8 } catch {}; Pump }
function SetProgress($v,$text){
  if($v -ne $null){ $bar.Style="Continuous"; $bar.Value=[Math]::Max(0,[Math]::Min(100,[int]$v)); $pct.Text="$([int]$bar.Value)%" }
  if($text){ $status.Text=$text; Log ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $text) }
  Pump
}
# Qovluğu gizli silir, UI donmur
function RemoveDirAsync($path){
  $p=Start-Process cmd.exe -ArgumentList "/c rmdir /s /q `"$path`"" -WindowStyle Hidden -PassThru
  $sw=[Diagnostics.Stopwatch]::StartNew()
  while(-not $p.HasExited){ $time.Text="Keçən vaxt: "+$sw.Elapsed.ToString("mm\:ss"); Pump; Start-Sleep -Milliseconds 150 }
  if(Test-Path -LiteralPath $path){ throw "$path tam silinmədi. Fayllar başqa proqram tərəfindən istifadə oluna bilər." }
}
function StopAppProcesses {
  $rootFull=$root.TrimEnd("\")
  $all=@(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)
  # Bu installer prosesi və bütün valideynləri (cmd / powershell / explorer) HEÇ VAXT dayandırılmır
  $protected=@{}
  $id=$PID
  while($id -and -not $protected.ContainsKey([int]$id)){
    $protected[[int]$id]=$true
    $par=$all | Where-Object { $_.ProcessId -eq $id } | Select-Object -First 1
    if($par){ $id=$par.ParentProcessId } else { $id=0 }
  }
  $targets=@{}
  # 1) Bu qovluqdan işləyən node prosesləri
  foreach($p in $all){
    if($protected.ContainsKey([int]$p.ProcessId)){ continue }
    if($p.Name -ieq "node.exe" -and $p.CommandLine -and $p.CommandLine -like "*$rootFull*"){ $targets[[int]$p.ProcessId]=$true }
  }
  # 2) Dashboard portunu (3456) tutan proses
  try {
    foreach($c in @(Get-NetTCPConnection -LocalPort 3456 -State Listen -ErrorAction SilentlyContinue)){
      if(-not $protected.ContainsKey([int]$c.OwningProcess)){ $targets[[int]$c.OwningProcess]=$true }
    }
  } catch {}
  # 3) Onların alt prosesləri
  $changed=$true
  while($changed){
    $changed=$false
    foreach($p in $all){
      if($protected.ContainsKey([int]$p.ProcessId)){ continue }
      if($targets.ContainsKey([int]$p.ParentProcessId) -and -not $targets.ContainsKey([int]$p.ProcessId)){ $targets[[int]$p.ProcessId]=$true; $changed=$true }
    }
  }
  if($targets.Count -eq 0){ Log "Dayandırılacaq agent prosesi yoxdur." }
  foreach($tid in @($targets.Keys)){
    try { Stop-Process -Id $tid -Force -ErrorAction Stop; Log "Proses dayandırıldı: PID $tid" } catch {}
  }
  Start-Sleep -Seconds 1
}
function RemovePath($path) {
  if(Test-Path -LiteralPath $path){ Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction Stop; Log "Silindi: $path" }
}

$form=New-Object System.Windows.Forms.Form
$form.Text="$app - Uninstall"
$form.Size=New-Object System.Drawing.Size(720,600)
$form.StartPosition="CenterScreen"
$form.FormBorderStyle="FixedDialog"
$form.MaximizeBox=$false
$form.MinimizeBox=$false
$form.Add_FormClosing({ if($script:busy){ $_.Cancel=$true } })
$title=New-Object System.Windows.Forms.Label
$title.Text="$app - Uninstall"
$title.Font=New-Object System.Drawing.Font("Segoe UI",20,[System.Drawing.FontStyle]::Bold)
$title.Location=New-Object System.Drawing.Point(25,15)
$title.AutoSize=$true
$form.Controls.Add($title)
$info=New-Object System.Windows.Forms.Label
$info.Text="Dependency-lər (node_modules), launch faylları və Desktop shortcut silinir."+[Environment]::NewLine+"Qorunur: .env, config, data, logs, temp, uploads, database, credentials."
$info.Location=New-Object System.Drawing.Point(28,60)
$info.AutoSize=$true
$form.Controls.Add($info)

$nodeMarker=Join-Path $root "installer\.node-installed-by-agent"
$nodeOwned=Test-Path $nodeMarker
$nodeCb=New-Object System.Windows.Forms.CheckBox
$nodeCb.Text="Node.js-i sil (yalnız bu installer quraşdırıbsa)"
$nodeCb.Checked=$false
$nodeCb.Enabled=$nodeOwned
$nodeCb.Location=New-Object System.Drawing.Point(35,105)
$nodeCb.AutoSize=$true
$form.Controls.Add($nodeCb)
$nodeInfo=New-Object System.Windows.Forms.Label
if($nodeOwned){ $nodeInfo.Text="Node.js bu installer tərəfindən quraşdırılıb." } else { $nodeInfo.Text="Node.js sistemdə mövcuddur və installer tərəfindən silinməyəcək." }
$nodeInfo.Location=New-Object System.Drawing.Point(55,128)
$nodeInfo.AutoSize=$true
$form.Controls.Add($nodeInfo)

$status=New-Object System.Windows.Forms.Label
$status.Text="Hazır"
$status.Font=New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$status.Location=New-Object System.Drawing.Point(28,165)
$status.Size=New-Object System.Drawing.Size(560,22)
$form.Controls.Add($status)
$time=New-Object System.Windows.Forms.Label
$time.Text=""
$time.Location=New-Object System.Drawing.Point(28,190)
$time.AutoSize=$true
$form.Controls.Add($time)
$bar=New-Object System.Windows.Forms.ProgressBar
$bar.Location=New-Object System.Drawing.Point(28,215)
$bar.Size=New-Object System.Drawing.Size(600,24)
$bar.Minimum=0; $bar.Maximum=100; $bar.MarqueeAnimationSpeed=30
$form.Controls.Add($bar)
$pct=New-Object System.Windows.Forms.Label
$pct.Text="0%"
$pct.Location=New-Object System.Drawing.Point(640,219)
$pct.AutoSize=$true
$form.Controls.Add($pct)
$log=New-Object System.Windows.Forms.TextBox
$log.Multiline=$true; $log.ReadOnly=$true; $log.ScrollBars="Vertical"; $log.WordWrap=$true
$log.Font=New-Object System.Drawing.Font("Consolas",9)
$log.BackColor=[System.Drawing.Color]::FromArgb(30,30,30)
$log.ForeColor=[System.Drawing.Color]::Gainsboro
$log.Location=New-Object System.Drawing.Point(28,255)
$log.Size=New-Object System.Drawing.Size(650,240)
$form.Controls.Add($log)
$cancel=New-Object System.Windows.Forms.Button
$cancel.Text="Bağla"
$cancel.Location=New-Object System.Drawing.Point(378,510)
$cancel.Size=New-Object System.Drawing.Size(95,38)
$cancel.Add_Click({ $form.Close() })
$form.Controls.Add($cancel)
$uninstall=New-Object System.Windows.Forms.Button
$uninstall.Text="Uninstall"
$uninstall.Location=New-Object System.Drawing.Point(488,510)
$uninstall.Size=New-Object System.Drawing.Size(190,38)
$form.Controls.Add($uninstall)

$uninstall.Add_Click({
  $uninstall.Enabled=$false; $cancel.Enabled=$false; $nodeCb.Enabled=$false; $script:busy=$true
  $log.Clear()
  Remove-Item -LiteralPath $logFile -Force -ErrorAction SilentlyContinue
  try {
    SetProgress 5 "Agent prosesləri dayandırılır..."
    StopAppProcesses

    SetProgress 15 "Desktop shortcut silinir..."
    $desktop=[Environment]::GetFolderPath("Desktop")
    RemovePath (Join-Path $desktop "$app.lnk")

    SetProgress 25 "Launch faylları silinir..."
    RemovePath (Join-Path $PSScriptRoot "launch.bat")
    RemovePath (Join-Path $PSScriptRoot "launcher.ps1")

    $nodeModules=Join-Path $root "node_modules"
    if(Test-Path -LiteralPath $nodeModules){
      SetProgress 30 "Dependency-lər (node_modules) silinir..."
      $bar.Style="Marquee"
      RemoveDirAsync $nodeModules
      $bar.Style="Continuous"
      Log "Silindi: $nodeModules"
    } else { Log "node_modules artıq yoxdur." }

    if($nodeCb.Checked -and $nodeOwned){
      SetProgress 85 "Installer-in quraşdırdığı Node.js silinir..."
      $winget=Get-Command winget.exe -ErrorAction SilentlyContinue
      if(-not $winget){ throw "Node.js silinməsi üçün winget tapılmadı." }
      $p=Start-Process $winget.Source -ArgumentList "uninstall --id OpenJS.NodeJS.LTS -e --silent" -PassThru -WindowStyle Hidden
      while(-not $p.HasExited){ Pump; Start-Sleep -Milliseconds 150 }
      $p.WaitForExit()
      if($p.ExitCode -ne 0){ throw "Node.js uninstall uğursuz oldu. Exit code: $($p.ExitCode)" }
      RemovePath $nodeMarker
    }
    $time.Text=""
    SetProgress 100 "Uninstall tamamlandı."
    [System.Windows.Forms.MessageBox]::Show("Uninstall tamamlandı."+[Environment]::NewLine+[Environment]::NewLine+"Qorunan məlumatlar: .env, config, data, logs, temp, uploads, database və credentials.",$app,"OK","Information") | Out-Null
    $script:busy=$false
    $form.Close()
  } catch {
    $bar.Style="Continuous"
    $status.Text="Xəta"
    Log ""; Log ("XƏTA: "+$_.Exception.Message)
    [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,"Uninstall xətası","OK","Error") | Out-Null
    $uninstall.Enabled=$true
  } finally { $script:busy=$false; $cancel.Enabled=$true }
})
try { [void]$form.ShowDialog() } catch { [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,"Xəta","OK","Error") | Out-Null; exit 1 }
