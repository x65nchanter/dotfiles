local wezterm = require 'wezterm'
local act = wezterm.action

local config = {}

-- Глобальная переменная для хранения ID таба с AI ассистентом
wezterm.GLOBAL.ai_tab_id = wezterm.GLOBAL.ai_tab_id or nil

if wezterm.config_builder then
    config = wezterm.config_builder()
end

-- === DEFAULT SHELL SETTING ===
config.default_prog = { "pwsh.exe", "-NoLogo" }
config.term = "wezterm"
config.set_environment_variables = {
    ["LANG"] = "ru_RU.UTF-8",
    -- Если LANG уже установлен в системе, можно попробовать LC_ALL
    ["LC_ALL"] = "ru_RU.UTF-8",
}


-- === ШРИФТ И ЛИГАТУРЫ ===
config.font = wezterm.font_with_fallback({
    { family = 'JetBrainsMono Nerd Font', weight = 'Medium' },
    'Segoe UI Emoji', -- Для смайликов и иконок в Windows
})
config.font_size = 14.0

-- === ЦВЕТОВАЯ СХЕМА (JetBrains Dark) ===
config.colors = {
    foreground   = '#a9b7c6',
    background   = '#1e1f22',
    cursor_bg    = '#bbbbbb',
    selection_bg = '#214283',
    selection_fg = '#a9b7c6',
    tab_bar      = {
        background = '#1e1f22',
        active_tab = { bg_color = '#2d2f33', fg_color = '#dfe1e5' },
        inactive_tab = { bg_color = '#1e1f22', fg_color = '#7e818c' },
    }
}

-- === ФУНКЦИЯ ОПРЕДЕЛЕНИЯ GIT ВЕТКИ ===
local function get_git_branch(pane)
    local cwd = pane:get_current_working_dir()
    if not cwd then return "" end

    -- Превращаем объект URL в путь (зависит от ОС)
    local path = cwd.file_path

    -- Выполняем git команду асинхронно (чтобы не фризить UI)
    local success, stdout, stderr = wezterm.run_child_process({
        'git', '-C', path, 'rev-parse', '--abbrev-ref', 'HEAD'
    })

    if success then
        return "  " .. stdout:gsub("\n", "") .. " "
    end
    return ""
end

-- === ФУНКЦИЯ ОПРЕДЕЛЕНИЯ GPU (ДИНАМИЧЕСКАЯ) ===
local function get_gpu_info()
    -- Добавляем memory.used и memory.total для расчета % VRAM
    local success, stdout, stderr = wezterm.run_child_process({
        'nvidia-smi', '--query-gpu=gpu_name,utilization.gpu,temperature.gpu,memory.used,memory.total',
        '--format=csv,noheader,nounits'
    })

    if success then
        local name, load, temp, mem_used, mem_total = stdout:match("([^,]+),%s*([^,]+),%s*([^,]+),%s*([^,]+),%s*([^,]+)")
        if name then
            local clean_name = name:gsub("NVIDIA ", ""):gsub(" GeForce", ""):gsub(" RTX", ""):gsub(" Series", ""):gsub(
            "^%s*(.-)%s*$", "%1")

            -- Считаем процент VRAM
            local vram_pct = (tonumber(mem_used) / tonumber(mem_total)) * 100

            return {
                name = clean_name,
                load = load:gsub("^%s*(.-)%s*$", "%1"),
                temp = temp:gsub("^%s*(.-)%s*$", "%1"),
                vram = string.format("%.0f", vram_pct)
            }
        end
    end
    return nil
end

-- === СТАТУС-БАР ===
wezterm.on('update-status', function(window, pane)
    local date = wezterm.strftime('%H:%M:%S')
    local user = os.getenv("USERNAME") or "Engineer"
    local git = get_git_branch(pane)
    local active_tab = window:active_tab()

    local gpu = get_gpu_info()
    local gpu_text = gpu and (gpu.name .. " " .. gpu.load .. "% " .. gpu.temp .. "°C") or "GPU Offline"
    local vram_text = gpu and (gpu.vram .. "%") or "0%"

    local lock_icon = ""
    if wezterm.GLOBAL.ai_tab_id and active_tab:tab_id() == wezterm.GLOBAL.ai_tab_id then
        lock_icon = "  "
    end

    window:set_right_status(wezterm.format({
        { Foreground = { Color = '#a9b7c6' } }, { Text = lock_icon .. '   ' .. user .. ' ' },
        { Foreground = { Color = '#629755' } }, { Text = git },
        { Foreground = { Color = '#cc7832' } }, { Text = '   ' .. gpu_text .. ' ' },
        -- Секция VRAM с процентами из nvidia-smi
        { Foreground = { Color = '#9876aa' } }, { Text = '   ' .. vram_text .. ' ' },
        { Foreground = { Color = '#ffc66d' } }, { Text = '   ' .. date .. ' ' },
    }))
end)

