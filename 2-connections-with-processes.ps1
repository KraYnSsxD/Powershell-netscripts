# Активные соединения с названиями процессов

Write-Host "=== TCP СОЕДИНЕНИЯ (УСТАНОВЛЕННЫЕ) С ПРОЦЕССАМИ ===" -ForegroundColor Green

Get-NetTCPConnection -State Established | ForEach-Object {
    $process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        "Процесс" = $process.ProcessName
        "PID" = $_.OwningProcess
        "Локальный IP" = $_.LocalAddress
        "Локальный порт" = $_.LocalPort
        "Удаленный IP" = $_.RemoteAddress
        "Удаленный порт" = $_.RemotePort
        "Состояние" = $_.State
    }
} | Format-Table -AutoSize

Write-Host "`n=== UDP СОЕДИНЕНИЯ С ПРОЦЕССАМИ ===" -ForegroundColor Green

Get-NetUDPEndpoint | ForEach-Object {
    $process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        "Процесс" = $process.ProcessName
        "PID" = $_.OwningProcess
        "Локальный IP" = $_.LocalAddress
        "Локальный порт" = $_.LocalPort
        "Удаленный IP" = $_.RemoteAddress
        "Удаленный порт" = $_.RemotePort
    }
} | Format-Table -AutoSize

Write-Host "`n=== ПРОСЛУШИВАЕМЫЕ ПОРТЫ (TCP) ===" -ForegroundColor Green

Get-NetTCPConnection -State Listen | ForEach-Object {
    $process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        "Процесс" = $process.ProcessName
        "PID" = $_.OwningProcess
        "Локальный IP" = $_.LocalAddress
        "Локальный порт" = $_.LocalPort
        "Состояние" = $_.State
    }
} | Format-Table -AutoSize
