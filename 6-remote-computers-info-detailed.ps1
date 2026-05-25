# ============================================================================
# Скрипт: Расширенный сбор информации с удаленных компьютеров в сети
# Описание: Получает полный набор данных о системе, сети, программах и статусе
# ============================================================================

Write-Host "=== РАСШИРЕННОЕ СКАНИРОВАНИЕ УДАЛЕННЫХ КОМПЬЮТЕРОВ ===" -ForegroundColor Green

# 1. Получить список компьютеров в сети
Write-Host "`nПолучаю список компьютеров в сети..." -ForegroundColor Yellow
$computers = @()

try {
    net view | Select-String "^\\\\" | ForEach-Object {
        $computerName = $_ -replace '\\\\', '' -replace '\s+.*'
        if ($computerName -and $computerName -ne "") {
            $computers += $computerName
        }
    }
    Write-Host "Найдено компьютеров: $($computers.Count)" -ForegroundColor Cyan
} catch {
    Write-Host "Ошибка при сканировании сети: $_" -ForegroundColor Red
}

# ============================================================================
# ФУНКЦИИ ДЛЯ СБОРА РАСШИРЕННОЙ ИНФОРМАЦИИ
# ============================================================================

function Get-ExtendedRemoteComputerInfo {
    param (
        [string]$ComputerName,
        [PSCredential]$Credential = $null
    )
    
    $computerInfo = @{
        # Основная информация
        ComputerName = $ComputerName
        IsOnline = $false
        Domain = "N/A"
        Workgroup = "N/A"
        
        # Аппаратное обеспечение
        OSVersion = "N/A"
        OSBuildNumber = "N/A"
        RAM = "N/A"
        CPUInfo = "N/A"
        CPUCores = "N/A"
        CPUThreads = "N/A"
        DiskSpace = "N/A"
        GPU = "N/A"
        Motherboard = "N/A"
        BIOSVersion = "N/A"
        SerialNumber = "N/A"
        
        # Сеть
        IPAddress = "N/A"
        MACAddress = "N/A"
        DefaultGateway = "N/A"
        DNSServers = "N/A"
        NetworkAdapters = "N/A"
        
        # Пользователи и сессии
        LoggedInUser = "N/A"
        LocalUsers = "N/A"
        LastBootTime = "N/A"
        Uptime = "N/A"
        
        # Установленное ПО
        InstalledApps = "N/A"
        InstalledUpdates = "N/A"
        WindowsUpdatesStatus = "N/A"
        
        # Процессы и сервисы
        RunningProcesses = "N/A"
        CriticalServices = "N/A"
        
        # Безопасность
        AntiVirusStatus = "N/A"
        FirewallStatus = "N/A"
        UAC = "N/A"
        
        # Общая информация
        TimeZone = "N/A"
        Language = "N/A"
        LastLoginTime = "N/A"
        PageFileSize = "N/A"
        TotalHardDrives = "N/A"
    }
    
    Write-Host "`nПроверяю $ComputerName..." -ForegroundColor Yellow
    
    if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {
        $computerInfo.IsOnline = $true
        Write-Host "$ComputerName - ДОСТУПЕН" -ForegroundColor Green
        
        try {
            $sessionParams = @{
                ComputerName = $ComputerName
                ErrorAction = "Stop"
            }
            
            if ($Credential) {
                $sessionParams.Credential = $Credential
            }
            
            # ==================== СИСТЕМА И ОС ====================
            $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem @sessionParams
            $computerInfo.OSVersion = $osInfo.Caption
            $computerInfo.OSBuildNumber = $osInfo.BuildNumber
            $computerInfo.TimeZone = $osInfo.CurrentTimeZone
            $computerInfo.TotalHardDrives = (Get-CimInstance -ClassName Win32_DiskDrive @sessionParams | Measure-Object).Count
            
            # ==================== КОМПЬЮТЕР ====================
            $systemInfo = Get-CimInstance -ClassName Win32_ComputerSystem @sessionParams
            $computerInfo.Domain = $systemInfo.Domain
            $computerInfo.Workgroup = if ($systemInfo.PartOfDomain) { $systemInfo.Domain } else { "Рабочая группа" }
            $computerInfo.LoggedInUser = "$($systemInfo.Domain)\$($systemInfo.UserName)"
            $computerInfo.SerialNumber = (Get-CimInstance -ClassName Win32_BIOS @sessionParams).SerialNumber
            $computerInfo.Motherboard = (Get-CimInstance -ClassName Win32_BaseBoard @sessionParams).Product
            $computerInfo.BIOSVersion = (Get-CimInstance -ClassName Win32_BIOS @sessionParams).SMBIOSBIOSVersion
            
            # ==================== ПРОЦЕССОР ====================
            $cpuInfo = Get-CimInstance -ClassName Win32_Processor @sessionParams | Select-Object -First 1
            $computerInfo.CPUInfo = $cpuInfo.Name
            $computerInfo.CPUCores = $cpuInfo.NumberOfCores
            $computerInfo.CPUThreads = $cpuInfo.ThreadCount
            
            # ==================== ПАМЯТЬ ====================
            $ramInfo = Get-CimInstance -ClassName Win32_PhysicalMemory @sessionParams
            $totalRAM = ($ramInfo | Measure-Object -Property Capacity -Sum).Sum / 1GB
            $computerInfo.RAM = "$([Math]::Round($totalRAM, 2)) GB"
            $computerInfo.PageFileSize = "$(([Math]::Round((Get-CimInstance -ClassName Win32_PageFile @sessionParams).FileSize / 1GB, 2))) GB"
            
            # ==================== ВИДЕОКАРТА ====================
            $gpuInfo = Get-CimInstance -ClassName Win32_VideoController @sessionParams
            $computerInfo.GPU = if ($gpuInfo) { ($gpuInfo | Select-Object -ExpandProperty Name) -join ", " } else { "Встроенная графика" }
            
            # ==================== ДИСКИ ====================
            $diskInfo = Get-CimInstance -ClassName Win32_LogicalDisk @sessionParams | 
                Where-Object { $_.DriveType -eq 3 } | 
                ForEach-Object {
                    $freeSpace = [Math]::Round($_.FreeSpace / 1GB, 2)
                    $totalSpace = [Math]::Round($_.Size / 1GB, 2)
                    $percentFree = [Math]::Round(($_.FreeSpace / $_.Size) * 100, 2)
                    "$($_.Name) - Всего: $totalSpace GB, Свободно: $freeSpace GB ($percentFree%)"
                }
            $computerInfo.DiskSpace = $diskInfo -join "; "
            
            # ==================== СЕТЬ ====================
            $netAdapter = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration @sessionParams | 
                Where-Object { $_.IPAddress -and $_.IPAddress[0] -notmatch "^169\." } | 
                Select-Object -First 1
            
            if ($netAdapter) {
                $computerInfo.IPAddress = $netAdapter.IPAddress[0]
                $computerInfo.MACAddress = $netAdapter.MACAddress
                $computerInfo.DefaultGateway = $netAdapter.DefaultIPGateway[0]
                $computerInfo.DNSServers = ($netAdapter.DNSServerSearchOrder | Where-Object { $_ }) -join ", "
            }
            
            $allNetAdapters = Get-CimInstance -ClassName Win32_NetworkAdapter @sessionParams | 
                Where-Object { $_.NetConnectionStatus -eq 2 }
            $computerInfo.NetworkAdapters = ($allNetAdapters | Select-Object -ExpandProperty Name) -join "; "
            
            # ==================== ВРЕМЯ И ЗАГРУЗКА ====================
            $uptime = Get-CimInstance -ClassName Win32_OperatingSystem @sessionParams | 
                Select-Object -ExpandProperty LastBootUpTime
            $computerInfo.LastBootTime = $uptime.ToString("dd.MM.yyyy HH:mm:ss")
            
            $uptimeSpan = New-TimeSpan -Start $uptime -End (Get-Date)
            $computerInfo.Uptime = "$([Math]::Round($uptimeSpan.TotalDays, 1)) дней ($($uptimeSpan.Hours)ч $($uptimeSpan.Minutes)м)"
            
            # ==================== ПОЛЬЗОВАТЕЛИ ====================
            $localUsers = Get-CimInstance -ClassName Win32_UserAccount -Filter "LocalAccount=TRUE" @sessionParams
            $computerInfo.LocalUsers = if ($localUsers) { ($localUsers.Name | Select-Object -First 5) -join ", " } else { "Не найдено" }
            
            # ==================== УСТАНОВЛЕННОЕ ПО ====================
            $installedApps = Get-CimInstance -ClassName Win32_Product @sessionParams | 
                Select-Object -ExpandProperty Name -First 10
            $computerInfo.InstalledApps = if ($installedApps) { ($installedApps -join ", ") } else { "Не найдено" }
            
            # ==================== ОБНОВЛЕНИЯ WINDOWS ====================
            try {
                $updates = Get-CimInstance -ClassName Win32_QuickFixEngineering @sessionParams | 
                    Measure-Object | Select-Object -ExpandProperty Count
                $computerInfo.InstalledUpdates = $updates
                $computerInfo.WindowsUpdatesStatus = "Установлено $updates обновлений"
            } catch {
                $computerInfo.WindowsUpdatesStatus = "Не удалось получить"
            }
            
            # ==================== ПРОЦЕССЫ ====================
            $processes = Get-CimInstance -ClassName Win32_Process @sessionParams | Measure-Object | Select-Object -ExpandProperty Count
            $computerInfo.RunningProcesses = "$processes процессов"
            
            # ==================== СЕРВИСЫ ====================
            $criticalServices = Get-CimInstance -ClassName Win32_Service -Filter "State='Running'" @sessionParams | 
                Where-Object { $_.Name -in @('WinDefend', 'MpsSvc', 'wuauserv', 'CryptSvc') } | 
                Select-Object -ExpandProperty DisplayName
            $computerInfo.CriticalServices = if ($criticalServices) { ($criticalServices -join ", ") } else { "Не все найдены" }
            
            # ==================== БЕЗОПАСНОСТЬ ====================
            try {
                $antivirus = Get-CimInstance -ClassName AntiVirusProduct @sessionParams -ErrorAction SilentlyContinue
                $computerInfo.AntiVirusStatus = if ($antivirus) { $antivirus.DisplayName } else { "Не установлен" }
            } catch {
                $computerInfo.AntiVirusStatus = "Неизвестно"
            }
            
            try {
                $firewall = Get-CimInstance -ClassName FirewallProduct @sessionParams -ErrorAction SilentlyContinue
                $computerInfo.FirewallStatus = if ($firewall) { $firewall.DisplayName } else { "Отключен или встроенный" }
            } catch {
                $computerInfo.FirewallStatus = "Неизвестно"
            }
            
            # ==================== UAC ====================
            try {
                $uacPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System"
                $uacValue = Invoke-CimMethod -ClassName StdRegProv -MethodName GetDWORDValue `
                    -Arguments @{ hDefKey=[uint32]2147483648; sSubKeyName=$uacPath; sValueName="EnableLUA" } `
                    @sessionParams
                $computerInfo.UAC = if ($uacValue.uValue -eq 1) { "Включен" } else { "Отключен" }
            } catch {
                $computerInfo.UAC = "Неизвестно"
            }
            
            # ==================== ЯЗЫК И РЕГИОНАЛЬНЫЕ ПАРАМЕТРЫ ====================
            try {
                $cultureInfo = Get-CimInstance -ClassName Win32_OperatingSystem @sessionParams | Select-Object -ExpandProperty MUILanguages
                $computerInfo.Language = if ($cultureInfo) { $cultureInfo -join ", " } else { "По умолчанию" }
            } catch {
                $computerInfo.Language = "Неизвестно"
            }
            
        } catch {
            Write-Host "Ошибка при получении информации с $ComputerName : $_" -ForegroundColor Red
        }
    } else {
        Write-Host "$ComputerName - НЕДОСТУПЕН" -ForegroundColor Red
    }
    
    return $computerInfo
}

