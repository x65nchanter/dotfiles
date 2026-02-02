Write-Host "--- Экспорт списков приложений ---" -ForegroundColor Cyan

# 1. Scoop Export
Write-Host "[1/2] Экспорт Scoop..." -ForegroundColor Yellow
# Используем нативный формат scoop для импорта
scoop export > "$HOME\.config\apps-index\scoop.json"

# 2. Winget Export
Write-Host "[2/2] Экспорт Winget..." -ForegroundColor Yellow
winget export -o "$HOME\.config\apps-index\winget.json" --include-versions --accept-source-agreements

Write-Host "Готово! Файлы обновлены в ~/.config/apps-index/" -ForegroundColor Green
