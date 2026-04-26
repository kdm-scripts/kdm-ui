-- KDM UI Library
-- Основной файл: kdm_ui.lua
-- Создаёт внешний интерфейс для читов в Roblox

local KDM = {}
KDM.__index = KDM

-- Сервисы
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- Drawing-библиотека
local Drawing = Drawing or game:GetService("Drawing")
if not Drawing then
    warn("Drawing library is not available")
    return
end

-- Внутренние переменные
local ActiveWindows = {}
local Connections = {}

-- Цветовая палитра по умолчанию
local Colors = {
    Background = Color3.fromRGB(25, 25, 25),
    Header = Color3.fromRGB(35, 35, 35),
    Tab = Color3.fromRGB(30, 30, 30),
    TabActive = Color3.fromRGB(50, 50, 50),
    Element = Color3.fromRGB(40, 40, 40),
    ElementHover = Color3.fromRGB(55, 55, 55),
    Accent = Color3.fromRGB(65, 130, 255),
    Text = Color3.fromRGB(255, 255, 255),
    TextDark = Color3.fromRGB(180, 180, 180),
    SliderBg = Color3.fromRGB(50, 50, 50),
    SliderFill = Color3.fromRGB(65, 130, 255),
    ToggleOff = Color3.fromRGB(60, 60, 60),
    ToggleOn = Color3.fromRGB(65, 130, 255),
    ToggleCircle = Color3.fromRGB(255, 255, 255),
}