-- === ОБРАБОТКА ВРЕМЕНИ ВЫПОЛНЕНИЯ (Индикатор в табах) ===
-- WezTerm может показывать, сколько работала последняя команда
config.status_update_interval = 1000

-- === НАСТРОЙКИ ОКНА ===
config.window_decorations = "NONE"
config.initial_cols = 160
config.initial_rows = 35
config.window_background_opacity = 0.9
config.front_end = "WebGpu"

-- === Таб с ассистентом ===
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
    if wezterm.GLOBAL.ai_tab_id ~= nil and tab.tab_id == wezterm.GLOBAL.ai_tab_id then
        local bg = '#2b2042' -- Темно-пурпурный фон
        local fg = '#c6a0f6' -- Светло-пурпурный текст

        if tab.is_active then
            bg = '#4c366e' -- Ярче, если активна
            fg = '#ffffff'
        end

        return {
            { Background = { Color = bg } },
            { Foreground = { Color = fg } },
            { Text = "1: AI Assistant  " },
        }
    end
    -- Для остальных вкладок возвращаем стандартный вид
    return nil
end)

-- === АВТОЗАПУСК (Версия для Windows 2026) ===
wezterm.on('gui-startup', function(cmd)
    local mux = wezterm.mux

    -- 1. Создаем окно и первый таб с ассистентом
    -- Используем полное имя cmd.exe и ключ /k (чтобы окно не закрылось при ошибке)
    local tab_ai, pane_ai, window = mux.spawn_window({
        args = {
            "cmd.exe", "/C",
            "title AI Assistant && " ..
            "for /L %i in () do (" ..
            "  opencode --model lmstudio/zai-org/glm-4.7-flash " ..
            "  && timeout /t 5" ..
            ")"
        },
        set_environment_variables = {
            ["OPENAI_API_BASE"] = "http://127.0.0.1",
            ["OPENAI_API_KEY"] = "lm-studio",
            ["AI_MAX_TOKENS"] = "32768",
            ["AI_CONTEXT_STRATEGY"] = "rolling",
            ["USE_MCP"] = "true",
        }
    })

    -- СОХРАНЯЕМ ID ПЕРВОГО ТАБА
    wezterm.GLOBAL.ai_tab_id = tab_ai:tab_id()

    tab_ai:set_title("AI Assistant")

    -- 2. Создаем второй таб для обычной работы
    local tab_work, pane_work, _ = window:spawn_tab({})
    tab_work:set_title("Work")

    -- 3. Фокусируемся на рабочем табе (втором)
    tab_work:activate()
end)

