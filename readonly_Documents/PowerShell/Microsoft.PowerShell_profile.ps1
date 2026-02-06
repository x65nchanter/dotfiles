if ($env:TERM_PROGRAM -ne "WezTerm" -and -not $env:WEZTERM_PANE)
{
    return
}

if ($env:IS_AI_AGENT)
{
    return
}

Invoke-Expression (& { (atuin init powershell | Out-String) })
. "$HOME\.config\powershell\completions\local-llm-completions.ps1"
. "$HOME\.config\powershell\completions\opencode.ps1"
. "$HOME\.config\powershell\completions\intelliSense.ps1"
. "$HOME\.config\powershell\aliases\eza-alias.ps1"
. "$HOME\.config\powershell\aliases\gsudo-alias.ps1"
. "$HOME\.config\powershell\aliases\glog.ps1"
. "$HOME\.config\powershell\aliases\lazygit.ps1"
. "$HOME\.config\powershell\aliases\ascii.ps1"
. "$HOME\.config\powershell\aliases\z-location.ps1"
. "$HOME\.config\powershell\enviroment.ps1"
. "$HOME\.config\powershell\modules\oh-my-posh.ps1"
. "$HOME\.config\powershell\modules\gsudoModule.ps1"
. "$HOME\.config\powershell\modules\PSFzf.ps1"
. "$HOME\.config\powershell\modules\terminal-icons.ps1"
. "$HOME\.config\powershell\modules\ZLocation.ps1"
. "$HOME\.env.ps1"

$env:IS_PROFILE_LOADED = $true