-- Утилиты
local function round(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Класс элемента интерфейса
local UIElement = {}
UIElement.__index = UIElement

function UIElement.new(Type)
    local self = setmetatable({}, UIElement)
    self.Type = Type
    self.Visible = true
    self.Active = true
    self.Hovered = false
    self.Drawings = {}
    self.Connections = {}
    self.Callback = nil
    return self
end

function UIElement:Destroy()
    for _, drawing in ipairs(self.Drawings) do
        if drawing.Remove then
            drawing:Remove()
        end
    end
    for _, conn in ipairs(self.Connections) do
        conn:Disconnect()
    end
end

-- Класс Tab
local Tab = {}
Tab.__index = Tab

function Tab.new(Window, Name, Icon)
    local self = setmetatable({}, Tab)
    self.Window = Window
    self.Name = Name
    self.Icon = Icon
    self.Elements = {}
    self.Visible = false
    self.Button = nil
    self.ButtonText = nil
    self.Container = {}
    return self
end

function Tab:Activate()
    self.Visible = true
    for _, elem in ipairs(self.Elements) do
        if elem.Visible then
            for _, d in ipairs(elem.Drawings) do
                d.Visible = true
            end
        end
    end
    --
    if self.Button then
        self.Button.Color = Colors.TabActive
    end
end

function Tab:Deactivate()
    self.Visible = false
    for _, elem in ipairs(self.Elements) do
        for _, d in ipairs(elem.Drawings) do
            d.Visible = false
        end
    end
    if self.Button then
        self.Button.Color = Colors.Tab
    end
end

-- Класс Window
local Window = {}
Window.__index = Window

function Window.new(options)
    local self = setmetatable({}, Window)
    options = options or {}
    self.Name = options.Name or "KDM UI"
    self.Width = options.Width or 500
    self.Height = options.Height or 350
    self.Position = options.Position or Vector2.new(100, 100)
    self.Tabs = {}
    self.ActiveTab = nil
    self.Dragging = false
    self.DragStart = nil
    self.MainContainer = {}
    self.Elements = {}

    -- Создание базового фрейма
    -- Тень окна
    local shadow = Drawing.new("Square")
    shadow.Size = Vector2.new(self.Width + 8, self.Height + 8)
    shadow.Position = self.Position - Vector2.new(4, 4)
    shadow.Color = Color3.new(0, 0, 0)
    shadow.Transparency = 0.6
    shadow.Filled = true
    shadow.Visible = true
    table.insert(self.MainContainer, shadow)

    -- Основной прямоугольник
    local main = Drawing.new("Square")
    main.Size = Vector2.new(self.Width, self.Height)
    main.Position = self.Position
    main.Color = Colors.Background
    main.Filled = true
    main.Visible = true
    table.insert(self.MainContainer, main)

    -- Заголовок
    local header = Drawing.new("Square")
    header.Size = Vector2.new(self.Width, 30)
    header.Position = self.Position
    header.Color = Colors.Header
    header.Filled = true
    table.insert(self.MainContainer, header)

    local titleText = Drawing.new("Text")
    titleText.Text = self.Name
    titleText.Position = self.Position + Vector2.new(8, 5)
    titleText.Size = 18
    titleText.Color = Colors.Text
    titleText.Font = Drawing.Fonts.SourceSansBold
    titleText.Visible = true
    table.insert(self.MainContainer, titleText)

    self.Main = main
    self.Header = header
    self.TitleText = titleText

    -- Обработчики перетаскивания
    local startDragConn
    local stopDragConn
    local dragConn

    startDragConn = UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UIS:GetMouseLocation()
            local x = mousePos.X
            local y = mousePos.Y
            if x >= self.Position.X and x <= self.Position.X + self.Width
                and y >= self.Position.Y and y <= self.Position.Y + 30 then
                self.Dragging = true
                self.DragStart = Vector2.new(x - self.Position.X, y - self.Position.Y)
            end
        end
    end)

    stopDragConn = UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Dragging = false
        end
    end)

    dragConn = RunService.RenderStepped:Connect(function()
        if self.Dragging then
            local mousePos = UIS:GetMouseLocation()
            local newPos = Vector2.new(mousePos.X - self.DragStart.X, mousePos.Y - self.DragStart.Y)
            -- Обновление позиций всех drawings
            local delta = newPos - self.Position
            self.Position = newPos
            for _, d in ipairs(self.MainContainer) do
                d.Position = d.Position + delta
            end
            -- Табы и элементы обновят позиции через методы табов
            for _, tab in ipairs(self.Tabs) do
                if tab.Button then
                    tab.Button.Position = tab.Button.Position + delta
                end
                if tab.ButtonText then
                    tab.ButtonText.Position = tab.ButtonText.Position + delta
                end
                for _, elem in ipairs(tab.Elements) do
                    for _, d in ipairs(elem.Drawings) do
                        d.Position = d.Position + delta
                    end
                end
            end
            self.DragStart = mousePos - newPos
        end
    end)

    table.insert(self.Elements, { Type = "DragConnection", Conn = startDragConn })
    table.insert(self.Elements, { Type = "DragConnection", Conn = stopDragConn })
    table.insert(self.Elements, { Type = "DragConnection", Conn = dragConn })

    -- Кнопка закрытия (X)
    local closeBtn = Drawing.new("Square")
    closeBtn.Size = Vector2.new(20, 20)
    closeBtn.Position = self.Position + Vector2.new(self.Width - 25, 5)
    closeBtn.Color = Color3.fromRGB(255, 70, 70)
    closeBtn.Filled = true
    closeBtn.Visible = true
    table.insert(self.MainContainer, closeBtn)

    local closeText = Drawing.new("Text")
    closeText.Text = "X"
    closeText.Position = closeBtn.Position + Vector2.new(4, 0)
    closeText.Size = 16
    closeText.Color = Colors.Text
    closeText.Font = Drawing.Fonts.SourceSansBold
    closeText.Visible = true
    table.insert(self.MainContainer, closeText)

    local closeConn = UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UIS:GetMouseLocation()
            if mousePos.X >= closeBtn.Position.X and mousePos.X <= closeBtn.Position.X + 20
                and mousePos.Y >= closeBtn.Position.Y and mousePos.Y <= closeBtn.Position.Y + 20 then
                self:Destroy()
            end
        end
    end)
    table.insert(self.Elements, { Type = "CloseConnection", Conn = closeConn })

    -- Регистрация окна
    table.insert(ActiveWindows, self)
    return self
end

