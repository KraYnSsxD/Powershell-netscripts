# Полный подробный отчет о всех сетевых ресурсах и соединениях

# Проверка прав администратора (некоторые командлеты требуют повышенных привилегий)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Скрипт запущен без прав администратора. Часть данных (например, SMB сессии) может быть недоступна."
}

$reportPath = "C:\FullNetworkReport_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"

# Использование массива ArrayList для высокой скорости работы
$report = New-Object System.Collections.ArrayList

[void]$report.Add("========== ПОЛНЫЙ ОТЧЕТ О СЕТЕВЫХ РЕСУРСАХ И СОЕДИНЕНИЯХ ==========")
[void]$report.Add("Дата: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$report.Add("Компьютер: $env:COMPUTERNAME")
[void]$report.Add("Пользователь: $env:USERNAME`n")

# 1. ИНФОРМАЦИЯ О СЕТИ
[void]$report.Add("`n=== 1. ИНФОРМАЦИЯ О СЕТЕВЫХ АДАПТЕРАХ ===")
Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notmatch "Loopback"} | ForEach-Object {
    [void]$report.Add("Адаптер: $($_.InterfaceAlias) | IP: $($_.IPAddress) | Маска: $($_.PrefixLength)")
}

# 2. ОБЩИЕ ПАПКИ
[void]$report.Add("`n=== 2. ОБЩИЕ ПАПКИ (SHARES) ===")
Get-SmbShare | ForEach-Object {
    [void]$report.Add("Название: $($_.Name) | Путь: $($_.Path) | Описание: $($_.Description)")
}

# 3. ПРИНТЕРЫ
[void]$report.Add("`n=== 3. ПРИНТЕРЫ ===")
Get-Printer | ForEach-Object {
    [void]$report.Add("Название: $($_.Name) | Порт: $($_.PortName) | Статус: $($_.PrinterStatus) | Тип: $($_.Type)")
}

# 4. TCP СОЕДИНЕНИЯ
[void]$report.Add("`n=== 4. УСТАНОВЛЕННЫЕ TCP СОЕДИНЕНИЯ ===")
Get-NetTCPConnection -State Established | ForEach-Object {
    $process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    [void]$report.Add("$($process.ProcessName) | $($_.LocalAddress):$($_.LocalPort) -> $($_.RemoteAddress):$($_.RemotePort)")
}

# 5. UDP СОЕДИНЕНИЯ
[void]$report.Add("`n=== 5. UDP СОЕДИНЕНИЯ ===")
Get-NetUDPEndpoint | ForEach-Object {
    $process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    [void]$report.Add("$($process.ProcessName) | $($_.LocalAddress):$($_.LocalPort) -> $($_.RemoteAddress):$($_.RemotePort)")
}

# 6. ПРОСЛУШИВАЕМЫЕ ПОРТЫ
[void]$report.Add("`n=== 6. ПРОСЛУШИВАЕМЫЕ ПОРТЫ (LISTENING) ===")
Get-NetTCPConnection -State Listen | ForEach-Object {
    $process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    [void]$report.Add("$($process.ProcessName) | Слушает $($_.LocalAddress):$($_.LocalPort)")
}

# 7. ВНЕШНИЕ ПОДКЛЮЧЕНИЯ
[void]$report.Add("`n=== 7. ВНЕШНИЕ ПОДКЛЮЧЕНИЯ (ИНТЕРНЕТ) ===")
Get-NetTCPConnection -State Established | Where-Object { 
    $_.RemoteAddress -ne "127.0.0.1" -and 
    $_.RemoteAddress -ne "::1" -and
    $_.RemoteAddress -notmatch "^192\.168\." -and 
    $_.RemoteAddress -notmatch "^10\." -and 
    $_.RemoteAddress -notmatch "^172\.(1[6-9]|2[0-9]|3[0-1])\."
} | ForEach-Object {
    $process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    [void]$report.Add("$($process.ProcessName) -> $($_.RemoteAddress):$($_.RemotePort)")
}

# 8. АКТИВНЫЕ SMB СЕАНСЫ
[void]$report.Add("`n=== 8. АКТИВНЫЕ СЕАНСЫ (ПОДКЛЮЧЕНИЯ ПОЛЬЗОВАТЕЛЕЙ) ===")
try {
    Get-SmbSession -ErrorAction Stop | ForEach-Object {
        [void]$report.Add("Пользователь: $($_.UserName) | IP: $($_.ClientIPAddress) | Компьютер: $($_.ClientComputerName)")
    }
} catch {
    [void]$report.Add("Не удалось получить данные SMB сессий (требуются права администратора).")
}

# 9. СТАТИСТИКА
[void]$report.Add("`n=== 9. СТАТИСТИКА ===")
$tcpCount = (Get-NetTCPConnection -State Established | Measure-Object).Count
$udpCount = (Get-NetUDPEndpoint | Measure-Object).Count
$listenCount = (Get-NetTCPConnection -State Listen | Measure-Object).Count
$externalCount = (Get-NetTCPConnection -State Established | Where-Object { 
    $_.RemoteAddress -ne "127.0.0.1" -and 
    $_.RemoteAddress -ne "::1" -and
    $_.RemoteAddress -notmatch "^192\.168\." -and 
    $_.RemoteAddress -notmatch "^10\." -and 
    $_.RemoteAddress -notmatch "^172\.(1[6-9]|2[0-9]|3[0-1])\."
} | Measure-Object).Count

[void]$report.Add("Активных TCP соединений: $tcpCount")
[void]$report.Add("Активных UDP портов: $udpCount")
[void]$report.Add("Прослушиваемых портов (TCP): $listenCount")
[void]$report.Add("Внешних подключений: $externalCount")
[void]$report.Add("Общих папок: $($(Get-SmbShare | Measure-Object).Count)")
[void]$report.Add("Принтеров: $($(Get-Printer | Measure-Object).Count)")

# Сохранение отчета
try {
    $report | Out-File $reportPath -Encoding UTF8 -ErrorAction Stop
    Write-Host "`n✓ Отчет успешно сохранен: $reportPath" -ForegroundColor Green
} catch {
    Write-Host "`n❌ Ошибка сохранения в корень диска C:. Пробуем сохранить в папку скрипта..." -ForegroundColor Red
    $reportPath = ".\FullNetworkReport_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
    $report | Out-File $reportPath -Encoding UTF8
    Write-Host "✓ Отчет сохранен в текущую папку: $(Resolve-Path $reportPath)" -ForegroundColor Green
}
