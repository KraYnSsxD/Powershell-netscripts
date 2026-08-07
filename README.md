# krsz-netscripts

PowerShell scripts for network scanning and diagnostics.
## Quick Start

To run any script, use the following command (adjust the path accordingly):
```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\path\to\script.ps1"
```

### Unblocking a Script File

If the script is blocked by Windows, unblock it first:
```powershell
Unblock-File -Path ".\script-name.ps1"
```

### Temporary Execution Policy (Current Session Only)

Alternatively, set a temporary execution policy for the current PowerShell process only (no permanent changes):
```powershell

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

## Script Purpose and Overview

The repository contains a set of specialized scripts for network diagnostics and reporting:

    Network scanning and resource discovery — 1-scan-network.ps1
    Active network connections with associated processes — 2-connections-with-processes.ps1
    External connections (requested sites/services) — 3-external-connections.ps1
    Process connection statistics — 4-process-connections-stats.ps1
    Active sessions (who is connected to the computer) — 5-smb-sessions.ps1
    Detailed information from remote computers on the network — 6-remote-computers-info-detailed.ps1

### Comprehensive Reports

    full-network-report.ps1 — Generates a full detailed network report.
    gemini-full-network-report.ps1 — Generates a full detailed report (as processed by Google Gemini); output is saved to the same folder where the script is located.

### One‑Command Network Scan

You can quickly collect key network data with a single command. This will generate a report file on your desktop:
```powershell
& {
    "=== SMB SHARES ==="; Get-SmbShare;
    "`n=== ARP CACHE ==="; Get-NetNeighbor;
    "`n=== DNS CACHE ==="; Get-DnsClientCache
} > "\$home\Desktop\network_report.txt"
```
After execution, you’ll find network_report.txt on your desktop with the collected data.

## Wi‑Fi Password Retrieval

### Script
Use `password-scan-windows.ps1` to display the Wi‑Fi password for the connected network.
Note: This works only on Windows because it relies on the netsh utility.

###One‑Liner Command
You can also run this directly in PowerShell (requires Administrator privileges to show passwords):

```powershell
(netsh wlan show profiles) | Select-String ":(.+)$" | ForEach-Object { $name = $_.Matches.Value.Trim(": "); & netsh wlan show profile name="$name" key=clear }
```
## Important Notes
    Administrator Rights. Several operations (especially Wi‑Fi password extraction via netsh) require running PowerShell as Administrator. Without elevated privileges, passwords will not be displayed.
    Character Encoding. netsh outputs text in OEM encoding (e.g., CP866 on many systems), which may cause issues with non‑ASCII characters in PowerShell’s default encoding. If you see garbled text for network names, consider additional encoding conversion.
    Security Warning. Displaying and logging Wi‑Fi passwords poses a security risk. Avoid saving such logs in shared or public locations, and never commit them to version control.
    Execution Policy. Windows blocks unsigned scripts by default. Use the provided methods to safely allow script execution for testing and deployment.
