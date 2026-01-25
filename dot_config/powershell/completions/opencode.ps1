Register-ArgumentCompleter -Native -CommandName opencode -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    
    # Получаем все аргументы из текущей строки
    $elements = $commandAst.Elements | ForEach-Object { $_.ToString() }
    
    # Вызываем yargs-движок opencode для получения списка дополнений
    $completions = opencode --get-yargs-completions $elements
    
    $completions | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
