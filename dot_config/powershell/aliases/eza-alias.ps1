# 1. Удаляем стандартный алиас ls, если он существует
if (Test-Path Alias:ls)
{
    Remove-Item Alias:ls -Force
}

function ls
{
    if (Get-Command eza -ErrorAction SilentlyContinue)
    {
        eza --icons --group-directories-first $args
    } else
    {
        Get-ChildItem $args
    }
}

function lt
{
    if (Get-Command eza -ErrorAction SilentlyContinue)
    {
        eza --tree --level=2 --icons $args
    } else
    {
        tree /f /a
    }
}
