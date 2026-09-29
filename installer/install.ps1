Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
try { [System.Windows.Forms.Application]::SetUnhandledExceptionMode([System.Windows.Forms.UnhandledExceptionMode]::CatchException) } catch {}
[System.Windows.Forms.Application]::add_ThreadException({ param($s,$e) try { Add-Content -LiteralPath $logFile -Value ("GÖZLƏNILMƏZ XƏTA: "+$e.Exception.ToString()) -Encoding UTF8 } catch {}; [System.Windows.Forms.MessageBox]::Show($e.Exception.Message,"Gözlənilməz xəta","OK","Error") | Out-Null })
$ErrorActionPreference="Stop"
$root=(Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$app="YouTube AI Agent"
$launcherPath=Join-Path $PSScriptRoot "launcher.ps1"
$launchBatPath=Join-Path $PSScriptRoot "launch.bat"
$logFile=Join-Path $PSScriptRoot "install.log"
$script:busy=$false
$script:fetched=0

# launcher.ps1 yalnız quraşdırmadan sonra yaradılır (repo-da yoxdur)
$launcherContent=@'
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
'@

# ---------- UI köməkçiləri ----------
function Pump { [System.Windows.Forms.Application]::DoEvents() }
function Log($t){ $log.AppendText($t+[Environment]::NewLine); try { Add-Content -LiteralPath $logFile -Value $t -Encoding UTF8 } catch {}; Pump }
function SetProgress($v,$text){
  if($v -ne $null){ $bar.Style="Continuous"; $bar.Value=[Math]::Max(0,[Math]::Min(100,[int]$v)); $pct.Text="$([int]$bar.Value)%" }
  if($text){ $status.Text=$text; Log ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $text) }
  Pump
}

# Komandanı gizli işə salır, çıxışını canlı olaraq log qutusuna yazır (UI donmur)
function RunLogged($file,$arguments,$workDir,$onChunk){
  $tmp=[System.IO.Path]::GetTempFileName()
  $cmdLine="/c `"`"$file`" $arguments > `"$tmp`" 2>&1`""
  $p=Start-Process cmd.exe -ArgumentList $cmdLine -WorkingDirectory $workDir -WindowStyle Hidden -PassThru
  $state=@{pos=0L}; $sw=[Diagnostics.Stopwatch]::StartNew()
  $read={
    $fs=New-Object System.IO.FileStream($tmp,"Open","Read","ReadWrite")
    try {
      if($fs.Length -gt $state.pos){
        $fs.Seek($state.pos,"Begin") | Out-Null
        $buf=New-Object byte[] ($fs.Length-$state.pos)
        $n=$fs.Read($buf,0,$buf.Length); $state.pos+=$n
        $txt=[System.Text.Encoding]::UTF8.GetString($buf,0,$n)
        $log.AppendText($txt.Replace("`r`n","`n").Replace("`n",[Environment]::NewLine))
        if($onChunk){ & $onChunk $txt }
      }
    } finally { $fs.Close() }
  }
  while(-not $p.HasExited){
    & $read
    $time.Text="Keçən vaxt: "+$sw.Elapsed.ToString("mm\:ss")
    Pump; Start-Sleep -Milliseconds 150
  }
  $p.WaitForExit(); & $read
  Remove-Item $tmp -Force -ErrorAction SilentlyContinue
  return $p.ExitCode
}

