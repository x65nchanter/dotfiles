# Короткий алиас для Lazygit
function lg
{
    if (Get-Command lazygit -ErrorAction SilentlyContinue)
    {
        lazygit $args
    } else
    {
        Write-Host "Lazygit не установлен. Выполни: scoop install lazygit" -ForegroundColor Yellow
    }
}
