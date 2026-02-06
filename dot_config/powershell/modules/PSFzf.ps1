if (Get-Command fzf -ErrorAction SilentlyContinue)
{
    Import-Module PSFzf
    Set-PsFzfOption -CursorColor '#ff8700' -Multi
}
