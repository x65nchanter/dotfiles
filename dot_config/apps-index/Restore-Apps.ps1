Write-Host "--- Запуск восстановления приложений из JSON ---" -ForegroundColor Cyan

# 1. Восстановление Scoop
$scoopJson = "$HOME\.config\apps-index\scoop.json"
if (Test-Path $scoopJson)
{
    Write-Host "[1/2] Импорт Scoop пакетов..." -ForegroundColor Yellow
    # Scoop сам понимает этот JSON
    scoop import $scoopJson
}

# 2. Восстановление Winget
$wingetJson = "$HOME\.config\apps-index\winget.json"
if (Test-Path $wingetJson)
{
    Write-Host "[2/2] Импорт Winget пакетов..." -ForegroundColor Yellow
    # Используем команду import.
    # --ignore-unavailable пропустит те 80 "кривых" пакетов, которые он не найдет
    winget import -i $wingetJson --ignore-unavailable --accept-package-agreements --accept-source-agreements
}

Write-Host "--- Восстановление завершено! ---" -ForegroundColor Green
