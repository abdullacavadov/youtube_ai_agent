function S($s){[regex]::Unescape($s)}
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference="Stop"
$root=(Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$app="YouTube AI Agent"
function NodePath { $c=Get-Command node.exe -ErrorAction SilentlyContinue;if($c){return $c.Source};foreach($p in @("$env:ProgramFiles\nodejs\node.exe","$env:LOCALAPPDATA\Programs\nodejs\node.exe")){if(Test-Path $p){return $p}};return $null }
function EnsureNode { $n=NodePath;if($n){$m=[int]((& $n --version).TrimStart("v").Split(".")[0]);if($m-ge 18){return $n}};if([System.Windows.Forms.MessageBox]::Show("Node.js 18+ tap$(S '\u0131')lmad$(S '\u0131'). Node.js LTS qura$(S '\u015f')d$(S '\u0131')r$(S '\u0131')ls$(S '\u0131')n?",$app,"YesNo","Question")-ne "Yes"){throw "Node.js qura$(S '\u015f')d$(S '\u0131')r$(S '\u0131')lmad$(S '\u0131')."};$w=Get-Command winget.exe -ErrorAction SilentlyContinue;if(-not $w){throw "winget tap$(S '\u0131')lmad$(S '\u0131'). Node.js LTS qura$(S '\u015f')d$(S '\u0131')r$(S '\u0131')n v$(S '\u0259') installer-i yenid$(S '\u0259')n ba$(S '\u015f')lad$(S '\u0131')n."};Start-Process $w.Source -ArgumentList "install --id OpenJS.NodeJS.LTS -e --source winget --accept-source-agreements --accept-package-agreements --silent" -Wait -NoNewWindow;$n=NodePath;if(-not $n){throw "Node.js tap$(S '\u0131')lmad$(S '\u0131'). Installer-i yenid$(S '\u0259')n ba$(S '\u015f')lad$(S '\u0131')n."};Set-Content (Join-Path $root "installer\.node-installed-by-agent") "1" -Encoding ASCII;return $n }
function StopAppProcesses {
  $rootFull=$root.TrimEnd("\\")
  $all=Get-CimInstance Win32_Process -ErrorAction SilentlyContinue
  $targets=@{}
  foreach($p in $all){
    if($p.ProcessId -eq $PID){ continue }
    if($p.CommandLine -and ($p.CommandLine -like "*$rootFull*" -or $p.CommandLine -like "*youtube_ai_agent*")){
      $targets[$p.ProcessId]=$true
    }
  }
  $changed=$true
  while($changed){
    $changed=$false
    foreach($p in $all){
      if($targets.ContainsKey($p.ParentProcessId) -and -not $targets.ContainsKey($p.ProcessId)){
        $targets[$p.ProcessId]=$true
        $changed=$true
      }
    }
  }
  foreach($p in $all | Where-Object { $targets.ContainsKey($_.ProcessId) }){
    try { Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop } catch {}
  }
  Start-Sleep -Seconds 2
}

function Prep { foreach($d in @("config","logs","data","data/production","data/assets","data/videos","data/audio","data/scripts","data/captions","temp/processing","uploads/thumbnails")){New-Item -ItemType Directory -Force (Join-Path $root $d)|Out-Null};$e=Join-Path $root ".env";if(-not(Test-Path $e)){@("NODE_ENV=production","PORT=3456","LOG_LEVEL=info","DEFAULT_PRIVACY_STATUS=private","ENABLE_ANALYTICS=true","ANALYTICS_DB_PATH=./data/analytics.db","UPLOAD_PATH=./uploads","MAX_CONCURRENT_JOBS=1")|Set-Content $e -Encoding UTF8} }
function SaveKey($provider,$key){if([string]::IsNullOrWhiteSpace($key)){return};$p=Join-Path $root "config\credentials.json";$c=@{};if(Test-Path $p){try{$o=Get-Content $p -Raw|ConvertFrom-Json;foreach($x in $o.PSObject.Properties){$c[$x.Name]=$x.Value}}catch{}};if($provider-eq"Google Gemini"){$c.gemini=[ordered]@{apiKey=$key}}elseif($provider-eq"OpenAI"){$c.openai=[ordered]@{apiKey=$key}}else{$c.aiProvider=[ordered]@{provider="openrouter";apiKey=$key}};$c|ConvertTo-Json -Depth 10|Set-Content $p -Encoding UTF8}
function Shortcut {$d=[Environment]::GetFolderPath("Desktop");$s=New-Object -ComObject WScript.Shell;$l=$s.CreateShortcut((Join-Path $d "$app.lnk"));$l.TargetPath="$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe";$q=[char]34;$l.Arguments="-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File $q$root\installer\launcher.ps1$q";$l.WorkingDirectory=$root;$l.Description="Start $app";$l.Save()}
$f=New-Object System.Windows.Forms.Form;$f.Text="$app - Qura$(S '\u015f')d$(S '\u0131')rma";$f.Size=New-Object System.Drawing.Size(700,540);$f.StartPosition="CenterScreen";$f.FormBorderStyle="FixedDialog";$f.MaximizeBox=$false
$t=New-Object System.Windows.Forms.Label;$t.Text=$app;$t.Font=New-Object System.Drawing.Font("Segoe UI",22,[System.Drawing.FontStyle]::Bold);$t.Location=New-Object System.Drawing.Point(30,25);$t.AutoSize=$true;$f.Controls.Add($t)
$p=New-Object System.Windows.Forms.Label;$p.Text="AI provayderi:";$p.Location=New-Object System.Drawing.Point(30,90);$p.AutoSize=$true;$f.Controls.Add($p)
$provider=New-Object System.Windows.Forms.ComboBox;$provider.DropDownStyle="DropDownList";$provider.Items.AddRange(@("Google Gemini","OpenAI","OpenRouter"));$provider.SelectedIndex=0;$provider.Location=New-Object System.Drawing.Point(140,86);$provider.Size=New-Object System.Drawing.Size(220,25);$f.Controls.Add($provider)
$k=New-Object System.Windows.Forms.Label;$k.Text="API key:";$k.Location=New-Object System.Drawing.Point(30,130);$k.AutoSize=$true;$f.Controls.Add($k)
$key=New-Object System.Windows.Forms.TextBox;$key.UseSystemPasswordChar=$true;$key.Location=New-Object System.Drawing.Point(140,126);$key.Size=New-Object System.Drawing.Size(490,25);$f.Controls.Add($key)
$h=New-Object System.Windows.Forms.Label;$h.Text="API key ist$(S '\u0259')y$(S '\u0259') g$(S '\u00f6')r$(S '\u0259')dir."; $h.Location=New-Object System.Drawing.Point(140,158);$h.AutoSize=$true;$f.Controls.Add($h)
$log=New-Object System.Windows.Forms.TextBox;$log.Multiline=$true;$log.ReadOnly=$true;$log.ScrollBars="Vertical";$log.Location=New-Object System.Drawing.Point(30,200);$log.Size=New-Object System.Drawing.Size(620,220);$f.Controls.Add($log)
$b=New-Object System.Windows.Forms.Button;$b.Text="Qura$(S '\u015f')d$(S '\u0131')r";$b.Location=New-Object System.Drawing.Point(500,440);$b.Size=New-Object System.Drawing.Size(150,35);$f.Controls.Add($b)
$b.Add_Click({$b.Enabled=$false;try{$log.AppendText("Node.js yoxlan$(S '\u0131')l$(S '\u0131')r...`r`n");$n=EnsureNode;$env:Path="$(Split-Path $n -Parent);$env:Path";$npm=Get-Command npm.cmd -ErrorAction SilentlyContinue;if(-not$npm){throw "npm tap$(S '\u0131')lmad$(S '\u0131')."};$log.AppendText("Fayllar haz$(S '\u0131')rlan$(S '\u0131')r...`r`n");StopAppProcesses;$log.AppendText("Agent prosesl$(S '\u0259')ri dayandirilir...`r`n");Prep;$log.AppendText("npm ci i$(S '\u015f')l$(S '\u0259')yir...`r`n");$psi=New-Object Diagnostics.ProcessStartInfo;$psi.FileName=$npm.Source;$psi.Arguments="ci --no-audit --no-fund";$psi.WorkingDirectory=$root;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true;$psi.CreateNoWindow=$true;$pr=New-Object Diagnostics.Process;$pr.StartInfo=$psi;[void]$pr.Start();$log.AppendText($pr.StandardOutput.ReadToEnd());$log.AppendText($pr.StandardError.ReadToEnd());$pr.WaitForExit();if($pr.ExitCode-ne 0){throw "npm ci u$(S '\u011f')ursuz oldu."};SaveKey $provider.SelectedItem $key.Text;Shortcut;$log.AppendText("Qura$(S '\u015f')d$(S '\u0131')rma tamamland$(S '\u0131').`r`n");if([System.Windows.Forms.MessageBox]::Show("Desktop shortcut yarad$(S '\u0131')ld$(S '\u0131'). Proqram indi a$(S '\u00e7')$(S '\u0131')ls$(S '\u0131')n?",$app,"YesNo","Information")-eq"Yes"){Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$root\installer\launcher.ps1`""};$f.Close()}catch{[System.Windows.Forms.MessageBox]::Show($_.Exception.Message,"Qura$(S '\u015f')d$(S '\u0131')rma x$(S '\u0259')tas$(S '\u0131')","OK","Error")|Out-Null;$b.Enabled=$true}})
[void]$f.ShowDialog()