# ---------- Node / proseslər / fayllar ----------
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
    if($m -ge 18){ Log "Node.js tapıldı: $n ($(& $n --version))"; return $n }
  }
  $answer=[System.Windows.Forms.MessageBox]::Show("Node.js 18+ tapılmadı. Node.js LTS quraşdırılsın?",$app,"YesNo","Question")
  if($answer -ne "Yes"){ throw "Node.js quraşdırılmadı." }
  $w=Get-Command winget.exe -ErrorAction SilentlyContinue
  if(-not $w){ throw "winget tapılmadı. Node.js-i manual quraşdırın və installer-i yenidən başladın." }
  SetProgress 6 "Node.js LTS quraşdırılır (winget)..."
  $bar.Style="Marquee"
  $code=RunLogged $w.Source "install --id OpenJS.NodeJS.LTS -e --source winget --accept-source-agreements --accept-package-agreements --silent" $root $null
  $bar.Style="Continuous"
  $n=NodePath
  if(-not $n){ throw "Node.js quraşdırılmadı (winget exit code: $code)." }
  Set-Content (Join-Path $root "installer\.node-installed-by-agent") "1" -Encoding ASCII
  return $n
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
function CreateLaunchFiles {
  # UTF-8 BOM ilə - PowerShell 5.1 üçün Azərbaycan hərfləri düzgün oxunur
  $utf8Bom=New-Object System.Text.UTF8Encoding($true)
  [System.IO.File]::WriteAllText($launcherPath,($launcherContent -replace "`r?`n","`r`n"),$utf8Bom)
  $bat="@echo off`r`npowershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"%~dp0launcher.ps1`"`r`n"
  [System.IO.File]::WriteAllText($launchBatPath,$bat,(New-Object System.Text.ASCIIEncoding))
}
function CreateShortcut {
  $desktop=[Environment]::GetFolderPath("Desktop")
  $shortcutPath=Join-Path $desktop "$app.lnk"
  $shell=New-Object -ComObject WScript.Shell
  $shortcut=$shell.CreateShortcut($shortcutPath)
  $shortcut.TargetPath="$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
  $q=[char]34
  $shortcut.Arguments="-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File $q$launcherPath$q"
  $shortcut.WorkingDirectory=$root
  $shortcut.Description="Start $app"
  $shortcut.Save()
  if(-not (Test-Path -LiteralPath $shortcutPath)){ throw "Desktop shortcut yaradıla bilmədi." }
  Log "Shortcut: $shortcutPath"
}

# ---------- Pəncərə ----------
$form=New-Object System.Windows.Forms.Form
$form.Text="$app - Quraşdırma"
$form.Size=New-Object System.Drawing.Size(720,560)
$form.StartPosition="CenterScreen"
$form.FormBorderStyle="FixedDialog"
$form.MaximizeBox=$false
$form.MinimizeBox=$false
$form.Add_FormClosing({ if($script:busy){ $_.Cancel=$true } })
$title=New-Object System.Windows.Forms.Label
$title.Text="$app"
$title.Font=New-Object System.Drawing.Font("Segoe UI",20,[System.Drawing.FontStyle]::Bold)
$title.Location=New-Object System.Drawing.Point(25,15)
$title.AutoSize=$true
$form.Controls.Add($title)
$info=New-Object System.Windows.Forms.Label
$info.Text="Yalnız runtime və dependency quraşdırılır."+[Environment]::NewLine+"Konfiqurasiya, credentials, database və istifadəçi məlumatlarına toxunulmur."
$info.Location=New-Object System.Drawing.Point(28,60)
$info.AutoSize=$true
$form.Controls.Add($info)
$status=New-Object System.Windows.Forms.Label
$status.Text="Hazır"
$status.Font=New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$status.Location=New-Object System.Drawing.Point(28,105)
$status.Size=New-Object System.Drawing.Size(560,22)
$form.Controls.Add($status)
$time=New-Object System.Windows.Forms.Label
$time.Text=""
$time.Location=New-Object System.Drawing.Point(28,130)
$time.AutoSize=$true
$form.Controls.Add($time)
$bar=New-Object System.Windows.Forms.ProgressBar
$bar.Location=New-Object System.Drawing.Point(28,155)
$bar.Size=New-Object System.Drawing.Size(600,24)
$bar.Minimum=0; $bar.Maximum=100; $bar.MarqueeAnimationSpeed=30
$form.Controls.Add($bar)
$pct=New-Object System.Windows.Forms.Label
$pct.Text="0%"
$pct.Location=New-Object System.Drawing.Point(640,159)
$pct.AutoSize=$true
$form.Controls.Add($pct)
$log=New-Object System.Windows.Forms.TextBox
$log.Multiline=$true; $log.ReadOnly=$true; $log.ScrollBars="Vertical"; $log.WordWrap=$true
$log.Font=New-Object System.Drawing.Font("Consolas",9)
$log.BackColor=[System.Drawing.Color]::FromArgb(30,30,30)
$log.ForeColor=[System.Drawing.Color]::Gainsboro
$log.Location=New-Object System.Drawing.Point(28,195)
$log.Size=New-Object System.Drawing.Size(650,270)
$form.Controls.Add($log)
$install=New-Object System.Windows.Forms.Button
$install.Text="Quraşdır"
$install.Location=New-Object System.Drawing.Point(488,478)
$install.Size=New-Object System.Drawing.Size(190,38)
$form.Controls.Add($install)
$cancel=New-Object System.Windows.Forms.Button
$cancel.Text="Bağla"
$cancel.Location=New-Object System.Drawing.Point(378,478)
$cancel.Size=New-Object System.Drawing.Size(95,38)
$cancel.Add_Click({ $form.Close() })
$form.Controls.Add($cancel)

$install.Add_Click({
  $install.Enabled=$false; $cancel.Enabled=$false; $script:busy=$true
  $log.Clear(); $script:fetched=0
  Remove-Item -LiteralPath $logFile -Force -ErrorAction SilentlyContinue
  try {
    SetProgress 2 "Fayllar yoxlanılır..."
    $pkg=Join-Path $root "package.json"; $lock=Join-Path $root "package-lock.json"
    if(-not (Test-Path -LiteralPath $pkg)){ throw "package.json tapılmadı:`n$pkg`n`nFayl silinib. Repo-nu yenidən klonlayın və ya 'git restore package.json package-lock.json' əmrini işlədin." }
    $hasLock=Test-Path -LiteralPath $lock
    $total=0
    if($hasLock){ $total=([regex]::Matches((Get-Content -LiteralPath $lock -Raw),'"node_modules/')).Count }
    if($hasLock){ Log "package.json və package-lock.json tapıldı (~$total paket)." } else { Log "package-lock.json yoxdur - 'npm install' istifadə olunacaq." }

    SetProgress 4 "Node.js yoxlanılır..."
    $n=EnsureNode
    $env:Path=(Split-Path $n -Parent)+";"+$env:Path
    $npm=Get-Command npm.cmd -ErrorAction SilentlyContinue
    if(-not $npm){ throw "npm tapılmadı." }

    SetProgress 8 "İşləyən agent dayandırılır..."
    StopAppProcesses

    SetProgress 10 "Dependency-lər quraşdırılır (bir neçə dəqiqə çəkə bilər)..."
    $npmCmd=if($hasLock){"ci"}else{"install"}
    if($total -le 0){ $bar.Style="Marquee" }
    $onChunk={
      param($txt)
      $script:fetched+=([regex]::Matches($txt,"http fetch GET")).Count
      if($total -gt 0){
        $v=10+[Math]::Min(78,[int](78*$script:fetched/$total))
        $bar.Style="Continuous"; $bar.Value=$v; $pct.Text="$v%"
        $status.Text="Dependency-lər yüklənir: $($script:fetched)/$total"
      }
    }
    $code=RunLogged $npm.Source "$npmCmd --no-audit --no-fund --loglevel=http --foreground-scripts" $root $onChunk
    $bar.Style="Continuous"
    if($code -ne 0){ throw "npm $npmCmd uğursuz oldu (exit code: $code). Ətraflı məlumat yuxarıdakı log-dadır." }
    if(-not (Test-Path -LiteralPath (Join-Path $root "node_modules"))){ throw "npm bitdi, amma node_modules yaranmadı." }

    SetProgress 92 "Launch faylları yaradılır..."
    CreateLaunchFiles
    SetProgress 96 "Desktop shortcut yaradılır..."
    CreateShortcut
    SetProgress 100 "Quraşdırma tamamlandı."
    $time.Text=""
    [System.Windows.Forms.MessageBox]::Show("Quraşdırma tamamlandı."+[Environment]::NewLine+[Environment]::NewLine+"Desktop-dakı '$app' shortcut-u ilə başladın."+[Environment]::NewLine+"Konfiqurasiyanı proqramın Settings bölməsindən daxil edin.",$app,"OK","Information") | Out-Null
    $script:busy=$false
    $form.Close()
  } catch {
    # Uğursuz olarsa yarımçıq launch faylı qalmasın
    Remove-Item -LiteralPath $launcherPath,$launchBatPath -Force -ErrorAction SilentlyContinue
    $bar.Style="Continuous"
    $status.Text="Xəta"
    Log ""; Log ("XƏTA: "+$_.Exception.Message)
    [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,"Quraşdırma xətası","OK","Error") | Out-Null
    $install.Text="Yenidən cəhd et"; $install.Enabled=$true; $cancel.Enabled=$true
  } finally {
    $script:busy=$false
    try { [System.IO.File]::WriteAllText($logFile,$log.Text,(New-Object System.Text.UTF8Encoding($true))) } catch {}
    $cancel.Enabled=$true
  }
})
try { [void]$form.ShowDialog() } catch { [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,"Xəta","OK","Error") | Out-Null; exit 1 }