-- === ГОРЯЧИЕ КЛАВИШИ ===
config.keys = {

    -- Копирование и вставка
    { key = 'phys:C', mods = 'CTRL|SHIFT', action = act.CopyTo 'Clipboard' },
    { key = 'phys:V', mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard' },


    -- ЗАКРЫТИЕ ТАБА
    {
        key = 'phys:Q',
        mods = 'CTRL',
        action = wezterm.action_callback(function(window, pane)
            local active_tab = window:active_tab()
            local current_id = active_tab:tab_id()

            -- Сравниваем ID текущего таба с ID нашего ассистента
            if wezterm.GLOBAL.ai_tab_id and current_id == wezterm.GLOBAL.ai_tab_id then
                window:toast_notification("WezTerm", "Этот таб защищен (AI Assistant)", nil, 2000)
            else
                window:perform_action(act.CloseCurrentTab { confirm = false }, pane)
            end
        end),
    },

    -- Скопировать последний вывод в буфер обмена
    {
        key = 'phys:D', -- Можно заменить на другую клавишу
        mods = 'CTRL|SHIFT',
        action = wezterm.action_callback(function(window, pane)
            -- Получаем информацию о видимых строках терминала
            local info = pane:get_logical_lines_as_text(1000) -- берем последние 1000 строк

            -- Разбиваем на строки
            local lines = {}
            for line in info:gmatch("[^\n]+") do
                table.insert(lines, line)
            end

            -- Ищем последний блок текста.
            -- Обычно вывод команды находится между последним и предпоследним появлением промпта.
            -- Мы просто возьмем последние 20 строк вывода (самый простой и надежный способ для CLI)
            local result = ""
            local count = #lines
            local start_idx = count > 20 and count - 20 or 1

            for i = start_idx, count do
                -- Пропускаем пустые строки или саму строку ввода (если там есть значки > или $)
                if not lines[i]:find("^%s*$") then
                    result = result .. lines[i] .. "\n"
                end
            end

            if result ~= "" then
                window:copy_to_clipboard(result)
                window:toast_notification("WezTerm", "Последний вывод скопирован! 📋", nil, 2000)
            end
        end),
    },

    -- Вызов помощи ассистента (исправлено)
    {
        key = 'F1',
        mods = 'CTRL',
        action = wezterm.action_callback(function(window, pane)
            local mux = wezterm.mux
            local ai_tab_id = wezterm.GLOBAL.ai_tab_id
            local found_tab = nil

            -- 1. Поиск вкладки
            if ai_tab_id ~= nil then
                local success, result = pcall(mux.get_tab, ai_tab_id)
                if success and result then found_tab = result end
            end

            if found_tab then
                -- Если нашли — активируем
                found_tab:activate()

                -- Двигаем в начало через PERFORM_ACTION (это надежнее методов)
                window:perform_action(wezterm.action.MoveTab(0), found_tab:active_pane())

                -- Вставляем текст
                window:perform_action(wezterm.action.PasteFrom("Clipboard"), found_tab:active_pane())
            else
                -- 2. Создаем новую вкладку
                local tab_ai, pane_ai, _ = window:mux_window():spawn_tab({
                    args = {
                        "cmd.exe", "/C",
                        "title AI Assistant && for /L %i in () do ( opencode --model lmstudio/zai-org/glm-4.7-flash || timeout /t 5 )"
                    },
                })

                wezterm.GLOBAL.ai_tab_id = tab_ai:tab_id()
                tab_ai:set_title("AI Assistant")

                -- 3. Асинхронная настройка (чтобы не было nil при обращении к еще создаваемому объекту)
                wezterm.time_it(function()
                    wezterm.sleep_ms(200) -- Даем время на инициализацию

                    -- Активируем и двигаем в начало
                    tab_ai:activate()
                    window:perform_action(wezterm.action.MoveTab(0), pane_ai)

                    -- Ждем загрузки opencode и вставляем
                    wezterm.sleep_ms(800)
                    window:perform_action(wezterm.action.PasteFrom("Clipboard"), pane_ai)
                end)
            end
        end),
    },

    -- Семантическое выделение (Ctrl + W)
    {
        key = 'phys:W',
        mods = 'CTRL',
        action = act.QuickSelectArgs({
            label = 'Select',
            patterns = { '[a-zA-Z0-9_\\-/.]+' },
        })
    },

    -- Табы Alt + 1..9
    { key = '1',      mods = 'ALT',  action = act.ActivateTab(0) },
    { key = '2',      mods = 'ALT',  action = act.ActivateTab(1) },
    { key = '3',      mods = 'ALT',  action = act.ActivateTab(2) },
    { key = '4',      mods = 'ALT',  action = act.ActivateTab(3) },
    { key = '5',      mods = 'ALT',  action = act.ActivateTab(4) },
    { key = '6',      mods = 'ALT',  action = act.ActivateTab(5) },
    { key = '7',      mods = 'ALT',  action = act.ActivateTab(6) },
    { key = '8',      mods = 'ALT',  action = act.ActivateTab(7) },
    { key = '9',      mods = 'ALT',  action = act.ActivateTab(8) },

    { key = 'phys:F', mods = 'CTRL', action = act.Search 'CurrentSelectionOrEmptyString' },
    { key = 'phys:N', mods = 'CTRL', action = act.SpawnTab 'DefaultDomain' },
}

return config
