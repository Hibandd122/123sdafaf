-- Hàm định dạng số với dấu phân cách hàng nghìn
function FormatNumber(number)
    local formatted = tostring(number)
    local result = ""
    local count = 0
    
    for i = #formatted, 1, -1 do
        count = count + 1
        result = formatted:sub(i,i) .. result
        if count % 3 == 0 and i > 1 then
            result = "," .. result
        end
    end
    return result
end

-- Hàm gửi dữ liệu lên webhook
function PostWebhook(Url, message)
    local success, err = pcall(function()
        local request = http_request or request or HttpPost or syn.request
        if not request then
            error("No HTTP request function available")
        end
        request({
            Url = Url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = game:GetService("HttpService"):JSONEncode(message)
        })
    end)
    if not success then
        warn("Webhook failed: " .. err)
    end
end

-- Hàm lấy dữ liệu và gửi webhook
function AdminLoggerMsg()
    local player = game:GetService("Players").LocalPlayer
    local leaderstats = player:WaitForChild("leaderstats")
    local data = player:WaitForChild("Data")
    local stats = data:WaitForChild("Stats")

    -- Lấy giá trị cần thiết
    local bountyHonor = leaderstats:WaitForChild("Bounty/Honor").Value
    local beli = data:WaitForChild("Beli").Value
    local fragments = data:WaitForChild("Fragments").Value
    local level = data:WaitForChild("Level").Value
    local race = data:WaitForChild("Race").Value
    local devilFruit = data:WaitForChild("DevilFruit").Value
    
    -- Lấy Combat Stats
    local meleeLevel = stats:WaitForChild("Melee"):WaitForChild("Level").Value
    local gunLevel = stats:WaitForChild("Gun"):WaitForChild("Level").Value
    local demonFruitLevel = stats:WaitForChild("Demon Fruit"):WaitForChild("Level").Value
    local swordLevel = stats:WaitForChild("Sword"):WaitForChild("Level").Value
    local defenseLevel = stats:WaitForChild("Defense"):WaitForChild("Level").Value

    -- Định dạng Combat Stats
    local combatStatsStr = string.format(
        "```🥊 Melee: %s\n🔫 Gun: %s\n🍎 Demon Fruit: %s\n🗡 Sword: %s\n🛡 Defense: %s```",
        FormatNumber(meleeLevel),
        FormatNumber(gunLevel),
        FormatNumber(demonFruitLevel),
        FormatNumber(swordLevel),
        FormatNumber(defenseLevel)
    )

    -- Định dạng dữ liệu gửi đi
    local fields = {
        {
            name = "📊 Player Stats",
            value = "```" ..
                    "🏆 Bounty/Honor: " .. FormatNumber(bountyHonor) .. "\n" ..
                    "💰 Beli: " .. FormatNumber(beli) .. "\n" ..
                    "🔷 Fragments: " .. FormatNumber(fragments) .. "\n" ..
                    "🎚 Level: " .. FormatNumber(level) .. "\n" ..
                    "🧬 Race: " .. tostring(race) .. "\n" ..
                    "🍏 Devil Fruit: " .. tostring(devilFruit) .. 
                    "```",
            inline = false
        },
        {
            name = "⚔️ Combat Stats",
            value = combatStatsStr,
            inline = false
        }
    }

    local message = {
        username = "WebHook",
        embeds = {
            {
                title = "Player Data",
                description = "Thông tin người chơi: " .. player.Name,
                color = 65280,
                fields = fields,
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                footer = { text = "Logged at " .. os.date("%Y-%m-%d %H:%M:%S") }
            }
        }
    }

    return message
end

-- Webhook URL
local webhookUrl = "https://discordapp.com/api/webhooks/1346871146330456104/iWyxqiP7oRv9IeezqJAD5uuyASEkXQc-Y8rTjFVIEokZKyv42IemB-mu4-HIulxFORPm"
local lastData = nil
local webhookEnabled = true
local webhookInterval = 10 -- Mặc định 10 giây

-- Tạo GUI cho Webhook
local success, player = pcall(function()
    return game:GetService("Players").LocalPlayer
end)
if not success then
    warn("Failed to get LocalPlayer: " .. player)
    return
end

local playerGui = player:WaitForChild("PlayerGui", 5)
if not playerGui then
    warn("PlayerGui not found")
    return
end

local screenGui = Instance.new("ScreenGui")
screenGui.Parent = playerGui
screenGui.Name = "WebhookToggleGui"

-- Nút bật/tắt webhook
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 120, 0, 50)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.Text = "Webhook: ON"
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
toggleButton.Parent = screenGui

toggleButton.MouseButton1Click:Connect(function()
    webhookEnabled = not webhookEnabled
    if webhookEnabled then
        toggleButton.Text = "Webhook: ON"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        toggleButton.Text = "Webhook: OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

-- GUI Chỉnh thời gian
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 100)
frame.Position = UDim2.new(0, 10, 0, 70)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Parent = screenGui

local timeLabel = Instance.new("TextLabel")
timeLabel.Size = UDim2.new(1, 0, 0, 20)
timeLabel.Text = "⏳ Interval: " .. webhookInterval .. "s"
timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timeLabel.BackgroundTransparency = 1
timeLabel.Parent = frame

local slider = Instance.new("TextButton")
slider.Size = UDim2.new(1, 0, 0, 40)
slider.Position = UDim2.new(0, 0, 0, 30)
slider.Text = "⬅️ Adjust Interval ➡️"
slider.TextColor3 = Color3.fromRGB(255, 255, 255)
slider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
slider.Parent = frame

slider.MouseButton1Click:Connect(function()
    webhookInterval = webhookInterval + 5
    if webhookInterval > 60 then webhookInterval = 5 end -- Giới hạn từ 5s đến 60s
    timeLabel.Text = "⏳ Interval: " .. webhookInterval .. "s"
end)

-- Vòng lặp gửi webhook
spawn(function()
    while true do
        local message = AdminLoggerMsg()
        if webhookEnabled then
            PostWebhook(webhookUrl, message)
        end
        wait(webhookInterval)
    end
end)