function Window:AddTab(name, icon)
    local tab = Tab.new(self, name, icon)
    local tabWidth = #self.Tabs * 100 + 10
    local tabX = self.Position.X + 10 + (#self.Tabs * 100)
    local tabY = self.Position.Y + 35
    local tabBtn = Drawing.new("Square")
    tabBtn.Size = Vector2.new(95, 25)
    tabBtn.Position = Vector2.new(tabX, tabY)
    tabBtn.Color = (#self.Tabs == 0) and Colors.TabActive or Colors.Tab
    tabBtn.Filled = true
    tabBtn.Visible = true
    table.insert(self.MainContainer, tabBtn)

    local tabText = Drawing.new("Text")
    tabText.Text = name
    tabText.Position = tabBtn.Position + Vector2.new(5, 3)
    tabText.Size = 15
    tabText.Color = Colors.Text
    tabText.Font = Drawing.Fonts.SourceSans
    tabText.Visible = true
    table.insert(self.MainContainer, tabText)

    tab.Button = tabBtn
    tab.ButtonText = tabText

    local tabClickConn = UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UIS:GetMouseLocation()
            if mousePos.X >= tabBtn.Position.X and mousePos.X <= tabBtn.Position.X + 95
                and mousePos.Y >= tabBtn.Position.Y and mousePos.Y <= tabBtn.Position.Y + 25 then
                self:SelectTab(tab)
            end
        end
    end)
    table.insert(tab.Elements, { Type = "TabConnection", Conn = tabClickConn })

    table.insert(self.Tabs, tab)
    if #self.Tabs == 1 then
        self:SelectTab(tab)
    end
    return tab
end

function Window:SelectTab(tab)
    if self.ActiveTab then
        self.ActiveTab:Deactivate()
    end
    self.ActiveTab = tab
    tab:Activate()
end

function Window:Destroy()
    for _, elem in ipairs(self.Elements) do
        if elem.Conn then elem.Conn:Disconnect() end
    end
    for _, d in ipairs(self.MainContainer) do
        if d.Remove then d:Remove() end
    end
    for _, tab in ipairs(self.Tabs) do
        for _, elem in ipairs(tab.Elements) do
            for _, d in ipairs(elem.Drawings) do
                if d.Remove then d:Remove() end
            end
            if elem.Connections then
                for _, c in ipairs(elem.Connections) do
                    c:Disconnect()
                end
            end
        end
    end
end

-- Методы для элементов внутри вкладки
-- Кнопка
function Tab:AddButton(text, callback)
    local element = UIElement.new("Button")
    element.Callback = callback
    local yOffset = (#self.Elements * 35) + 10
    local xPos = self.Window.Position.X + 10
    local yPos = self.Window.Position.Y + 65 + yOffset

    local btn = Drawing.new("Square")
    btn.Size = Vector2.new(self.Window.Width - 20, 30)
    btn.Position = Vector2.new(xPos, yPos)
    btn.Color = Colors.Element
    btn.Filled = true
    btn.Visible = false
    table.insert(element.Drawings, btn)

    local btnText = Drawing.new("Text")
    btnText.Text = text
    btnText.Position = btn.Position + Vector2.new(5, 5)
    btnText.Size = 16
    btnText.Color = Colors.Text
    btnText.Font = Drawing.Fonts.SourceSans
    btnText.Visible = false
    table.insert(element.Drawings, btnText)

    -- Наведение и клик
    local hover = false
    local inputConn = UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and element.Visible and element.Active then
            local mousePos = UIS:GetMouseLocation()
            if mousePos.X >= btn.Position.X and mousePos.X <= btn.Position.X + btn.Size.X
                and mousePos.Y >= btn.Position.Y and mousePos.Y <= btn.Position.Y + btn.Size.Y then
                if callback then
                    callback()
                end
            end
        end
    end)
    table.insert(element.Connections, inputConn)

    local renderConn = RunService.RenderStepped:Connect(function()
        if not element.Visible or not element.Active then return end
        local mousePos = UIS:GetMouseLocation()
        hover = (mousePos.X >= btn.Position.X and mousePos.X <= btn.Position.X + btn.Size.X
            and mousePos.Y >= btn.Position.Y and mousePos.Y <= btn.Position.Y + btn.Size.Y)
        if hover then
            btn.Color = Colors.ElementHover
        else
            btn.Color = Colors.Element
        end
    end)
    table.insert(element.Connections, renderConn)

    table.insert(self.Elements, element)
    return element
end

-- Тоггл
function Tab:AddToggle(text, default, callback)
    local element = UIElement.new("Toggle")
    element.Value = default or false
    element.Callback = callback
    local yOffset = (#self.Elements * 35) + 10
    local xPos = self.Window.Position.X + 10
    local yPos = self.Window.Position.Y + 65 + yOffset

    -- Фон переключателя
    local toggleBg = Drawing.new("Square")
    toggleBg.Size = Vector2.new(20, 10)
    toggleBg.Position = Vector2.new(xPos + 80, yPos + 5)
    toggleBg.Color = element.Value and Colors.ToggleOn or Colors.ToggleOff
    toggleBg.Filled = true
    toggleBg.Visible = false
    table.insert(element.Drawings, toggleBg)

    -- Кружок
    local toggleCircle = Drawing.new("Square")
    toggleCircle.Size = Vector2.new(14, 14)
    toggleCircle.Position = element.Value and (toggleBg.Position + Vector2.new(6, -2)) or (toggleBg.Position - Vector2.new(0, 2))
    toggleCircle.Color = Colors.ToggleCircle
    toggleCircle.Filled = true
    toggleCircle.Visible = false
    table.insert(element.Drawings, toggleCircle)

    -- Текст
    local labelText = Drawing.new("Text")
    labelText.Text = text
    labelText.Position = Vector2.new(xPos, yPos + 5)
    labelText.Size = 15
    labelText.Color = Colors.Text
    labelText.Font = Drawing.Fonts.SourceSans
    labelText.Visible = false
    table.insert(element.Drawings, labelText)

    local function updateVisuals()
        toggleBg.Color = element.Value and Colors.ToggleOn or Colors.ToggleOff
        toggleCircle.Position = element.Value and (toggleBg.Position + Vector2.new(6, -2)) or (toggleBg.Position - Vector2.new(0, 2))
    end

    local inputConn = UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and element.Visible and element.Active then
            local mousePos = UIS:GetMouseLocation()
            if mousePos.X >= toggleBg.Position.X - 5 and mousePos.X <= toggleBg.Position.X + 25
                and mousePos.Y >= toggleBg.Position.Y - 5 and mousePos.Y <= toggleBg.Position.Y + 15 then
                element.Value = not element.Value
                updateVisuals()
                if callback then
                    callback(element.Value)
                end
            end
        end
    end)
    table.insert(element.Connections, inputConn)

    table.insert(self.Elements, element)
    return element
end

-- Слайдер
function Tab:AddSlider(text, min, max, default, callback)
    local element = UIElement.new("Slider")
    element.Min = min
    element.Max = max
    element.Value = default or min
    element.Callback = callback
    local yOffset = (#self.Elements * 35) + 10
    local xPos = self.Window.Position.X + 10
    local yPos = self.Window.Position.Y + 65 + yOffset
    local sliderWidth = self.Window.Width - 100

    -- Текст
    local labelText = Drawing.new("Text")
    labelText.Text = text .. ": " .. round(element.Value, 1)
    labelText.Position = Vector2.new(xPos, yPos)
    labelText.Size = 15
    labelText.Color = Colors.Text
    labelText.Font = Drawing.Fonts.SourceSans
    labelText.Visible = false
    table.insert(element.Drawings, labelText)

    -- Фон слайдера
    local sliderBg = Drawing.new("Square")
    sliderBg.Size = Vector2.new(sliderWidth, 6)
    sliderBg.Position = Vector2.new(xPos + 5, yPos + 20)
    sliderBg.Color = Colors.SliderBg
    sliderBg.Filled = true
    sliderBg.Visible = false
    table.insert(element.Drawings, sliderBg)

    -- Заполненная часть
    local sliderFill = Drawing.new("Square")
    local fillWidth = ((element.Value - min) / (max - min)) * sliderWidth
    sliderFill.Size = Vector2.new(fillWidth, 6)
    sliderFill.Position = sliderBg.Position
    sliderFill.Color = Colors.SliderFill
    sliderFill.Filled = true
    sliderFill.Visible = false
    table.insert(element.Drawings, sliderFill)

    -- Кружок слайдера
    local sliderKnob = Drawing.new("Square")
    sliderKnob.Size = Vector2.new(10, 10)
    sliderKnob.Position = Vector2.new(sliderBg.Position.X + fillWidth - 5, sliderBg.Position.Y - 2)
    sliderKnob.Color = Colors.ToggleCircle
    sliderKnob.Filled = true
    sliderKnob.Visible = false
    table.insert(element.Drawings, sliderKnob)

    local draggingSlider = false

    local function setValFromMouse(mouseX)
        local relX = mouseX - sliderBg.Position.X
        relX = math.clamp(relX, 0, sliderWidth)
        local percent = relX / sliderWidth
        element.Value = min + (max - min) * percent
        element.Value = round(element.Value, 1)
        -- обновление визуала
        sliderFill.Size = Vector2.new(relX, 6)
        sliderKnob.Position = Vector2.new(sliderBg.Position.X + relX - 5, sliderBg.Position.Y - 2)
        labelText.Text = text .. ": " .. round(element.Value, 1)
        if callback then
            callback(element.Value)
        end
    end

    local inputBeganConn = UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and element.Visible and element.Active then
            local mousePos = UIS:GetMouseLocation()
            if mousePos.X >= sliderBg.Position.X - 10 and mousePos.X <= sliderBg.Position.X + sliderWidth + 10
                and mousePos.Y >= sliderBg.Position.Y - 5 and mousePos.Y <= sliderBg.Position.Y + 15 then
                draggingSlider = true
                setValFromMouse(mousePos.X)
            end
        end
    end)
    table.insert(element.Connections, inputBeganConn)

    local inputEndedConn = UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = false
        end
    end)
    table.insert(element.Connections, inputEndedConn)

    local renderConn = RunService.RenderStepped:Connect(function()
        if draggingSlider and element.Visible and element.Active then
            local mousePos = UIS:GetMouseLocation()
            setValFromMouse(mousePos.X)
        end
    end)
    table.insert(element.Connections, renderConn)

    table.insert(self.Elements, element)
    return element
