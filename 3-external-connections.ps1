# Мониторинг внешних подключений

Write-Host "=== ВНЕШНИЕ TCP СОЕДИНЕНИЯ (интернет) ===" -ForegroundColor Green
Write-Host "Процессы, которые выходят в интернет:`n" -ForegroundColor Yellow

Get-NetTCPConnection -State Established | Where-Object { 
    $_.RemoteAddress -ne "127.0.0.1" -and 
    $_.RemoteAddress -notmatch "^192\.168\." -and 
    $_.RemoteAddress -notmatch "^10\." -and 
    $_.RemoteAddress -notmatch "^172\.1[6-9]\."
} | ForEach-Object {
    $process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    $hostName = [System.Net.Dns]::GetHostEntryAsync($_.RemoteAddress).Result.HostName -ErrorAction SilentlyContinue 2>$null
    
    [PSCustomObject]@{
        "Процесс" = $process.ProcessName
        "Локальный IP" = $_.LocalAddress
        "Локальный порт" = $_.LocalPort
        "Удаленный хост" = if ($hostName) { $hostName } else { "Неизвестно" }
        "Удаленный IP" = $_.RemoteAddress
        "Удаленный порт" = $_.RemotePort
    }
} | Format-Table -AutoSize

Write-Host "`n=== СТАТИСТИКА ===" -ForegroundColor Green
$externalConnections = (Get-NetTCPConnection -State Established | Where-Object { 
    $_.RemoteAddress -ne "127.0.0.1" -and 
    $_.RemoteAddress -notmatch "^192\.168\." -and 
    $_.RemoteAddress -notmatch "^10\." -and 
    $_.RemoteAddress -notmatch "^172\.1[6-9]\."
}).Count

$localConnections = (Get-NetTCPConnection -State Established | Where-Object { 
    $_.RemoteAddress -match "^192\.168\." -or 
    $_.RemoteAddress -match "^10\." -or 
    $_.RemoteAddress -match "^172\.1[6-9]\."
}).Count

Write-Host "Внешних соединений: $externalConnections"
Write-Host "Локальных соединений: $localConnections"
