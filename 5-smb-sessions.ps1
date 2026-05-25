# Активные сеансы в сети (кто подключен к общим папкам)

Write-Host "=== АКТИВНЫЕ СЕАНСЫ SMB (подключения к общим папкам) ===" -ForegroundColor Green

Get-SmbSession | ForEach-Object {
    [PSCustomObject]@{
        "Пользователь" = $_.UserName
        "Компьютер" = $_.ClientComputerName
        "IP адрес" = $_.ClientIPAddress
        "Время подключения" = $_.IdleTime
    }
} | Format-Table -AutoSize

Write-Host "`n=== ОТКРЫТЫЕ ОБЩИЕ РЕСУРСЫ ===" -ForegroundColor Green

Get-SmbOpenFile | ForEach-Object {
    [PSCustomObject]@{
        "Файл/Папка" = $_.Path
        "Пользователь" = $_.ClientUserName
        "Компьютер" = $_.ClientComputerName
        "Тип доступа" = $_.AccessMode
    }
} | Format-Table -AutoSize