end

-- Текстовое поле
function Tab:AddTextbox(text, placeholder, callback)
    local element = UIElement.new("Textbox")
    element.Value = ""
    element.Placeholder = placeholder or ""
    element.Callback = callback
    local yOffset = (#self.Elements * 35) + 10
    local xPos = self.Window.Position.X + 10
    local yPos = self.Window.Position.Y + 65 + yOffset
    local textboxWidth = self.Window.Width - 120

    -- Label
    local labelText = Drawing.new("Text")
    labelText.Text = text
    labelText.Position = Vector2.new(xPos, yPos + 5)
    labelText.Size = 15
    labelText.Color = Colors.Text
    labelText.Font = Drawing.Fonts.SourceSans
    labelText.Visible = false
    table.insert(element.Drawings, labelText)

    -- Поле ввода
    local inputBg = Drawing.new("Square")
    inputBg.Size = Vector2.new(textboxWidth, 25)
    inputBg.Position = Vector2.new(xPos + 70, yPos)
    inputBg.Color = Colors.Element
    inputBg.Filled = true
    inputBg.Visible = false
    table.insert(element.Drawings, inputBg)

    local inputText = Drawing.new("Text")
    inputText.Text = placeholder
    inputText.Position = inputBg.Position + Vector2.new(3, 3)
    inputText.Size = 15
    inputText.Color = Colors.TextDark
    inputText.Font = Drawing.Fonts.SourceSans
    inputText.Visible = false
    table.insert(element.Drawings, inputText)

    element.InputBg = inputBg
    element.InputText = inputText

    local focused = false

    local function updateTextDisplay()
        if element.Value == "" then
            inputText.Text = element.Placeholder
            inputText.Color = Colors.TextDark
        else
            inputText.Text = element.Value
            inputText.Color = Colors.Text
        end
    end

    local clickConn = UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and element.Visible and element.Active then
            local mousePos = UIS:GetMouseLocation()
            if mousePos.X >= inputBg.Position.X and mousePos.X <= inputBg.Position.X + textboxWidth
                and mousePos.Y >= inputBg.Position.Y and mousePos.Y <= inputBg.Position.Y + 25 then
                focused = true
                inputBg.Color = Colors.ElementHover
            else
                focused = false
                inputBg.Color = Colors.Element
                if callback then
                    callback(element.Value)
                end
            end
        end
    end)
    table.insert(element.Connections, clickConn)

    local keyConn = UIS.InputBegan:Connect(function(input, gameProcessed)
        if focused and not gameProcessed then
            if input.KeyCode == Enum.KeyCode.Backspace then
                element.Value = string.sub(element.Value, 1, -2)
                updateTextDisplay()
            end
        end
    end)
    table.insert(element.Connections, keyConn)

    local textInputConn = UIS.TextInputBegan:Connect(function(text)
        if focused then
            element.Value = element.Value .. text
            updateTextDisplay()
        end
    end)
    table.insert(element.Connections, textInputConn)

    table.insert(self.Elements, element)
    return element
