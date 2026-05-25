# Полный подробный отчет о всех сетевых ресурсах и соединениях

$reportPath = "C:\FullNetworkReport_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
$report = @()

$report += "========== ПОЛНЫЙ ОТЧЕТ О СЕТЕВЫХ РЕСУРСАХ И СОЕДИНЕНИЯХ =========="
$report += "Дата: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$report += "Компьютер: $env:COMPUTERNAME"
$report += "Пользователь: $env:USERNAME`n"

# 1. ИНФОРМАЦИЯ О СЕТИ
$report += "`n=== 1. ИНФОРМАЦИЯ О СЕТЕВЫХ АДАПТЕРАХ ==="
Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notmatch "Loopback"} | ForEach-Object {
    $report += "Адаптер: $($_.InterfaceAlias) | IP: $($_.IPAddress) | Маска: $($_.PrefixLength)"
}

# 2. ОБЩИЕ ПАПКИ
$report += "`n=== 2. ОБЩИЕ ПАПКИ (SHARES) ==="
Get-SmbShare | ForEach-Object {
    $report += "Название: $($_.Name) | Путь: $($_.Path) | Описание: $($_.Description)"
}

# 3. ПРИНТЕРЫ
$report += "`n=== 3. ПРИНТЕРЫ ==="
Get-Printer | ForEach-Object {
    $report += "Названи: $($_.Name) | Порт: $($_.PortName) | Статус: $($_.PrinterStatus) | Тип: $($_.Type)"
}

# 4. TCP СОЕДИНЕНИЯ
$report += "`n=== 4. УСТАНОВЛЕННЫЕ TCP СОЕДИНЕНИЯ ==="
Get-NetTCPConnection -State Established | ForEach-Object {
    $process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    $report += "$($process.ProcessName) | $($_.LocalAddress):$($_.LocalPort) -> $($_.RemoteAddress):$($_.RemotePort)"
}

# 5. UDP СОЕДИНЕНИЯ
$report += "`n=== 5. UDP СОЕДИНЕНИЯ ==="
Get-NetUDPEndpoint | ForEach-Object {
    $process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    $report += "$($process.ProcessName) | $($_.LocalAddress):$($_.LocalPort) -> $($_.RemoteAddress):$($_.RemotePort)"
}

# 6. ПРОСЛУШИВАЕМЫЕ ПОРТЫ
$report += "`n=== 6. ПРОСЛУШИВАЕМЫЕ ПОРТЫ (LISTENING) ==="
Get-NetTCPConnection -State Listen | ForEach-Object {
    $process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    $report += "$($process.ProcessName) | Слушает $($_.LocalAddress):$($_.LocalPort)"
}

# 7. ВНЕШНИЕ ПОДКЛЮЧЕНИЯ
$report += "`n=== 7. ВНЕШНИЕ ПОДКЛЮЧЕНИЯ (ИНТЕРНЕТ) ==="
Get-NetTCPConnection -State Established | Where-Object { 
    $_.RemoteAddress -ne "127.0.0.1" -and 
    $_.RemoteAddress -notmatch "^192\.168\." -and 
    $_.RemoteAddress -notmatch "^10\." -and 
    $_.RemoteAddress -notmatch "^172\.1[6-9]\."
} | ForEach-Object {
    $process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    $report += "$($process.ProcessName) -> $($_.RemoteAddress):$($_.RemotePort)"
}

# 8. АКТИВНЫЕ SMB СЕАНСЫ
$report += "`n=== 8. АКТИВНЫЕ СЕАНСЫ (ПОДКЛЮЧЕНИЯ ПОЛЬЗОВАТЕЛЕЙ) ==="
Get-SmbSession | ForEach-Object {
    $report += "Пользователь: $($_.UserName) | IP: $($_.ClientIPAddress) | Компьютер: $($_.ClientComputerName)"
}

# 9. СТАТИСТИКА
$report += "`n=== 9. СТАТИСТИКА ==="
$tcpCount = (Get-NetTCPConnection -State Established | Measure-Object).Count
$udpCount = (Get-NetUDPEndpoint | Measure-Object).Count
$listenCount = (Get-NetTCPConnection -State Listen | Measure-Object).Count
$externalCount = (Get-NetTCPConnection -State Established | Where-Object { 
    $_.RemoteAddress -ne "127.0.0.1" -and 
    $_.RemoteAddress -notmatch "^192\.168\." -and 
    $_.RemoteAddress -notmatch "^10\." -and 
    $_.RemoteAddress -notmatch "^172\.1[6-9]\."
} | Measure-Object).Count

$report += "Активных TCP соединений: $tcpCount"
$report += "Активных UDP портов: $udpCount"
$report += "Прослушиваемых портов (TCP): $listenCount"
$report += "Внешних подключений: $externalCount"
$report += "Общих папок: $($(Get-SmbShare | Measure-Object).Count)"
$report += "Принтеров: $($(Get-Printer | Measure-Object).Count)"

# Сохранение отчета
$report | Out-File $reportPath -Encoding UTF8
Write-Host "✓ Отчет сохранен: $reportPath" -ForegroundColor Green
Write-Host "`nС
