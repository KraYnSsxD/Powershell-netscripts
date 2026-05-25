# Статистика - какие процессы сколько соединений используют

Write-Host "=== ПРОЦЕССЫ ПО КОЛИЧЕСТВУ TCP СОЕДИНЕНИЙ ===" -ForegroundColor Green

Get-NetTCPConnection | Group-Object -Property OwningProcess | ForEach-Object {
    $process = Get-Process -Id $_.Name -ErrorAction SilentlyContinue
    if ($process) {
        [PSCustomObject]@{
            "Процесс" = $process.ProcessName
            "TCP соединений" = $_.Count
            "Использование памяти (МБ)" = [math]::Round($process.WorkingSet / 1MB, 2)
        }
    }
} | Sort-Object "TCP соединений" -Descending | Format-Table -AutoSize

Write-Host "`n=== ПРОЦЕССЫ ПО КОЛИЧЕСТВУ UDP ПОРТОВ ===" -ForegroundColor Green

Get-NetUDPEndpoint | Group-Object -Property OwningProcess | ForEach-Object {
    $process = Get-Process -Id $_.Name -ErrorAction SilentlyContinue
    if ($process) {
        [PSCustomObject]@{
            "Процесс" = $process.ProcessName
            "UDP портов" = $_.Count
        }
    }
} | Sort-Object "UDP портов" -Descending | Format-Table -AutoSize

Write-Host "`n=== ПРОСЛУШИВАЕМЫЕ ПОРТЫ ПО ПРОЦЕССАМ ===" -ForegroundColor Green

Get-NetTCPConnection -State Listen | Group-Object -Property OwningProcess | ForEach-Object {
    $process = Get-Process -Id $_.Name -ErrorAction SilentlyContinue
    if ($process) {
        [PSCustomObject]@{
            "Процесс" = $process.ProcessName
            "Прослушиваемых портов" = $_.Count
        }
    }
} | Format-Table -AutoSize