# ============================================================================
# ОБРАБОТКА И ВЫВОД РЕЗУЛЬТАТОВ
# ============================================================================

Write-Host "`n=== СБОР РАСШИРЕННОЙ ИНФОРМАЦИИ ===" -ForegroundColor Green

$results = @()

foreach ($computer in $computers) {
    $info = Get-ExtendedRemoteComputerInfo -ComputerName $computer
    $results += $info
}

# Вывод полной информации
Write-Host "`n=== ДЕТАЛЬНАЯ ИНФОРМАЦИЯ ===" -ForegroundColor Green

$results | ForEach-Object {
    Write-Host "`n╔════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║ $($_.ComputerName.PadRight(40)) ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    if ($_.IsOnline) {
        Write-Host "▶ СТАТУС И ДОСТУПНОСТЬ"
        Write-Host "  Статус: ОНЛАЙН" -ForegroundColor Green
        Write-Host "  Домен/Рабочая группа: $($_.Workgroup)"
        Write-Host "  Последняя загрузка: $($_.LastBootTime)"
        Write-Host "  Время работы: $($_.Uptime)"
        
        Write-Host "`n▶ АППАРАТНОЕ ОБЕСПЕЧЕНИЕ"
        Write-Host "  ОС: $($_.OSVersion) (сборка $($_.OSBuildNumber))"
        Write-Host "  Процессор: $($_.CPUInfo)"
        Write-Host "    └─ Ядер: $($_.CPUCores), Потоков: $($_.CPUThreads)"
        Write-Host "  ОЗУ: $($_.RAM)"
        Write-Host "  Видеокарта: $($_.GPU)"
        Write-Host "  Материнская плата: $($_.Motherboard)"
        Write-Host "  BIOS: $($_.BIOSVersion)"
        Write-Host "  Серийный номер: $($_.SerialNumber)"
        Write-Host "  Жестких дисков: $($_.TotalHardDrives)"
        
        Write-Host "`n▶ ХРАНИЛИЩЕ"
        Write-Host "  Диски: $($_.DiskSpace)"
        Write-Host "  Файл подкачки: $($_.PageFileSize)"
        
        Write-Host "`n▶ СЕТЬ"
        Write-Host "  IP адрес: $($_.IPAddress)"
        Write-Host "  MAC адрес: $($_.MACAddress)"
        Write-Host "  Шлюз по умолчанию: $($_.DefaultGateway)"
        Write-Host "  DNS серверы: $($_.DNSServers)"
        Write-Host "  Сетевые адаптеры: $($_.NetworkAdapters)"
        
        Write-Host "`n▶ ПОЛЬЗОВАТЕЛИ И СЕССИИ"
        Write-Host "  Текущий пользователь: $($_.LoggedInUser)"
        Write-Host "  Локальные пользователи: $($_.LocalUsers)"
        
        Write-Host "`n▶ ПРОГРАММНОЕ ОБЕСПЕЧЕНИЕ"
        Write-
