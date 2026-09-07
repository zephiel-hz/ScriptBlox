-- // ==============================================================
-- // HORIZON HUB | MULTI-GAMES LOADER + WIND UI KEY SYSTEM
-- // ==============================================================

-- 1. DAFTAR GAME YANG DIDUKUNG
-- (Kamu bisa menambah game lain sesuka hati di dalam tabel ini)
local SUPPORTED_GAMES = {
    -- [PlaceId] = { Nama Game, Link Script }
    [133341016381877] = {
        Name = "Mount RNG",
        Script = "loadstring(game:HttpGet("https://encrypt-x.pages.dev/Scripts?Id=1892450044143"))("1892450044143")",
    },
    
    -- Contoh menambah game lain:
    -- [2753915549] = {
    --     Name = "Blox Fruits",
    --     Script = "https://raw.githubusercontent.com/.../BloxFruits.lua",
    -- },
    -- [16732694052] = {
    --     Name = "Fisch",
    --     Script = "https://raw.githubusercontent.com/.../Fisch.lua",
    -- },
}

-- 2. DETEKSI GAME SAAT INI
local currentGame = SUPPORTED_GAMES[game.PlaceId] or SUPPORTED_GAMES[game.GameId]

if not currentGame then
    -- Kumpulkan daftar game yang didukung untuk notifikasi
    local gameNames = {}
    for _, info in pairs(SUPPORTED_GAMES) do
        table.insert(gameNames, "• " .. info.Name)
    end

    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Horizon Hub - Game Not Supported",
            Text = "Game ini belum didukung!\nGame yang didukung:\n" .. table.concat(gameNames, ", "),
            Duration = 7
        })
    end)
    warn("[Horizon Hub] PlaceId (" .. tostring(game.PlaceId) .. ") tidak terdaftar dalam Multi-Games.")
    return
end

-- 3. KONFIGURASI KEY SYSTEM & REWARD
local FLOWAUTH_LOADER_URL = "https://flowauth.net/v1/loaders/4a3a799b84b7f927699ee033c487ca36.lua"
local REWARD_URL = "https://flowauth.net/reward/4a3a799b84b7f927699ee033c487ca36" -- Ganti dengan link Flow Reward kamu
local KEY_FILE = "HorizonHub_Key.txt"

-- Fungsi untuk menjalankan script game target
local function launchTargetGameScript()
    print("[Horizon Hub] Menjalankan script untuk game: " .. currentGame.Name)
    local ok, err = pcall(function()
        loadstring(game:HttpGet(currentGame.Script))()
    end)
    if not ok then
        warn("[Horizon Hub Error]: " .. tostring(err))
    end
end

-- Fungsi verifikasi key ke server FlowAuth
local function verifyKeyWithFlowAuth(key)
    local success, result = pcall(function()
        local loader = loadstring(game:HttpGet(FLOWAUTH_LOADER_URL))
        return loader(key) -- Mengirim key ke runtime FlowAuth
    end)
    return success, result
end

-- 4. CEK APAKAH KEY SUDAH TERSIMPAN & MASIH VALID
if isfile and readfile and isfile(KEY_FILE) then
    local savedKey = readfile(KEY_FILE)
    if savedKey and savedKey:gsub("%s+", "") ~= "" then
        local ok, _ = verifyKeyWithFlowAuth(savedKey)
        if ok then
            print("[Horizon Hub] Key tersimpan valid! Menjalankan " .. currentGame.Name)
            launchTargetGameScript()
            return
        else
            -- Hapus file jika key sudah expired/invalid
            if delfile then pcall(delfile, KEY_FILE) end
        end
    end
end

-- 5. LOAD WIND UI LIBRARY
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- 6. BUAT WINDOW KEY SYSTEM (MULTI-GAMES)
local KeyWindow = WindUI:CreateWindow({
    Title = "Horizon Hub  |  " .. currentGame.Name,
    Folder = "HorizonHub",
    Icon = "solar:gamepad-bold",
    NewElements = true,
    HideSearchBar = true,
    OpenButton = { Enabled = false },
    Size = UDim2.fromOffset(480, 360),
})

-- TAB 1: VERIFIKASI KEY
local KeyTab = KeyWindow:Tab({
    Title = "Authentication",
    Icon = "solar:shield-keyhole-bold",
})

KeyTab:Section({
    Title = "Game Terdeteksi: " .. currentGame.Name,
    TextSize = 15,
})

local enteredKey = ""

-- Input Textbox
KeyTab:Input({
    Title = "Enter Access Key",
    Placeholder = "Tempel key kamu di sini...",
    Callback = function(val)
        enteredKey = val:gsub("%s+", "") -- Hapus spasi tidak sengaja
    end,
})

-- Tombol Verifikasi Key
KeyTab:Button({
    Title = "Verify Key",
    Desc = "Validasi key dan buka script " .. currentGame.Name,
    Callback = function()
        if enteredKey == "" then
            WindUI:Notify({
                Title = "Peringatan",
                Content = "Mohon masukkan key terlebih dahulu!",
                Duration = 4,
            })
            return
        end

        WindUI:Notify({
            Title = "Memeriksa Key...",
            Content = "Sedang menghubungkan ke server FlowAuth...",
            Duration = 2,
        })

        task.spawn(function()
            local success, err = verifyKeyWithFlowAuth(enteredKey)
            if success then
                -- Simpan key jika valid
                if writefile then
                    pcall(writefile, KEY_FILE, enteredKey)
                end

                WindUI:Notify({
                    Title = "Akses Diterima!",
                    Content = "Key Valid! Memuat " .. currentGame.Name .. "...",
                    Duration = 3,
                })

                task.wait(1)
                pcall(function() KeyWindow:Destroy() end)
                
                -- Jalankan script game yang sesuai
                launchTargetGameScript()
            else
                WindUI:Notify({
                    Title = "Gagal Verifikasi",
                    Content = "Key salah atau sudah kedaluwarsa!",
                    Duration = 4,
                })
            end
        end)
    end,
})

-- Tombol Ambil Key
KeyTab:Button({
    Title = "Get Key (Copy Link)",
    Desc = "Salin link FlowAuth Reward untuk mendapatkan key gratis",
    Callback = function()
        if setclipboard then
            setclipboard(REWARD_URL)
            WindUI:Notify({
                Title = "Link Berhasil Disalin!",
                Content = "Buka browser kamu dan selesaikan untuk mendapatkan key.",
                Duration = 5,
            })
        else
            WindUI:Notify({
                Title = "Info",
                Content = "Silakan buka: " .. REWARD_URL,
                Duration = 6,
            })
        end
    end,
})

-- TAB 2: DAFTAR GAME YANG DIDUKUNG
local SupportedTab = KeyWindow:Tab({
    Title = "Supported Games",
    Icon = "solar:folder-with-files-bold",
})

for id, info in pairs(SUPPORTED_GAMES) do
    local isCurrent = (id == game.PlaceId or id == game.GameId)
    SupportedTab:Section({
        Title = info.Name .. (isCurrent and "  [SEDANG DIMAINKAN]" or ""),
        TextSize = 13,
    })
end