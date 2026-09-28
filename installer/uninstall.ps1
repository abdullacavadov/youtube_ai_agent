function S($s){[regex]::Unescape($s)}
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference="Stop"
$root=(Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$app="YouTube AI Agent"

function StopAppProcesses {
  $rootFull=$root.TrimEnd("\")
  $procs=Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessId -ne $PID -and $_.CommandLine -and (
      $_.CommandLine -like "*$rootFull*" -or
      $_.CommandLine -like "*youtube_ai_agent*" -or
      $_.CommandLine -match "npm(\.cmd)?\s+start"
    )
  }
  foreach($p in $procs){ try { Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop } catch {} }
  Start-Sleep -Milliseconds 800
}

function RemovePath($path) { if(Test-Path -LiteralPath $path){ Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction Stop } }

$form=New-Object System.Windows.Forms.Form
$form.Text="$app - T$(S '\u0259')mizl$(S '\u0259')m$(S '\u0259')"
$form.Size=New-Object System.Drawing.Size(700,570)
$form.StartPosition="CenterScreen"
$form.FormBorderStyle="Sizable"
$form.MaximizeBox=$true
$form.AutoScroll=$true
$form.AutoScrollMinSize=New-Object System.Drawing.Size(0,720)
$title=New-Object System.Windows.Forms.Label
$title.Text="$app $(S '\u2014') Test $(S '\u00fc')$(S '\u00e7')$(S '\u00fc')n t$(S '\u0259')mizl$(S '\u0259')m$(S '\u0259')"
$title.Font=New-Object System.Drawing.Font("Segoe UI",20,[System.Drawing.FontStyle]::Bold)
$title.Location=New-Object System.Drawing.Point(25,20)
$title.AutoSize=$true
$form.Controls.Add($title)
$info=New-Object System.Windows.Forms.Label
$info.Text="M$(S '\u0259')nb$(S '\u0259') kodu saxlan$(S '\u0131')l$(S '\u0131')r. Se$(S '\u00e7')ilmi$(S '\u015f') qura$(S '\u015f')d$(S '\u0131')rma v$(S '\u0259') runtime fayllar$(S '\u0131') silinir."
$info.Location=New-Object System.Drawing.Point(28,65)
$info.AutoSize=$true
$form.Controls.Add($info)
$checks=@()
$items=@(@("node_modules","node_modules",$true),@(".env",".env",$true),@("config","config",$true),@("data","data",$true),@("logs","logs",$true),@("temp","temp",$true),@("uploads","uploads",$true),@("Desktop shortcut","__shortcut__",$true))
$y=105
foreach($item in $items){ $cb=New-Object System.Windows.Forms.CheckBox; $cb.Text=$item[0]; $cb.Checked=[bool]$item[2]; $cb.Location=New-Object System.Drawing.Point(35,$y); $cb.AutoSize=$true; $form.Controls.Add($cb); $checks += ,@($cb,$item[1]); $y += 35 }
$nodeMarker=Join-Path $root "installer\.node-installed-by-agent"
$nodeOwned=Test-Path $nodeMarker
$nodeCb=New-Object System.Windows.Forms.CheckBox
$nodeCb.Text="Node.js-i d$(S '\u0259') sil (yaln$(S '\u0131')z bu installer qura$(S '\u015f')d$(S '\u0131')r$(S '\u0131')bsa)"
$nodeCb.Checked=$false
$nodeCb.Enabled=$nodeOwned
$nodeCb.Location=New-Object System.Drawing.Point(35,($y+5))
$nodeCb.AutoSize=$true
$form.Controls.Add($nodeCb)
$warning=New-Object System.Windows.Forms.Label
$warning.Text=if($nodeOwned){"Node.js bu installer t$(S '\u0259')r$(S '\u0259')find$(S '\u0259')n qura$(S '\u015f')d$(S '\u0131')r$(S '\u0131')l$(S '\u0131')b."}else{"Node.js sistemd$(S '\u0259') art$(S '\u0131')q m$(S '\u00f6')vcuddur; uninstall onu silm$(S '\u0259')y$(S '\u0259')c$(S '\u0259')k."}
$warning.Location=New-Object System.Drawing.Point(55,($y+32))
$warning.AutoSize=$true
$form.Controls.Add($warning)
$log=New-Object System.Windows.Forms.TextBox
$log.Multiline=$true
$log.ReadOnly=$true
$log.ScrollBars="Vertical"
$log.Location=New-Object System.Drawing.Point(30,($y+65))
$log.Size=New-Object System.Drawing.Size(620,120)
$form.Controls.Add($log)
$cancel=New-Object System.Windows.Forms.Button
$cancel.Text="L$(S '\u0259')$(S '\u011f')v et"
$cancel.Location=New-Object System.Drawing.Point(390,($y+200))
$cancel.Size=New-Object System.Drawing.Size(110,35)
$cancel.Add_Click({$form.Close()})
$form.Controls.Add($cancel)
$clean=New-Object System.Windows.Forms.Button
$clean.Text="T$(S '\u0259')mizl$(S '\u0259')"
$clean.Location=New-Object System.Drawing.Point(510,($y+200))
$clean.Size=New-Object System.Drawing.Size(140,35)
$form.Controls.Add($clean)
$clean.Add_Click({
  $clean.Enabled=$false; $cancel.Enabled=$false
  try {
    $log.AppendText("Agent prosesl$(S '\u0259')ri dayand$(S '\u0131')r$(S '\u0131')l$(S '\u0131')r...`r`n")
    StopAppProcesses
    foreach($x in $checks){
      $cb=$x[0]; $name=$x[1]; if(-not $cb.Checked){continue}
      if($name -eq "__shortcut__"){ $desktop=[Environment]::GetFolderPath("Desktop"); $shortcut=Join-Path $desktop "$app.lnk"; if(Test-Path $shortcut){Remove-Item $shortcut -Force}; $log.AppendText("Desktop shortcut silindi.`r`n") }
      else { $path=Join-Path $root $name; RemovePath $path; $log.AppendText("$name silindi.`r`n") }
    }
    if($nodeCb.Checked -and $nodeOwned){
      $winget=Get-Command winget.exe -ErrorAction SilentlyContinue; if(-not $winget){throw "Node.js silinm$(S '\u0259')si $(S '\u00fc')$(S '\u00e7')$(S '\u00fc')n winget tap$(S '\u0131')lmad$(S '\u0131')."}
      $log.AppendText("Node.js silinir...`r`n")
      Start-Process $winget.Source -ArgumentList "uninstall --id OpenJS.NodeJS.LTS -e --silent" -Wait -NoNewWindow
      RemovePath $nodeMarker; $log.AppendText("Node.js silindi.`r`n")
    }
    $log.AppendText("T$(S '\u0259')mizl$(S '\u0259')m$(S '\u0259') tamamland$(S '\u0131').`r`n")
    [System.Windows.Forms.MessageBox]::Show("T$(S '\u0259')mizl$(S '\u0259')m$(S '\u0259') tamamland$(S '\u0131').`r`n`r`nYenid$(S '\u0259')n test etm$(S '\u0259')k $(S '\u00fc')$(S '\u00e7')$(S '\u00fc')n install.bat fayl$(S '\u0131')n$(S '\u0131') ba$(S '\u015f')lad$(S '\u0131')n.","$app","OK","Information")|Out-Null
    $form.Close()
  } catch { [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,"T$(S '\u0259')mizl$(S '\u0259')m$(S '\u0259') x$(S '\u0259')tas$(S '\u0131')","OK","Error")|Out-Null; $clean.Enabled=$true; $cancel.Enabled=$true }
})
[void]$form.ShowDialog()