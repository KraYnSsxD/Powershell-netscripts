$ssid = (netsh wlan show interfaces) -match '^\s*SSID' | ForEach-Object { ($_ -split ':',2)[1].Trim() }
netsh wlan show profile name="$ssid" key=clear
