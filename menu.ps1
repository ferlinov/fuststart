# Settings
$dataDir = "$env:APPDATA\QuickMenu"
$dataFile = "$dataDir\items.txt"

# Load/Save
function LoadItems {
    if (-not (Test-Path $dataFile)) {
        $default = @(
            "Notepad=notepad",
            "Calculator=calc",
            "Explorer=explorer"
        )
        New-Item -ItemType Directory -Force $dataDir | Out-Null
        $default | Set-Content $dataFile
    }
    Get-Content $dataFile | Where-Object { $_ -match '=' } | ForEach-Object {
        $name, $cmd = $_ -split '=', 2
        [PSCustomObject]@{ Name = $name; Cmd = $cmd }
    }
}

function SaveItems($items) {
    $items | ForEach-Object { "$($_.Name)=$($_.Cmd)" } | Set-Content $dataFile
}

# Menu
$items = LoadItems
$selected = 0
$message = ""

function DrawMenu {
    Clear-Host
    Write-Host "========= QUICK MENU =========" -ForegroundColor Cyan
    for ($i = 0; $i -lt $items.Count; $i++) {
        $line = "{0} {1,-20} {2}" -f $(if ($i -eq $selected) { "->" } else { "  " }),
                                    $items[$i].Name, $items[$i].Cmd
        if ($i -eq $selected) {
            Write-Host $line -ForegroundColor Yellow -BackgroundColor DarkGray
        } else {
            Write-Host $line
        }
    }
    Write-Host "===============================" -ForegroundColor Cyan
    Write-Host "Arrows=move  Enter=run  A=add  Del=delete  Esc=exit"
    if ($message) { Write-Host $message -ForegroundColor Green }
}

while ($true) {
    DrawMenu
    $message = ""
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    switch ($key.VirtualKeyCode) {
        38 { if ($selected -gt 0) { $selected-- } }
        40 { if ($selected -lt $items.Count - 1) { $selected++ } }
        27 { exit }
        13 {
            try {
                Start-Process $items[$selected].Cmd
                $message = "Started: $($items[$selected].Name)"
            } catch {
                $message = "Error starting: $($items[$selected].Cmd)"
            }
        }
        65 {
            Write-Host ""
            $name = Read-Host "Item name"
            if ($name) {
                $cmd = Read-Host "Path or command (e.g. notepad or C:\app.exe)"
                if ($cmd) {
                    $items += [PSCustomObject]@{ Name = $name; Cmd = $cmd }
                    SaveItems $items
                    $message = "Added: $name"
                }
            }
        }
        46 {
            if ($items.Count -gt 0) {
                Write-Host ""
                $confirm = Read-Host "Delete '$($items[$selected].Name)'? (y/n)"
                if ($confirm -eq 'y') {
                    $items = $items | Where-Object { $_ -ne $items[$selected] }
                    SaveItems $items
                    if ($selected -ge $items.Count) { $selected = $items.Count - 1 }
                    $message = "Deleted"
                }
            }
        }
    }
}