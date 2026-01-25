<#
.SYNOPSIS
    Terminal Sentinel - Интеллектуальный ассистент для PowerShell и WezTerm.

.DESCRIPTION
    Скрипт интегрирует локальную LLM (через LM Studio API) в командную строку PowerShell.
    Анализирует текущую папку, переменные окружения и ошибки для генерации автодополнения.
    Оптимизировано для работы с моделью Qwen3-Coder-30B в среде WezTerm.

.VERSION
    0.27.0 (Stable)

.AUTHOR
    Terminal Sentinel Project & Gemini (Collaboration)

.DATE
    21.01.2026

.CONFIG_PATH
    Prompt Template: ~/Prompts/terminal-sentinel-completion.txt
    Script: ~/.config/powershell-ai/ai-completion.ps1

.NOTES
    ИНСТРУКЦИЯ ПО УСТАНОВКЕ:
    1. Убедитесь, что скрипт сохранен по пути:
        ~/.config/powershell-ai/ai-completion.ps1
    2. Откройте ваш профиль PowerShell командой:
        notepad $PROFILE
    3. Добавьте в конец файла следующую строку:
        . "$HOME\.config\powershell-ai\ai-completion.ps1"
    4. Перезапустите терминал или выполните:
        . $PROFILE
    5. Использование: Начните писать команду и нажмите Alt+A (или Alt+Ф).

.LICENSE
    MIT License
#>

function Get-AICompletion
{
    try
    {
        $txt = ""; $cursor = 0
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$txt, [ref]$cursor)
        if ([string]::IsNullOrWhiteSpace($txt))
        { return
        }

        $esc = [char]27; $b = [char]96

        # 1. Загрузка промпта
        $promptPath = "$HOME\Prompts\terminal-sentinel-completion.txt"
        if (!(Test-Path $promptPath))
        { return
        }
        $systemTemplate = Get-Content -Path $promptPath -Raw

        # 2. Сбор данных
        $fileList = (Get-ChildItem -Force | Select-Object -ExpandProperty Name) -join "`n"
        $envList = (Get-ChildItem Env: | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join "`n"
        $lastErr = if ($Error.Count -gt 0)
        { $Error[0].Exception.Message
        } else
        { "None"
        }

        $safeErr = "$lastErr" -replace "['""$b]", ""
        $safePath = $PWD.Path -replace "['""$b]", ""
        $safeTxt = $txt -replace "['""$b]", ""

        $finalSystemPrompt = $systemTemplate `
            -replace '\{\{PWD\}\}', $safePath `
            -replace '\{\{FILES\}\}', $fileList `
            -replace '\{\{ERROR\}\}', $safeErr `
            -replace '\{\{ENV\}\}', $envList

        $payload = @{
            messages = @(
                @{role='system'; content=$finalSystemPrompt},
                @{role='user'; content="Request: $txt"}
            )
            model = "qwen3-coder-30b-a3b-instruct"
            temperature = 0.1
        } | ConvertTo-Json -Compress

        # 3. Запрос
        $res = Invoke-RestMethod -Uri "http://127.0.0.1:1234/v1/chat/completions" -Method Post `
            -Body ([System.Text.Encoding]::UTF8.GetBytes($payload)) `
            -ContentType "application/json; charset=utf-8" -TimeoutSec 60

        $raw = $res.choices.message.content.Trim()
        $cleanRaw = $raw -replace "[$b]", ""

        # 5. Обработка вариантов (УБРАНА ЖЕСТКАЯ ФИЛЬТРАЦИЯ ПРЕФИКСА)
        $options = $cleanRaw.Split(';') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" } | Select-Object -Unique -First 5

        if ($options.Count -gt 0)
        {
            # --- ВЫВОД DASHBOARD ---
            $ms = $startTime.ElapsedMilliseconds
            Write-Host "`n$esc[1;30m┌──$esc[1;36m SENTINEL AI $esc[1;30m" + ("─" * 25) + "$esc[0m"
            Write-Host "$esc[1;30m│$esc[0m Запрос: $esc[1;33m$txt$esc[0m"
            Write-Host "$esc[1;30m│$esc[0m Скорость: $esc[1;32m$ms мс$esc[0m"
            Write-Host "$esc[1;30m└──$esc[1;36m ВАРИАНТЫ КОМАНД $esc[1;30m" + ("─" * 23) + "$esc[0m"

            for ($i = 0; $i -lt $options.Count; $i++)
            {
                Write-Host "$esc[1;32m $($i+1) $esc[1;30m│$esc[0m $($options[$i])"
            }
            Write-Host "$esc[1;30m[1-5] Выбор | [Any] Отмена$esc[0m"

            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

            $linesToClear = $options.Count + 5
            for ($l = 0; $l -le $linesToClear; $l++)
            { Write-Host "$esc[1A$esc[2K" -NoNewline
            }

            if ($key.Character -match "[1-5]")
            {
                $choiceIdx = [int][string]$key.Character - 1
                [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $txt.Length, $options[$choiceIdx])
            }
            [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
        }

        # --- ОТЛАДКА: если опций нет, покажем что ответила модель ---
        if ($options.Count -eq 0 -and $cleanRaw)
        {
            Write-Host "`n [Sentinel Debug]: Model returned '$cleanRaw' but it didn't match '$txt'" -ForegroundColor Gray
            return
        }
    } catch
    {
        Write-Host " [Sentinel Error: $($_.Exception.Message)]" -ForegroundColor Yellow
    }
}

Set-PSReadLineKeyHandler -Chord 'Alt+a' -ScriptBlock { Get-AICompletion }
Set-PSReadLineKeyHandler -Chord 'Alt+ф' -ScriptBlock { Get-AICompletion }
