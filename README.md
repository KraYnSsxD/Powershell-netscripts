# krsz-netscripts
powershell scripts for net-work-scanning\

# запуск скриптов выполнять командой

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\SCRIPTNAME.PS1

**или**

.\SCRIPTNAME.PS1

## предназночение скриптов

1. Сканирование сети и обнаружение ресурсов **Файл 1-scan-network.ps1**
2. Активные сетевые соединения с процессами **Файл 2-connections-with-processes.ps1**
3. Внешние подключения (какие сайты/сервисы запрашивают) **Файл 3-external-connections.ps1**
4. Статистика процессов по соединениям **Файл 4-process-connections-stats.ps1**
5. Активные сеансы (кто подключен к компьютеру) **Файл 5-smb-sessions.ps1**
# 6. *Полный подробный отчет (всё сразу)* 
**Файл 6-full-network-report.ps1**