end

-- Лейбл
function Tab:AddLabel(text)
    local element = UIElement.new("Label")
    local yOffset = (#self.Elements * 35) + 10
    local xPos = self.Window.Position.X + 10
    local yPos = self.Window.Position.Y + 65 + yOffset + 5

    local label = Drawing.new("Text")
    label.Text = text
    label.Position = Vector2.new(xPos, yPos)
    label.Size = 15
    label.Color = Colors.Text
    label.Font = Drawing.Fonts.SourceSans
    label.Visible = false
    table.insert(element.Drawings, label)

    table.insert(self.Elements, element)
    return element
end

-- Разделитель
function Tab:AddSeparator()
    local element = UIElement.new("Separator")
    local yOffset = (#self.Elements * 35) + 10
    local xPos = self.Window.Position.X + 10
    local yPos = self.Window.Position.Y + 65 + yOffset + 5

    local line = Drawing.new("Line")
    line.From = Vector2.new(xPos, yPos)
    line.To = Vector2.new(xPos + self.Window.Width - 20, yPos)
    line.Color = Colors.Accent
    line.Thickness = 2
    line.Visible = false
    table.insert(element.Drawings, line)

    table.insert(self.Elements, element)
    return element
end

-- Публичные методы для совместимости
function KDM:CreateWindow(options)
    return Window.new(options)
end

-- Возвращаем библиотеку
return KDM
