-- // ==============================================================
-- // HORIZON HUB | MULTI-GAMES LAUNCHER (FLOWAUTH PROTECTED)
-- // ==============================================================

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

-- 1. DAFTAR GAME YANG DIDUKUNG
local SUPPORTED_GAMES = {
    -- [PlaceId] = { Nama Game, Script / Link }
    [133341016381877] = {
        Name = "Mount RNG",
        Script = 'loadstring(game:HttpGet("https://encrypt-x.pages.dev/Scripts?Id=1892450044143"))("1892450044143")',
    },
    [2753915549] = {
        Name = "Blox Fruits",
        Script = "https://raw.githubusercontent.com/acsu123/HOHO_CREATIVE/main/Hub.lua",
    },
    [16732694052] = {
        Name = "Fisch",
        Script = "https://raw.githubusercontent.com/SpeedHubX/SpeedHubX/main/SpeedHubX.lua",
    },
}

-- 2. DETEKSI GAME SAAT INI
local currentGame = SUPPORTED_GAMES[game.PlaceId] or SUPPORTED_GAMES[game.GameId]

if not currentGame then
    local gameNames = {}
    for _, info in pairs(SUPPORTED_GAMES) do
        table.insert(gameNames, "• " .. info.Name)
    end

    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Horizon Hub - Game Not Supported",
            Text = "Game ini belum didukung!\nGame yang didukung:\n" .. table.concat(gameNames, ", "),
            Duration = 7
        })
    end)
    warn("[Horizon Hub] PlaceId (" .. tostring(game.PlaceId) .. ") tidak terdaftar dalam Multi-Games.")
    return
end

-- 3. AUTO-PATCH BUG MOUNT RNG ("Mesh is not a valid member of Part Body")
if game.PlaceId == 133341016381877 or game.GameId == 6466404775 then
    local function ensureMesh(part)
        if part:IsA("BasePart") and part.Name == "Body" and not part:FindFirstChild("Mesh") then
            local m = Instance.new("SpecialMesh")
            m.Name = "Mesh"
            m.Parent = part
        end
    end

    for _, d in ipairs(Workspace:GetDescendants()) do
        pcall(ensureMesh, d)
    end

    Workspace.DescendantAdded:Connect(function(descendant)
        pcall(ensureMesh, descendant)
    end)
end

-- 4. LOAD NOTIFIKASI WIND UI
pcall(function()
    local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    WindUI:Notify({
        Title = "Horizon Hub",
        Content = "Akses Valid! Memuat script " .. currentGame.Name .. "...",
        Duration = 4,
        Icon = "solar:check-circle-bold",
    })
end)

-- 5. JALANKAN SCRIPT GAME TARGET
print("[Horizon Hub] Menjalankan script game: " .. currentGame.Name)
task.spawn(function()
    local ok, err = pcall(function()
        if type(currentGame.Script) == "function" then
            currentGame.Script()
        elseif type(currentGame.Script) == "string" then
            if currentGame.Script:match("^https?://") and not currentGame.Script:find("loadstring") then
                loadstring(game:HttpGet(currentGame.Script))()
            else
                loadstring(currentGame.Script)()
            end
        end
    end)
    if not ok then
        warn("[Horizon Hub Error]: " .. tostring(err))
    end
end)