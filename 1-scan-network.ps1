# Сканирование локальной сети и обнаружение ресурсов

Write-Host "=== ИНФОРМАЦИЯ О СЕТИ ===" -ForegroundColor Green
$ipconfig = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notmatch "Loopback"}
$ipconfig | Format-Table InterfaceAlias, IPAddress, PrefixLength

Write-Host "`n=== КОМПЬЮТЕРЫ И УСТРОЙСТВА В ЛОКАЛЬНОЙ СЕТИ ===" -ForegroundColor Green
net view

Write-Host "`n=== АКТИВНЫЕ ХОСТЫ (PING СКАНИРОВАНИЕ) ===" -ForegroundColor Green
$subnet = "192.168.1"  # Измените на вашу подсеть
1..254 | ForEach-Object {
    $ip = "$subnet.$_"
    if (Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue) {
        Write-Host "Найден: $ip" -ForegroundColor Yellow
    }
}

Write-Host "`n=== ОБЩИЕ ПАПКИ (SHARES) ===" -ForegroundColor Green
Get-SmbShare | Format-Table Name, Path, Description

Write-Host "`n=== ВСЕ ПРИНТЕРЫ В СИСТЕМЕ ===" -ForegroundColor Green
Get-Printer | Format-Table Name, PortName, PrinterStatus, Type

Write-Host "`n=== СЕТЕВЫЕ ПРИНТЕРЫ ===" -ForegroundColor Green
Get-Printer -PrinterType Connection | Format-Table Name, PortName, Description
