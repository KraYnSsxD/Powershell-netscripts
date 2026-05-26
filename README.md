# krsz-netscripts
powershell scripts for net-work-scanning\

# запуск скриптов выполнять командой

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\SCRIPTNAME.PS1

**или**

.\SCRIPTNAME.PS1

## предназначение скриптов

1. Сканирование сети и обнаружение ресурсов **Файл 1-scan-network.ps1**
2. Активные сетевые соединения с процессами **Файл 2-connections-with-processes.ps1**
3. Внешние подключения (какие сайты/сервисы запрашивают) **Файл 3-external-connections.ps1**
4. Статистика процессов по соединениям **Файл 4-process-connections-stats.ps1**
5. Активные сеансы (кто подключен к компьютеру) **Файл 5-smb-sessions.ps1**
6. Получение данных с удаленных компьютеров в сети **Файл 6-remote-computers-info-detailed.ps1**

   
# *Полный подробный отчет* 
**Файл full-network-report.ps1**

*Полный подробный отчет от google gemini(вывод скрипта сохраняется в папку с ним же)* **Файл gemini-full-network-report.ps1**

# узнать пароль от сети
**password-scan-windows.ps1** скрипт который выводит пароль от wifi сети к которой вы подключены, работает только на windows из за того что использует *netsh*
