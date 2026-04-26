-- example.lua
-- Демонстрация всех возможностей KDM UI Library

local KDM = loadstring(game:HttpGet("https://raw.githubusercontent.com/kdm-scripts/kdm-ui/refs/heads/main/kdm_ui.lua"))()

-- Создаём окно
local window = KDM:CreateWindow({
    Name = "KDM UI Example",
    Width = 550,
    Height = 400,
    Position = Vector2.new(200, 150)
})

-- Первая вкладка: Основные элементы
local tabMain = window:AddTab("Main", "home")

tabMain:AddButton("Нажми меня", function()
    print("Кнопка нажата!")
end)

tabMain:AddToggle("Включить ESP", false, function(state)
    print("ESP теперь " .. (state and "включен" or "выключен"))
end)

tabMain:AddSlider("Скорость", 0, 100, 50, function(value)
    print("Скорость: " .. value)
end)

tabMain:AddTextbox("Ник", "Введите ник", function(text)
    print("Введён ник: " .. text)
end)

tabMain:AddLabel("Это просто текстовая метка")

tabMain:AddSeparator()

tabMain:AddButton("Ещё кнопка", function()
    warn("Действие выполнено")
end)

-- Вторая вкладка: Дополнительно
local tabExtra = window:AddTab("Extra", "star")

tabExtra:AddToggle("Aimbot", false, function(state)
    print("Aimbot " .. (state and "ON" or "OFF"))
end)

tabExtra:AddSlider("Радиус обзора", 0, 1000, 300, function(value)
    print("Радиус: " .. value .. " studs")
end)

tabExtra:AddTextbox("Команда", "/command", function(cmd)
    print("Выполнена команда: " .. cmd)
end)

tabExtra:AddLabel("Настройки завершены")
tabExtra:AddSeparator()
tabExtra:AddButton("Сброс", function()
    print("Настройки сброшены")
end)

-- Третья вкладка: Информация
local tabInfo = window:AddTab("Info", "info")
tabInfo:AddLabel("KDM UI Library v1.0")
tabInfo:AddLabel("Разработано командой kdm-scripts")
tabInfo:AddSeparator()
tabInfo:AddButton("Закрыть окно", function()
    window:Destroy()
end)

print("KDM UI Example загружен. Окно открыто.")
