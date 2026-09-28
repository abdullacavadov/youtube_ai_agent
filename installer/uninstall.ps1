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
$form.Text="$app - Təmizləmə"
$form.Size=New-Object System.Drawing.Size(700,570)
$form.StartPosition="CenterScreen"
$form.FormBorderStyle="FixedDialog"
$form.MaximizeBox=$false
$title=New-Object System.Windows.Forms.Label
$title.Text="$app — Test üçün təmizləmə"
$title.Font=New-Object System.Drawing.Font("Segoe UI",20,[System.Drawing.FontStyle]::Bold)
$title.Location=New-Object System.Drawing.Point(25,20)
$title.AutoSize=$true
$form.Controls.Add($title)
$info=New-Object System.Windows.Forms.Label
$info.Text="Mənbə kodu saxlanılır. Seçilmiş quraşdırma və runtime faylları silinir."
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
$nodeCb.Text="Node.js-i də sil (yalnız bu installer quraşdırıbsa)"
$nodeCb.Checked=$false
$nodeCb.Enabled=$nodeOwned
$nodeCb.Location=New-Object System.Drawing.Point(35,$y+5)
$nodeCb.AutoSize=$true
$form.Controls.Add($nodeCb)
$warning=New-Object System.Windows.Forms.Label
$warning.Text=if($nodeOwned){"Node.js bu installer tərəfindən quraşdırılıb."}else{"Node.js sistemdə artıq mövcuddur; uninstall onu silməyəcək."}
$warning.Location=New-Object System.Drawing.Point(55,$y+32)
$warning.AutoSize=$true
$form.Controls.Add($warning)
$log=New-Object System.Windows.Forms.TextBox
$log.Multiline=$true
$log.ReadOnly=$true
$log.ScrollBars="Vertical"
$log.Location=New-Object System.Drawing.Point(30,$y+65)
$log.Size=New-Object System.Drawing.Size(620,120)
$form.Controls.Add($log)
$cancel=New-Object System.Windows.Forms.Button
$cancel.Text="Ləğv et"
$cancel.Location=New-Object System.Drawing.Point(390,$y+200)
$cancel.Size=New-Object System.Drawing.Size(110,35)
$cancel.Add_Click({$form.Close()})
$form.Controls.Add($cancel)
$clean=New-Object System.Windows.Forms.Button
$clean.Text="Təmizlə"
$clean.Location=New-Object System.Drawing.Point(510,$y+200)
$clean.Size=New-Object System.Drawing.Size(140,35)
$form.Controls.Add($clean)
$clean.Add_Click({
  $clean.Enabled=$false; $cancel.Enabled=$false
  try {
    $log.AppendText("Agent prosesləri dayandırılır...`r`n")
    StopAppProcesses
    foreach($x in $checks){
      $cb=$x[0]; $name=$x[1]; if(-not $cb.Checked){continue}
      if($name -eq "__shortcut__"){ $desktop=[Environment]::GetFolderPath("Desktop"); $shortcut=Join-Path $desktop "$app.lnk"; if(Test-Path $shortcut){Remove-Item $shortcut -Force}; $log.AppendText("Desktop shortcut silindi.`r`n") }
      else { $path=Join-Path $root $name; RemovePath $path; $log.AppendText("$name silindi.`r`n") }
    }
    if($nodeCb.Checked -and $nodeOwned){
      $winget=Get-Command winget.exe -ErrorAction SilentlyContinue; if(-not $winget){throw "Node.js silinməsi üçün winget tapılmadı."}
      $log.AppendText("Node.js silinir...`r`n")
      Start-Process $winget.Source -ArgumentList "uninstall --id OpenJS.NodeJS.LTS -e --silent" -Wait -NoNewWindow
      RemovePath $nodeMarker; $log.AppendText("Node.js silindi.`r`n")
    }
    $log.AppendText("Təmizləmə tamamlandı.`r`n")
    [System.Windows.Forms.MessageBox]::Show("Təmizləmə tamamlandı.`r`n`r`nYenidən test etmək üçün install.bat faylını başladın.","$app","OK","Information")|Out-Null
    $form.Close()
  } catch { [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,"Təmizləmə xətası","OK","Error")|Out-Null; $clean.Enabled=$true; $cancel.Enabled=$true }
})
[void]$form.ShowDialog()