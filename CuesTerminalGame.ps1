$ErrorActionPreference = 'Stop'

$savePath = Join-Path $PSScriptRoot 'save.json'

function Get-DefaultSave {
    return [ordered]@{
        credits = 0.0
        drones = 0
        refineries = 0
        lastTick = (Get-Date).ToString('o')
        totalClicks = 0
    }
}

function Load-Save {
    if (Test-Path $savePath) {
        try {
            $raw = Get-Content $savePath -Raw
            $data = $raw | ConvertFrom-Json
            return $data
        } catch {
            return (Get-DefaultSave)
        }
    }
    return (Get-DefaultSave)
}

function Save-Game([object]$data) {
    $data.lastTick = (Get-Date).ToString('o')
    $json = $data | ConvertTo-Json -Depth 4
    $json | Set-Content -Path $savePath
}

function Format-Number([double]$value) {
    if ($value -ge 1000000) {
        return "{0:N2}M" -f ($value / 1000000)
    }
    if ($value -ge 1000) {
        return "{0:N2}K" -f ($value / 1000)
    }
    return "{0:N0}" -f $value
}

function Get-DroneCost([int]$count) {
    return [math]::Floor(10 * [math]::Pow(1.15, $count))
}

function Get-RefineryCost([int]$count) {
    return [math]::Floor(100 * [math]::Pow(1.15, $count))
}

function Apply-OfflineEarnings([object]$data) {
    $last = [datetime]::Parse($data.lastTick)
    $now = Get-Date
    $seconds = [math]::Max(0, ($now - $last).TotalSeconds)
    $rate = ($data.drones * 0.5) + ($data.refineries * 2)
    $data.credits += $seconds * $rate
    return $seconds
}

$game = Load-Save
$offlineSeconds = Apply-OfflineEarnings -data $game

$lastFrame = Get-Date
$lastSave = Get-Date
$showOffline = $offlineSeconds -ge 1

try {
    while ($true) {
        $now = Get-Date
        $deltaSeconds = ($now - $lastFrame).TotalSeconds
        $lastFrame = $now

        $rate = ($game.drones * 0.5) + ($game.refineries * 2)
        $game.credits += $rate * $deltaSeconds

        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            switch ($key.Key) {
                'M' {
                    $game.credits += 1
                    $game.totalClicks += 1
                }
                'D' {
                    $cost = Get-DroneCost -count $game.drones
                    if ($game.credits -ge $cost) {
                        $game.credits -= $cost
                        $game.drones += 1
                    }
                }
                'R' {
                    $cost = Get-RefineryCost -count $game.refineries
                    if ($game.credits -ge $cost) {
                        $game.credits -= $cost
                        $game.refineries += 1
                    }
                }
                'S' { Save-Game -data $game }
                'Q' { break }
            }
        }

        if (($now - $lastSave).TotalSeconds -ge 5) {
            Save-Game -data $game
            $lastSave = $now
        }

        Clear-Host
        $droneCost = Get-DroneCost -count $game.drones
        $refineryCost = Get-RefineryCost -count $game.refineries
        $creditsDisplay = Format-Number -value $game.credits
        $rateDisplay = Format-Number -value $rate

        Write-Host "========================================="
        Write-Host "   CUES TERMINAL IDLE: ORBITAL DRIFT"
        Write-Host "========================================="
        Write-Host "            .      .      ."
        Write-Host "         .     .  /\\  .     ."
        Write-Host "       .       /====\\       ."
        Write-Host "   .       .  /|====|\\  .       ."
        Write-Host "         .   /_|____|_\\   ."
        Write-Host "             /_/____\_\\"
        Write-Host "          ___\_\____/_/___"
        Write-Host "         /________________\\"
        Write-Host "========================================="
        Write-Host "Credits: $creditsDisplay"
        Write-Host "Idle Rate: $rateDisplay / sec"
        Write-Host "Drones: $($game.drones) (cost: $droneCost)"
        Write-Host "Refineries: $($game.refineries) (cost: $refineryCost)"
        Write-Host "Manual mines: $($game.totalClicks)"
        if ($showOffline) {
            Write-Host "Offline earnings: $(Format-Number -value ($offlineSeconds * $rate)) credits"
            $showOffline = $false
        }
        Write-Host "========================================="
        Write-Host "[M] Mine  [D] Buy Drone  [R] Buy Refinery"
        Write-Host "[S] Save  [Q] Quit"
        Write-Host "Save file: $savePath"

        Start-Sleep -Milliseconds 200
    }
} finally {
    Save-Game -data $game
    Write-Host "Game saved. See you next time!"
}
