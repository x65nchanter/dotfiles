
if ($Host.UI.RawUI.WindowSize.Width -gt 0 -and $null -eq $PSIdler)
{
    # Эти настройки выполнятся только в WezTerm/Консоли
    try
    {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        Set-PSReadLineOption -PredictionViewStyle ListView
        # Добавьте сюда другие настройки интерфейса, если они есть
    } catch
    {
        # Write-Warning "PSReadLine не смог запустить предсказания в этой сессии."
    }
}

Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
