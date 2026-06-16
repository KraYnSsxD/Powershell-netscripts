$profiles = (netsh wlan show profiles) | Select-String "\:(.+)$" | ForEach-Object { $_.Matches.Value.Trim(": ") }

foreach ($profile in $profiles) {
    Write-Host "--- Профиль: $profile ---" -ForegroundColor Cyan
    netsh wlan show profile name="$profile" key=clear | Select-String "Содержимое ключа"
    Write-Host ""
}
