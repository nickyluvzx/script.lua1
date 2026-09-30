local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local v1 = nil
pcall(function()
    v1 = game:GetService("VirtualInputManager")
end)

local v2 = {
    API = "http://38.92.41.52:3000",
    TOKEN = "73fa12c47459fed3724e505c",
    WORKER = "ravenactxx",
    INTERVALO = 4,
    v3 = 45,
    v4 = 90,
    v5 = 5,
    v6 = 0.12,
    v7 = 1.25,
    v8 = 0.015,
    v10 = 1.6,
    v11 = 10
}

print("[KyanStore] INICIO")

local v12 = nil

while Players.LocalPlayer == nil do
    task.wait(1)
end

v12 = Players.LocalPlayer

print("[KyanStore] LocalPlayer: " .. tostring(v12.Name))

local PlayerGui = v12:WaitForChild("PlayerGui")

local v13 = false
local v14 = {}

-- DEBUG
local DEBUG_LINES = {}

local function DEBUG(msg)
    msg = tostring(msg)
    local linha = os.date("%H:%M:%S") .. " | " .. msg
    print("[KYAN DEBUG] " .. linha)
    table.insert(DEBUG_LINES, linha)
    if #DEBUG_LINES > 15 then
        table.remove(DEBUG_LINES, 1)
    end
    if v14.DebugText then
        v14.DebugText.Text = table.concat(DEBUG_LINES, "\n")
    end
end

-- ASSETS
local function v15(v16)
    local v17 = getcustomasset or getsynasset
    local v18 = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
    if not v17 or not v18 or not writefile then
        return nil
    end

    local v19 = "KyanStoreAssets"
    local v20 = v19 .. "/" .. v16

    pcall(function()
        if makefolder and (not isfolder or not isfolder(v19)) then
            makefolder(v19)
        end
    end)

    local v21 = false

    if isfile then
        pcall(function()
            v21 = isfile(v20)
        end)
    end

    if not v21 then
        local v22, v23 = pcall(function()
            return v18({
                Url = v2.API .. "/assets/" .. v16,
                Method = "GET"
            })
        end)

        if v22 and v23 then
            local v24 = tonumber(v23.StatusCode or v23.Status or 0)

            if v24 >= 200 and v24 < 300 and v23.Body and #v23.Body > 0 then
                pcall(function()
                    writefile(v20, v23.Body)
                end)
            end
        end
    end

    local v25 = true

    if isfile then
        pcall(function()
            v25 = isfile(v20)
        end)
    end

    if not v25 then
        return nil
    end

    local v22, v26 = pcall(function()
        return v17(v20)
    end)

    return v22 and v26 or nil
end

-- UI HELPERS
local function v27(v28, v29)
    local v30 = Instance.new("UICorner")
    v30.CornerRadius = UDim.new(0, v29 or 10)
    v30.Parent = v28
    return v30
end

local function v31(v28, v32, v33, v34)
    local v35 = Instance.new("UIStroke")
    v35.Color = v32 or Color3.fromRGB(210, 20, 45)
    v35.Thickness = v33 or 1
    v35.Transparency = v34 or 0
    v35.Parent = v28
    return v35
end

local function v36(v28, v37, v38, v39, v40, v41)
    local v42 = Instance.new("TextLabel")
    v42.BackgroundTransparency = 1
    v42.Size = v38
    v42.Position = v39
    v42.Text = v37 or ""
    v42.TextColor3 = Color3.fromRGB(240, 236, 240)
    v42.Font = v41 and Enum.Font.GothamBold or Enum.Font.Gotham
    v42.TextSize = v40 or 14
    v42.TextXAlignment = Enum.TextXAlignment.Left
    v42.TextYAlignment = Enum.TextYAlignment.Center
    v42.Parent = v28
    return v42
end

-- UI PRINCIPAL
do
    local okUI, errUI = pcall(function()
        local antigo = PlayerGui:FindFirstChild("KyanStoreDeliveryStatus")

        if antigo then
            antigo:Destroy()
        end

        local v43 = Instance.new("ScreenGui")
        v43.Name = "KyanStoreDeliveryStatus"
        v43.ResetOnSpawn = false
        v43.IgnoreGuiInset = true
        v43.DisplayOrder = 999
        v43.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        v43.Parent = PlayerGui

        local v44 = Instance.new("Frame")
        v44.Name = "Panel"
        v44.AnchorPoint = Vector2.new(0.5, 0.5)
        v44.Size = UDim2.fromOffset(760, 500)
        v44.Position = UDim2.fromScale(0.5, 0.5)
        v44.BackgroundColor3 = Color3.fromRGB(12, 8, 11)
        v44.BorderSizePixel = 0
        v44.Parent = v43

        v27(v44, 16)
        v31(v44, Color3.fromRGB(215, 15, 42), 2, 0.08)

        local v45 = Instance.new("UIGradient")

        v45.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(29, 8, 14)),
            ColorSequenceKeypoint.new(0.55, Color3.fromRGB(12, 8, 11)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 5, 10))
        })

        v45.Rotation = 90
        v45.Parent = v44

        local v46 = Instance.new("UIScale")
        v46.Scale = 1
        v46.Parent = v44

        local function v47()
            local camera = workspace.CurrentCamera

            if not camera then
                return
            end

            local V = camera.ViewportSize

            v46.Scale = math.clamp(
                math.min(
                    (V.X - 28) / 760,
                    (V.Y - 28) / 500
                ),
                0.50,
                1
            )
        end

        v47()

        if workspace.CurrentCamera then
            workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(v47)
        end

        local v49 = Instance.new("ImageButton")
        v49.Name = "Toggle"
        v49.AnchorPoint = Vector2.new(1, 0)
        v49.Size = UDim2.fromOffset(62, 62)
        v49.Position = UDim2.new(1, -18, 0, 18)
        v49.BackgroundColor3 = Color3.fromRGB(17, 9, 13)
        v49.AutoButtonColor = true
        v49.Image = v15("toggle_icon.png") or ""
        v49.ScaleType = Enum.ScaleType.Crop
        v49.ZIndex = 30
        v49.Parent = v43

        v27(v49, 12)
        v31(v49, Color3.fromRGB(230, 25, 50), 2, 0)

        if v49.Image == "" then
            local v50 = v36(
                v49,
                "KS",
                UDim2.fromScale(1, 1),
                UDim2.fromScale(0, 0),
                18,
                true
            )

            v50.TextXAlignment = Enum.TextXAlignment.Center
            v50.TextColor3 = Color3.fromRGB(255, 45, 70)
            v50.ZIndex = 31
        end

        v49.MouseButton1Click:Connect(function()
            v44.Visible = not v44.Visible
        end)

        local v51 = Instance.new("ImageLabel")
        v51.Name = "AnimatedDrip"
        v51.Size = UDim2.new(1, 0, 0, 34)
        v51.Position = UDim2.fromOffset(0, 0)
        v51.BackgroundTransparency = 1
        v51.ScaleType = Enum.ScaleType.Stretch
        v51.ZIndex = 8
        v51.Parent = v44

        local v52 = v15("drip_red_spritesheet.png")

        if v52 then
            v51.Image = v52
            v51.ImageRectSize = Vector2.new(532, 24)
            v51.ImageRectOffset = Vector2.new(0, 0)

            task.spawn(function()
                local v53 = 0

                while v43.Parent do
                    v51.ImageRectOffset = Vector2.new(532 * v53, 0)
                    v53 = (v53 + 1) % 5
                    task.wait(0.10)
                end
            end)
        else
            v51.Image = ""
            v51.BackgroundTransparency = 0
            v51.BackgroundColor3 = Color3.fromRGB(190, 8, 28)
        end

        local v54 = Instance.new("Frame")
        v54.Size = UDim2.new(1, -32, 0, 142)
        v54.Position = UDim2.fromOffset(16, 24)
        v54.BackgroundColor3 = Color3.fromRGB(22, 9, 13)
        v54.BorderSizePixel = 0
        v54.Parent = v44

        v27(v54, 12)
        v31(v54, Color3.fromRGB(145, 15, 33), 1, 0.25)

        local v55 = Instance.new("ImageLabel")
        v55.Size = UDim2.fromScale(1, 1)
        v55.BackgroundTransparency = 1
        v55.Image = v15("banner.png") or ""
        v55.ScaleType = Enum.ScaleType.Crop
        v55.Parent = v54

        v27(v55, 12)

        if v55.Image == "" then
            local v50 = v36(
                v54,
                "KYAN STORE",
                UDim2.fromScale(1, 1),
                UDim2.fromScale(0, 0),
                38,
                true
            )

            v50.TextXAlignment = Enum.TextXAlignment.Center
            v50.TextColor3 = Color3.fromRGB(230, 20, 48)
        end

        local v56 = Instance.new("Frame")
        v56.Size = UDim2.fromOffset(246, 250)
        v56.Position = UDim2.fromOffset(16, 178)
        v56.BackgroundColor3 = Color3.fromRGB(24, 14, 18)
        v56.BackgroundTransparency = 0.12
        v56.BorderSizePixel = 0
        v56.Parent = v44

        v27(v56, 12)
        v31(v56, Color3.fromRGB(115, 20, 35), 1, 0.25)

        local v57 = v36(
            v56,
            "ENTREGA",
            UDim2.new(1, -24, 0, 32),
            UDim2.fromOffset(12, 10),
            18,
            true
        )

        v57.TextColor3 = Color3.fromRGB(255, 232, 236)

        local v58 = v36(
            v56,
            "entrega automática pela kyan store",
            UDim2.new(1, -24, 0, 26),
            UDim2.fromOffset(12, 40),
            12,
            false
        )

        v58.TextColor3 = Color3.fromRGB(170, 150, 156)

        local v59 = v36(
            v56,
            "nick do cliente",
            UDim2.new(1, -24, 0, 24),
            UDim2.fromOffset(12, 88),
            13,
            true
        )

        v59.TextColor3 = Color3.fromRGB(220, 205, 210)

        local v60 = Instance.new("Frame")
        v60.Size = UDim2.new(1, -24, 0, 50)
        v60.Position = UDim2.fromOffset(12, 116)
        v60.BackgroundColor3 = Color3.fromRGB(14, 11, 14)
        v60.BorderSizePixel = 0
        v60.Parent = v56

        v27(v60, 9)
        v31(v60, Color3.fromRGB(190, 15, 40), 1, 0.15)

        local v61 = v36(
            v60,
            "-",
            UDim2.new(1, -20, 1, 0),
            UDim2.fromOffset(10, 0),
            17,
            true
        )

        v61.TextColor3 = Color3.fromRGB(247, 240, 242)

        local v62 = v36(
            v56,
            "status atual",
            UDim2.new(1, -24, 0, 22),
            UDim2.fromOffset(12, 184),
            12,
            true
        )

        v62.TextColor3 = Color3.fromRGB(175, 150, 158)

        local v24 = v36(
            v56,
            "aguardando pedidos",
            UDim2.new(1, -24, 0, 30),
            UDim2.fromOffset(12, 208),
            14,
            true
        )

        v24.TextColor3 = Color3.fromRGB(255, 43, 67)

        local v63 = Instance.new("Frame")
        v63.Size = UDim2.new(1, -294, 0, 250)
        v63.Position = UDim2.fromOffset(278, 178)
        v63.BackgroundColor3 = Color3.fromRGB(24, 14, 18)
        v63.BackgroundTransparency = 0.12
        v63.BorderSizePixel = 0
        v63.Parent = v44

        v27(v63, 12)
        v31(v63, Color3.fromRGB(115, 20, 35), 1, 0.25)

        local v64 = v36(
            v63,
            "ITENS DA ENTREGA",
            UDim2.new(1, -24, 0, 30),
            UDim2.fromOffset(12, 10),
            17,
            true
        )

        v64.TextColor3 = Color3.fromRGB(255, 232, 236)

        local Rolagem = Instance.new("ScrollingFrame")
        Rolagem.Size = UDim2.new(1, -24, 0, 116)
        Rolagem.Position = UDim2.fromOffset(12, 44)
        Rolagem.BackgroundColor3 = Color3.fromRGB(13, 10, 13)
        Rolagem.BorderSizePixel = 0
        Rolagem.ScrollBarThickness = 4
        Rolagem.ScrollBarImageColor3 = Color3.fromRGB(205, 20, 45)
        Rolagem.CanvasSize = UDim2.new(0, 0, 0, 0)
        Rolagem.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Rolagem.Parent = v63

        v27(Rolagem, 9)
        v31(Rolagem, Color3.fromRGB(100, 22, 34), 1, 0.35)

        local v65 = v36(
            Rolagem,
            "-",
            UDim2.new(1, -16, 0, 0),
            UDim2.fromOffset(8, 8),
            13,
            false
        )

        v65.AutomaticSize = Enum.AutomaticSize.Y
        v65.TextColor3 = Color3.fromRGB(232, 220, 224)
        v65.Font = Enum.Font.Code
        v65.TextWrapped = true
        v65.TextYAlignment = Enum.TextYAlignment.Top

        local v66 = v36(
            v63,
            "STATUS DA ENTREGA",
            UDim2.new(1, -24, 0, 24),
            UDim2.fromOffset(12, 168),
            14,
            true
        )

        v66.TextColor3 = Color3.fromRGB(225, 212, 216)

        local v67 = {}

        local v68 = {
            "aguardando\npedidos",
            "entrega\npendente",
            "entregando\nmarretas",
            "marretas\nentregues"
        }

        for i = 1, 4 do
            local X = 12 + ((i - 1) * 105)

            local v69 = v36(
                v63,
                "●",
                UDim2.fromOffset(22, 22),
                UDim2.fromOffset(X, 196),
                20,
                true
            )

            v69.TextXAlignment = Enum.TextXAlignment.Center

            local v70 = v36(
                v63,
                v68[i],
                UDim2.fromOffset(88, 36),
                UDim2.fromOffset(X + 24, 188),
                10,
                true
            )

            v70.TextWrapped = true
            v70.TextColor3 = Color3.fromRGB(135, 125, 130)

            v67[i] = {
                v69 = v69,
                v70 = v70
            }
        end

        local v71 = Instance.new("Frame")
        v71.Size = UDim2.new(1, -32, 0, 42)
        v71.Position = UDim2.fromOffset(16, 442)
        v71.BackgroundColor3 = Color3.fromRGB(160, 8, 31)
        v71.BorderSizePixel = 0
        v71.Parent = v44

        v27(v71, 10)
        v31(v71, Color3.fromRGB(245, 30, 60), 1, 0.05)

        local v72 = v36(
            v71,
            "worker automático ativo • aguardando pedidos da api",
            UDim2.new(1, -20, 1, 0),
            UDim2.fromOffset(10, 0),
            13,
            true
        )

        v72.TextXAlignment = Enum.TextXAlignment.Center
        v72.TextColor3 = Color3.fromRGB(255, 244, 246)

        -- A continuação começa no DebugFrame.
        local DebugFrame = Instance.new("Frame")
        DebugFrame.Name = "DebugFrame"
        DebugFrame.Size = UDim2.fromOffset(720, 250)
        DebugFrame.Position = UDim2.fromOffset(20, 180)
        DebugFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
        DebugFrame.BorderSizePixel = 0
        DebugFrame.Visible = false
        DebugFrame.ZIndex = 100
        DebugFrame.Parent = v44

        v27(DebugFrame, 10)
        v31(DebugFrame, Color3.fromRGB(255, 35, 60), 2, 0)

        local DebugTitle = Instance.new("TextLabel")
        DebugTitle.Size = UDim2.new(1, -20, 0, 30)
        DebugTitle.Position = UDim2.fromOffset(10, 5)
        DebugTitle.BackgroundTransparency = 1
        DebugTitle.Text = "KYAN STORE • DEBUG"
        DebugTitle.TextColor3 = Color3.fromRGB(255, 45, 70)
        DebugTitle.TextSize = 16
        DebugTitle.Font = Enum.Font.GothamBold
        DebugTitle.TextXAlignment = Enum.TextXAlignment.Left
        DebugTitle.ZIndex = 101
        DebugTitle.Parent = DebugFrame

        local DebugText = Instance.new("TextLabel")
        DebugText.Name = "DebugText"
        DebugText.Size = UDim2.new(1, -20, 1, -40)
        DebugText.Position = UDim2.fromOffset(10, 38)
        DebugText.BackgroundTransparency = 1
        DebugText.Text = "Aguardando..."
        DebugText.TextColor3 = Color3.fromRGB(230, 230, 230)
        DebugText.TextSize = 12
        DebugText.Font = Enum.Font.Code
        DebugText.TextXAlignment = Enum.TextXAlignment.Left
        DebugText.TextYAlignment = Enum.TextYAlignment.Top
        DebugText.TextWrapped = false
        DebugText.ZIndex = 101
        DebugText.Parent = DebugFrame

        local DebugButton = Instance.new("TextButton")
        DebugButton.Size = UDim2.fromOffset(100, 30)
        DebugButton.Position = UDim2.new(1, -110, 0, 5)
        DebugButton.BackgroundColor3 = Color3.fromRGB(120, 10, 25)
        DebugButton.Text = "DEBUG"
        DebugButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        DebugButton.TextSize = 13
        DebugButton.Font = Enum.Font.GothamBold
        DebugButton.ZIndex = 102
        DebugButton.Parent = v44

        v27(DebugButton, 7)

        DebugButton.MouseButton1Click:Connect(function()
            DebugFrame.Visible = not DebugFrame.Visible
        end)

        v14.v43 = v43
        v14.v44 = v44
        v14.v24 = v24
        v14.v61 = v61
        v14.v65 = v65
        v14.v67 = v67
        v14.v72 = v72
        v14.DebugText = DebugText
    end)

    if not okUI then
        warn("[KyanStore] erro UI: " .. tostring(errUI))
    else
        print("[KyanStore] UI criada")
    end
end

DEBUG("Script carregado")
DEBUG("Jogador: " .. tostring(v12.Name))
DEBUG("PlaceId: " .. tostring(game.PlaceId))

-- STATUS
local function v73(v74)
    local v37 = tostring(v74 or "-")

    if v14.v24 then
        v14.v24.Text = v37
    end

    DEBUG("STATUS => " .. v37)

    local v75 = {
        ["aguardando pedidos"] = 1,
        ["entrega pendente"] = 2,
        ["entregando marretas"] = 3,
        ["marretas entregues"] = 4
    }

    local v76 = v75[v37]

    for i, v77 in ipairs(v14.v67 or {}) do
        local v78 = v76 and i <= v76
        local v79 = v76 and i == v76

        v77.v69.TextColor3 =
            v78
            and Color3.fromRGB(255, 35, 62)
            or Color3.fromRGB(92, 83, 88)

        v77.v70.TextColor3 =
            v79
            and Color3.fromRGB(255, 45, 70)
            or (
                v78
                and Color3.fromRGB(215, 185, 192)
                or Color3.fromRGB(125, 114, 120)
            )
    end
end

local function v80(v81)
    if not v81 then
        if v14.v61 then
            v14.v61.Text = "-"
        end

        if v14.v65 then
            v14.v65.Text = "-"
        end

        return
    end

    if v14.v61 then
        v14.v61.Text = tostring(v81.nick or "-")
    end

    local v82 = {}

    for _, v83 in ipairs(v81.items or {}) do
        local v84 = tonumber(v83.quantity or 0) or 0

        if v84 > 0 then
            table.insert(
                v82,
                string.format(
                    "%dx  %s  [%s]",
                    v84,
                    tostring(v83.name or "item"),
                    tostring(v83.ftfId or "sem id")
                )
            )
        end
    end

    if v14.v65 then
        v14.v65.Text =
            #v82 > 0
            and table.concat(v82, "\n")
            or "-"
    end
end

-- HTTP
local function HTTP(v85, v20, v86)
    DEBUG("HTTP " .. tostring(v85) .. " " .. tostring(v20))

    local v87 =
        request
        or http_request
        or (syn and syn.request)
        or (fluxus and fluxus.request)

    if not v87 then
        DEBUG("ERRO: executor não possui request")
        error("executor sem função request/http_request")
    end

    local ok, v23 = pcall(function()
        return v87({
            Url = v2.API .. v20,
            Method = v85,
            Headers = {
                ["Authorization"] = "Bearer " .. v2.TOKEN,
                ["Content-Type"] = "application/json"
            },
            Body = v86 and HttpService:JSONEncode(v86) or nil
        })
    end)

    if not ok then
        DEBUG("ERRO HTTP: " .. tostring(v23))
        error(v23)
    end

    local v24 =
        tonumber(v23.StatusCode or v23.Status or 0)

    DEBUG("HTTP STATUS => " .. tostring(v24))

    local v88 = nil

    if v23.Body and #v23.Body > 0 then
        local v22, v89 = pcall(function()
            return HttpService:JSONDecode(v23.Body)
        end)

        if v22 then
            v88 = v89
            DEBUG("HTTP possui JSON")
        else
            v88 = {raw = v23.Body}
            DEBUG("HTTP retornou texto não-JSON")
        end
    else
        DEBUG("HTTP sem Body")
    end

    return v88, v24
end

-- FUNÇÕES ORIGINAIS
local ReplicatedStorage2 = game:GetService("ReplicatedStorage")

local function ITEM_DATABASE()
    local v14x =
        ReplicatedStorage2:FindFirstChild("ReplicatedStorage")

    if v14x and v14x:FindFirstChild("ItemDatabase") then
        return v14x.ItemDatabase
    end

    return ReplicatedStorage2:FindFirstChild("ItemDatabase")
end

local function ITEM_GRID()
    local pg = v12:FindFirstChild("PlayerGui")

    if not pg then
        return nil
    end

    local menus =
        pg:FindFirstChild("MenusScreenGui")

    if not menus then
        return nil
    end

    local janela =
        menus:FindFirstChild("InventoryMenuWindow")
        or menus:FindFirstChild("_InventoryMenuWindow")

    if not janela then
        return nil
    end

    local body =
        janela:FindFirstChild("Body")

    if not body then
        return nil
    end

    return body:FindFirstChild("ItemGridFrame")
end

local function QUANTIDADE(card)
    local top =
        card:FindFirstChild("TopLabel")

    if not top or not top:IsA("TextLabel") then
        return 1
    end

    local texto =
        tostring(top.Text or "")

    local n =
        texto:match("[xX]%s*(%d+)")
        or texto:match("(%d+)%s*[xX]")

    return tonumber(n) or 1
end

local function EVENTO(id)
    local codigo =
        tostring(id):match("^[HG]([A-Za-z]+)%d+")

    if not codigo then
        return "default"
    end

    codigo = string.lower(codigo)

    local mapa = {
        ani = "anniversary",
        val = "valentines",
        hal = "halloween",
        mas = "christmas",
        lny = "lunar_new_year",
        spr = "spring",
        sum = "summer",
        aut = "autumn",
        pat = "st_patricks",
        eas = "easter",
        lbc = "merch",
        vip = "vip"
    }

    return mapa[codigo] or codigo
end

local function CLICAR_BOTAO(btn)
    if not btn or not btn:IsA("GuiButton") then
        DEBUG("CLIQUE: botão inválido")
        return false
    end

    DEBUG("CLIQUE: " .. tostring(btn.Name))

    local ok, vim =
        pcall(function()
            return game:GetService("VirtualInputManager")
        end)

    if ok and vim and btn.AbsolutePosition then
        local pos = btn.AbsolutePosition
        local size = btn.AbsoluteSize

        local X =
            math.floor(pos.X + size.X / 2)

        local Y =
            math.floor(pos.Y + size.Y / 2)

        local clicou =
            pcall(function()
                vim:SendMouseButtonEvent(
                    X,
                    Y,
                    0,
                    true,
                    game,
                    0
                )

                task.wait(0.05)

                vim:SendMouseButtonEvent(
                    X,
                    Y,
                    0,
                    false,
                    game,
                    0
                )
            end)

        if clicou then
            DEBUG("CLIQUE OK")
            return true
        end
    end

    if firesignal then
        local okSignal =
            pcall(function()
                firesignal(btn.MouseButton1Click)
            end)

        if okSignal then
            DEBUG("FIRESIGNAL OK")
            return true
        end
    end

    DEBUG("CLIQUE FALHOU")
    return false
end

local function ACHAR_BOTAO_INVENTARIO()
    local achados = {}

    local pg =
        v12:FindFirstChild("PlayerGui")

    if not pg then
        return nil
    end

    local function varrer(p)
        for _, c in ipairs(p:GetChildren()) do
            if c:IsA("GuiButton") then
                local nome =
                    string.lower(tostring(c.Name))

                if string.find(nome, "nvent")
                    or string.find(nome, "ackpack")
                    or string.find(nome, "ochila") then
                    table.insert(
                        achados,
                        c
                    )
                end
            end

            if c:IsA("Frame")
                or c:IsA("ScrollingFrame")
                or c:IsA("ScreenGui")
                or c:IsA("TextLabel")
                or c:IsA("ImageLabel")
                or c:IsA("TextButton")
                or c:IsA("ImageButton") then
                varrer(c)
            end
        end
    end

    varrer(pg)

    if #achados > 0 then
        table.sort(
            achados,
            function(a, b)
                return
                    (a.AbsoluteSize.X * a.AbsoluteSize.Y)
                    >
                    (b.AbsoluteSize.X * b.AbsoluteSize.Y)
            end
        )

        return achados[1]
    end

    return nil
end

local function ABRIR_INVENTARIO()
    DEBUG("Abrindo inventário...")

    local grid = ITEM_GRID()

    if grid then
        for _, c in ipairs(grid:GetChildren()) do
            if c:IsA("ImageButton") then
                DEBUG("Inventário já estava aberto")
                return true
            end
        end
    end

    local botao =
        ACHAR_BOTAO_INVENTARIO()

    if botao then
        DEBUG(
            "Botão inventário encontrado: "
            .. tostring(botao.Name)
        )

        CLICAR_BOTAO(botao)

        task.wait(1.2)

        grid = ITEM_GRID()

        if grid then
            for _, c in ipairs(grid:GetChildren()) do
                if c:IsA("ImageButton") then
                    DEBUG("Inventário aberto")
                    return true
                end
            end
        end
    else
        DEBUG("Botão de inventário não encontrado")
    end

    return false
end

local function ESCONDER_INVENTARIO()
    pcall(function()
        local pg =
            v12:FindFirstChild("PlayerGui")

        if not pg then
            return
        end

        for _, sg in ipairs(pg:GetChildren()) do
            if sg:IsA("ScreenGui") then
                for _, j in ipairs(sg:GetChildren()) do
                    local nm =
                        tostring(j.Name)

                    if (
                        string.find(nm, "InventoryMenuWindow")
                        or string.find(nm, "_InventoryMenuWindow")
                    )
                    and j:IsA("Frame") then
                        j.Visible = false
                    end
                end
            end
        end
    end)
end

local function COLETAR_INVENTARIO()
    DEBUG("Coletando inventário...")

    if not v13 then
        pcall(ABRIR_INVENTARIO)
    end

    local grid =
        ITEM_GRID()

    if not grid then
        if not v13 then
            pcall(ABRIR_INVENTARIO)
            task.wait(0.8)

            grid =
                ITEM_GRID()
        end
    end

    if not grid then
        pcall(ESCONDER_INVENTARIO)

        DEBUG("Inventário não disponível")

        return nil, "inventario nao disponivel"
    end

    local db =
        ITEM_DATABASE()

    local itens = {}
    local vistos = {}

    for _, card in ipairs(grid:GetChildren()) do
        if card:IsA("ImageButton") then
            local id =
                tostring(
                    card:GetAttribute("itemId")
                    or ""
                )

            if id:match("^H[A-Za-z0-9_-]+$")
                and id ~= "H0000"
                and id ~= "H0001" then

                local quantidade =
                    QUANTIDADE(card)

                local nome = nil

                local raridade =
                    card:GetAttribute("Rarity")

                local thumbnail = nil

                if db then
                    local item =
                        db:FindFirstChild(id)

                    if item then
                        nome =
                            item:GetAttribute("ItemName")

                        raridade =
                            item:GetAttribute("Rarity")
                            or raridade

                        thumbnail =
                            item:GetAttribute("Thumbnail")
                    end
                end

                if not nome then
                    local bottom =
                        card:FindFirstChild("BottomLabel")

                    if bottom and bottom:IsA("TextLabel") then
                        nome = bottom.Text
                    end
                end

                if not vistos[id] then
                    vistos[id] = true

                    table.insert(
                        itens,
                        {
                            id = id,
                            quantity = quantidade,
                            name = nome or id,
                            rarity = tonumber(raridade),
                            thumbnail = thumbnail,
                            event = EVENTO(id)
                        }
                    )
                end
            end
        end
    end

    pcall(ESCONDER_INVENTARIO)

    DEBUG(
        "Inventário coletado: "
        .. tostring(#itens)
        .. " tipos"
    )

    return itens
end

-- SINCRONIZAÇÃO
local function SINCRONIZAR()
    DEBUG("Iniciando sincronização")

    local inventario, erro =
        COLETAR_INVENTARIO()

    if not inventario then
        DEBUG("Erro inventário: " .. tostring(erro))
        return false
    end

    if #inventario == 0 then
        DEBUG("Inventário vazio")
        return false
    end

    DEBUG(
        "Enviando "
        .. tostring(#inventario)
        .. " itens para API"
    )

    local resposta, status =
        HTTP(
            "POST",
            "/api/inventory/sync",
            {
                worker = v2.WORKER,
                account = v12.Name,
                items = inventario
            }
        )

    if status >= 200 and status < 300 then
        DEBUG(
            "Estoque sincronizado: "
            .. tostring(
                resposta
                and resposta.totalItems
                or 0
            )
        )

        return true
    end

    DEBUG(
        "Falha sincronização HTTP "
        .. tostring(status)
    )

    return false
end

local function FOI_SOLICITADO()
    local resposta, status =
        HTTP(
            "GET",
            "/api/inventory/request?worker="
            .. HttpService:UrlEncode(v2.WORKER)
        )

    if status ~= 200 or not resposta then
        return false
    end

    return resposta.requested == true
end

-- HELPERS
local function v90(v91, v92, v93)
    local v94 = os.clock()

    repeat
        local v22, v89 =
            pcall(v92)

        if v22 and v89 then
            return v89
        end

        task.wait(v93 or 0.08)
    until os.clock() - v94 >= v91

    return nil
end

local function v95(v96)
    local v97 =
        string.lower(
            tostring(v96 or "")
        )

    for _, v98 in ipairs(Players:GetPlayers()) do
        if string.lower(v98.Name) == v97 then
            return v98
        end
    end

    return nil
end

local function v99(v28, ...)
    local v76 = v28

    for _, v16 in ipairs({...}) do
        if not v76 then
            return nil
        end

        v76 =
            v76:FindFirstChild(v16)
    end

    return v76
end

local function v100()
    return PlayerGui:FindFirstChild("MenusScreenGui")
end

local function v101()
    return PlayerGui:FindFirstChild("ScreenGui")
end

local function v102(v103)
    if not v103 then
        return false
    end

    local v22, v89 =
        pcall(function()
            return v103.Visible
        end)

    return v22 and v89 == true
end

local function v104(v105)
    if not v105 then
        return
    end

    local v28 =
        v105.Parent

    while v28 do
        if v28:IsA("ScrollingFrame") then
            pcall(function()
                local v106 =
                    v28.CanvasPosition.Y

                local v107 =
                    v105.AbsolutePosition.Y
                    - v28.AbsolutePosition.Y

                local v108 =
                    math.max(
                        0,
                        v106
                        + v107
                        - math.floor(
                            v28.AbsoluteSize.Y * 0.35
                        )
                    )

                v28.CanvasPosition =
                    Vector2.new(
                        v28.CanvasPosition.X,
                        v108
                    )
            end)

            task.wait(0.08)
            return
        end

        v28 =
            v28.Parent
    end
end

-- CLIQUE
local function v109(v105)
    if not v105 or not v105:IsA("GuiButton") then
        DEBUG("v109: botão inválido")
        return false, "botão inválido"
    end

    DEBUG(
        "v109: tentando clicar "
        .. tostring(v105.Name)
    )

    v104(v105)

    local v110 = false

    if v1 then
        v110 =
            pcall(function()
                local v39 =
                    v105.AbsolutePosition

                local v111 =
                    v105.AbsoluteSize

                local X =
                    math.floor(
                        v39.X
                        + v111.X / 2
                    )

                local Y =
                    math.floor(
                        v39.Y
                        + v111.Y / 2
                    )

                v1:SendMouseButtonEvent(
                    X,
                    Y,
                    0,
                    true,
                    game,
                    0
                )

                task.wait(0.04)

                v1:SendMouseButtonEvent(
                    X,
                    Y,
                    0,
                    false,
                    game,
                    0
                )
            end)
    end

    if v110 then
        DEBUG(
            "v109: VirtualInputManager OK"
        )
    elseif firesignal then
        local v112 =
            pcall(function()
                firesignal(
                    v105.MouseButton1Click
                )
            end)

        if not v112 then
            DEBUG("v109: firesignal falhou")

            return false,
                "não consegui acionar o botão"
        end

        DEBUG("v109: firesignal OK")
    else
        DEBUG(
            "v109: nenhum método de clique disponível"
        )

        return false,
            "executor sem VirtualInputManager/firesignal"
    end

    task.wait(v2.v6)

    return true
end
local function v113(v105)
    if not v105 or not v105:IsA("GuiButton") then
        return false, "botão inválido"
    end

    if firesignal then
        local OK =
            pcall(function()
                firesignal(
                    v105.MouseButton1Click
                )
            end)

        if OK then
            task.wait(v2.v8)
            return true
        end
    end

    v104(v105)

    if v1 then
        local OK =
            pcall(function()
                local v39 =
                    v105.AbsolutePosition

                local v111 =
                    v105.AbsoluteSize

                local X =
                    math.floor(
                        v39.X + v111.X / 2
                    )

                local Y =
                    math.floor(
                        v39.Y + v111.Y / 2
                    )

                v1:SendMouseButtonEvent(
                    X,
                    Y,
                    0,
                    true,
                    game,
                    0
                )

                task.wait(0.01)

                v1:SendMouseButtonEvent(
                    X,
                    Y,
                    0,
                    false,
                    game,
                    0
                )
            end)

        if OK then
            task.wait(v2.v8)
            return true
        end
    end

    return false,
        "executor sem método de clique compatível"
end

-- TRADE
local function v114(v115)
    if not v115 then
        return 0
    end

    local v116 =
        v115:FindFirstChild("TopLabel")

    local v74 =
        v116
        and tostring(v116.Text or "")
        or ""

    local v84 =
        tonumber(
            string.match(
                v74,
                "[xX]%s*(%d+)"
            )
        )

    return v84 or 1
end

local function FTFID(v115)
    if not v115 then
        return nil
    end

    local v89 =
        v115:GetAttribute("ItemId")
        or v115:GetAttribute("itemId")

    if v89 == nil then
        return nil
    end

    return string.upper(
        tostring(v89)
    )
end

local function v117(v115)
    local v71 =
        v115
        and v115:FindFirstChild("BottomLabel")

    return {
        ftfId = FTFID(v115),
        image = v115
            and tostring(v115.Image or "")
            or "",
        name =
            v71
            and tostring(v71.Text or "")
            or ""
    }
end

local function v118(v115, v119)
    if not v115 or not v119 then
        return false
    end

    local ID =
        FTFID(v115)

    if ID
        and v119.ftfId
        and ID == v119.ftfId then
        return true
    end

    local v71 =
        v115:FindFirstChild("BottomLabel")

    local v16 =
        v71
        and tostring(v71.Text or "")
        or ""

    local v26 =
        tostring(v115.Image or "")

    if v119.image ~= ""
        and v26 == v119.image then
        return true
    end

    if v119.name ~= ""
        and v16 == v119.name then
        return true
    end

    return false
end

local function v120(v121, ftfId)
    if not v121 then
        return nil
    end

    local v122 =
        string.upper(
            tostring(ftfId or "")
        )

    for _, v115 in ipairs(
        v121:GetChildren()
    ) do
        if v115:IsA("ImageButton")
            and v115.Name ~= "ItemCellPrefab" then

            if FTFID(v115) == v122
                and v102(v115) then
                return v115
            end
        end
    end

    return nil
end

local function v123(v121, ftfId)
    local v115 =
        v120(v121, ftfId)

    if not v115 then
        return 0
    end

    return v114(v115)
end

local function v124(v125, v119)
    if not v125 then
        return 0
    end

    local v126 = 0

    for _, v115 in ipairs(
        v125:GetChildren()
    ) do
        if v115:IsA("ImageButton")
            and v115.Name ~= "ItemCellPrefab"
            and v102(v115) then

            if v118(v115, v119) then
                v126 += v114(v115)
            end
        end
    end

    return v126
end

local function v127()
    return v99(
        v100(),
        "TradingMenuWindow"
    )
end

local function v128(v96)
    local v43 =
        v127()

    local v129 =
        v99(
            v43,
            "TopBar",
            "OtherTraderTitleText"
        )

    if not v129 then
        return false
    end

    return
        string.lower(
            tostring(v129.Text or "")
        )
        ==
        string.lower(
            tostring(v96 or "")
        )
end

local function v130()
    local v131 =
        v99(
            v101(),
            "TradePopUpWindow"
        )

    if not v131
        or not v102(v131) then
        return true
    end

    local v132 =
        v90(
            35,
            function()
                return not v102(v131)
            end,
            0.15
        )

    return v132 == true
end

local function v133()
    DEBUG("Abrindo lista de trades...")

    if not v130() then
        DEBUG(
            "TradePopUpWindow está bloqueando"
        )
        return false,
            "há uma solicitação de trade recebida bloqueando a interface"
    end

    local v134 =
        v99(
            v100(),
            "TradeListMenuWindow"
        )

    if v134 and v102(v134) then
        DEBUG(
            "TradeListMenuWindow já aberto"
        )

        return true, v134
    end

    local v105 =
        v99(
            v101(),
            "MenusTabFrame",
            "tradeMenuButton"
        )

    if not v105 then
        DEBUG(
            "tradeMenuButton NÃO encontrado"
        )

        return false,
            "botão da lista de trades não encontrado"
    end

    DEBUG("tradeMenuButton encontrado")

    local OK, v135 =
        v109(v105)

    if not OK then
        return false, v135
    end

    local v136 =
        v90(
            5,
            function()
                local v65 =
                    v99(
                        v100(),
                        "TradeListMenuWindow"
                    )

                if v65 and v102(v65) then
                    return v65
                end

                return nil
            end
        )

    if not v136 then
        DEBUG(
            "TradeListMenuWindow NÃO abriu"
        )

        return false,
            "lista de trades não abriu"
    end

    DEBUG("TradeListMenuWindow abriu")

    return true, v136
end


local function v137(v96)
    local v65 =
        v99(
            v100(),
            "TradeListMenuWindow",
            "Body",
            "ScrollingFrame"
        )

    if not v65 then
        DEBUG(
            "ScrollingFrame da lista não encontrado"
        )

        return nil
    end

    local v122 =
        string.lower(
            tostring(v96 or "")
        )

    for _, v138 in ipairs(
        v65:GetChildren()
    ) do
        if v138:IsA("Frame")
            and v138.Name == "PlayerTradeCell"
            and v102(v138) then

            local v36 =
                v138:FindFirstChild(
                    "PlayerNameLabel"
                )

            if v36
                and string.lower(
                    tostring(v36.Text or "")
                ) == v122 then

                DEBUG(
                    "Cliente encontrado na lista: "
                    .. tostring(v96)
                )

                return v138
            end
        end
    end

    return nil
end

local function v139(v96)
    DEBUG(
        "Iniciando trade com "
        .. tostring(v96)
    )

    local OK, v135 =
        v133()

    if not OK then
        return false, v135
    end

    local v138 =
        v90(
            6,
            function()
                return v137(v96)
            end
        )

    if not v138 then
        DEBUG(
            "Cliente NÃO apareceu na lista"
        )

        return false,
            "cliente não apareceu na lista de trades"
    end

    local v105 =
        v138:FindFirstChild(
            "TradeButton"
        )

    if not v105
        or not v102(v105) then

        DEBUG(
            "TradeButton indisponível"
        )

        return false,
            "cliente está indisponível para receber trade"
    end

    DEBUG("TradeButton encontrado")

    local v140, v141 =
        v109(v105)

    if not v140 then
        return false, v141
    end

    DEBUG(
        "TradeButton clicado, aguardando janela"
    )

    local v136 =
        v90(
            v2.v3,
            function()
                local v43 =
                    v127()

                if v43
                    and v102(v43)
                    and v128(v96) then
                    return v43
                end

                return nil
            end,
            0.12
        )

    if not v136 then
        DEBUG(
            "TradingMenuWindow NÃO abriu ou jogador diferente"
        )

        return false,
            "cliente não aceitou a trade a tempo"
    end

    DEBUG("TradeWindow aberta corretamente")

    return true, v136
end

-- OFFER
local function v158(v159, v160)
    DEBUG("Preparando oferta")

    local v161 =
        v99(
            v159,
            "Body",
            "InventoryGridFrame"
        )

    local v162 =
        v99(
            v159,
            "Body",
            "OfferFrame",
            "YourOfferFrame"
        )

    if not v161 or not v162 then
        DEBUG(
            "Estrutura da oferta não encontrada"
        )

        return nil, nil,
            "estrutura da trade não encontrada"
    end

    local v21 = 0

    for _, v163 in ipairs(
        v162:GetChildren()
    ) do
        if v163:IsA("ImageButton")
            and v163.Name ~= "ItemCellPrefab"
            and v102(v163) then

            v21 += 1
        end
    end

    if v21 > 0 then
        DEBUG(
            "Oferta já possui "
            .. tostring(v21)
            .. " item(ns)"
        )

        return nil, nil,
            "a oferta abriu com itens inesperados"
    end

    local Tentativas = {}
    local EstadoPorChave = {}
    local v164 = {}

    for _, v83 in ipairs(v160) do
        local ftfId =
            string.upper(
                tostring(v83.ftfId or "")
            )

        if ftfId == ""
            or v83.invalid == true then

            DEBUG(
                "Item sem FTF ID: "
                .. tostring(v83.name)
            )

            return nil, nil,
                "pedido contém item sem FTF ID"
        end

        local v165 =
            math.max(
                0,
                tonumber(v83.quantity or 0)
                or 0
            )

        if v165 > 0 then
            local v115 =
                v120(
                    v161,
                    ftfId
                )

            if not v115 then
                DEBUG(
                    "Item não encontrado: "
                    .. tostring(ftfId)
                )

                return nil, nil,
                    "item não encontrado no inventário da trade: "
                    .. ftfId
            end

            if v164[ftfId] == nil then
                v164[ftfId] =
                    v123(
                        v161,
                        ftfId
                    )
            end

            local v166 =
                v117(v115)

            local v167 =
                tostring(v83.key)

            EstadoPorChave[v167] = {
                key = v167,
                ftfId = ftfId,
                name = v83.name,
                requested = v165,
                before =
                    v124(
                        v162,
                        v166
                    ),
                fingerprint = v166
            }

            for _ = 1, v165 do
                table.insert(
                    Tentativas,
                    {
                        key = v167,
                        ftfId = ftfId,
                        card = v115
                    }
                )
            end
        end
    end

    DEBUG(
        "Tentativas de itens: "
        .. tostring(#Tentativas)
    )

    if #Tentativas == 0 then
        return nil, nil,
            "nenhum item restante para colocar na oferta"
    end

    local CliquesOK = 0

    for _, Tentativa in ipairs(
        Tentativas
    ) do
        if Tentativa.card
            and Tentativa.card.Parent then

            local OK =
                v113(
                    Tentativa.card
                )

            if OK then
                CliquesOK += 1
            end
        end
    end

    DEBUG(
        "Cliques nos itens: "
        .. tostring(CliquesOK)
        .. "/"
        .. tostring(#Tentativas)
    )

    if CliquesOK <= 0 then
        return nil, nil,
            "não consegui clicar nos itens da oferta"
    end

    task.wait(v2.v10)

    local v168 = {}
    local v169 = 0

    for v167, v24 in pairs(
        EstadoPorChave
    ) do
        local Depois =
            v124(
                v162,
                v24.fingerprint
            )

        local Entrou =
            math.max(
                0,
                Depois
                - (tonumber(v24.before) or 0)
            )

        Entrou =
            math.min(
                Entrou,
                tonumber(v24.requested) or 0
            )

        if Entrou > 0 then
            v168[v167] = {
                key = v167,
                ftfId = v24.ftfId,
                name = v24.name,
                quantity = Entrou
            }

            v169 += Entrou
        end
    end

    DEBUG(
        "Itens realmente na oferta: "
        .. tostring(v169)
    )

    if v169 <= 0 then
        return nil, nil,
            "nenhum item entrou na oferta depois do burst"
    end

    return v168, v164, nil
end

-- FUNÇÕES RESTANTES
local function v170(v168)
    local v171 = {}

    for _, v89 in pairs(v168 or {}) do
        table.insert(
            v171,
            {
                key = v89.key,
                ftfId = v89.ftfId,
                quantity = v89.quantity
            }
        )
    end

    table.sort(
        v171,
        function(a, b)
            return tostring(a.key)
                <
                tostring(b.key)
        end
    )

    return v171
end

local function v172(v168)
    local v173 = {}

    for _, v89 in pairs(v168 or {}) do
        v173[v89.ftfId] =
            (v173[v89.ftfId] or 0)
            +
            (tonumber(v89.quantity) or 0)
    end

    return v173
end

local function v174(v175, v176, v168, v177)
    while true do
        local v22, v88, v24 =
            pcall(function()
                local B, S =
                    HTTP(
                        "POST",
                        "/api/delivery/"
                        .. v175
                        .. "/progress",
                        {
                            worker = v2.WORKER,
                            batchId = v176,
                            delivered = v170(v168),
                            detail =
                                v177
                                or "trade concluída"
                        }
                    )

                return B, S
            end)

        if v22
            and v24 >= 200
            and v24 < 300
            and v88 then
            return v88
        end

        task.wait(5)
    end
end

local function v178(v175)
    local v24 = {
        ativo = true
    }

    task.spawn(function()
        while v24.ativo do
            task.wait(v2.v11)

            if not v24.ativo then
                break
            end

            pcall(function()
                HTTP(
                    "POST",
                    "/api/delivery/"
                    .. v175
                    .. "/heartbeat",
                    {
                        worker = v2.WORKER
                    }
                )
            end)
        end
    end)

    return v24
end

local function v179(v160, v168)
    for _, v83 in ipairs(v160) do
        local v180 =
            v168[v83.key]

        if v180 then
            v83.quantity =
                math.max(
                    0,
                    tonumber(v83.quantity)
                    or 0
                )

            v83.quantity =
                math.max(
                    0,
                    v83.quantity
                    -
                    (tonumber(v180.quantity) or 0)
                )
        end
    end

    local v181 = {}

    for _, v83 in ipairs(v160) do
        if (tonumber(v83.quantity) or 0) > 0 then
            table.insert(
                v181,
                v83
            )
        end
    end

    return v181
end

-- CORREÇÃO: v149 ESTAVA AUSENTE
local function v149(v164, v190)
    DEBUG("Conferindo estoque após a trade...")

    local inventario, erro =
        COLETAR_INVENTARIO()

    if not inventario then
        DEBUG(
            "Não foi possível conferir estoque: "
            .. tostring(erro)
        )

        return false, tostring(erro)
    end

    local atual = {}

    for _, item in ipairs(inventario) do
        local id =
            string.upper(
                tostring(item.id or "")
            )

        if id ~= "" then
            atual[id] =
                tonumber(item.quantity or 0)
                or 0
        end
    end

    for ftfId, quantidadeEntregue in pairs(v190 or {}) do
        local id =
            string.upper(
                tostring(ftfId)
            )

        local antes =
            tonumber(v164[id] or 0)
            or 0

        local depois =
            tonumber(atual[id] or 0)
            or 0

        local esperado =
            math.max(
                0,
                antes
                - (tonumber(quantidadeEntregue) or 0)
            )

        if depois > esperado then
            DEBUG(
                "Estoque não bateu para "
                .. id
                .. " | antes="
                .. tostring(antes)
                .. " | esperado="
                .. tostring(esperado)
                .. " | atual="
                .. tostring(depois)
            )

            return false,
                "estoque não confirmou a remoção do item "
                .. id
        end

        DEBUG(
            "Estoque confirmado: "
            .. id
            .. " | "
            .. tostring(antes)
            .. " -> "
            .. tostring(depois)
        )
    end

    DEBUG("Estoque confirmado com sucesso")

    return true, "estoque conferido"
end

-- PROCESSO DE ENTREGA
local function v182(v81)
    local v96 =
        tostring(v81.nick or "")

    DEBUG(
        "PROCESSANDO PEDIDO "
        .. tostring(v81.orderId)
    )

    DEBUG(
        "Cliente: "
        .. tostring(v96)
    )

    local v160 = {}

    for _, v83 in ipairs(
        v81.items or {}
    ) do
        table.insert(
            v160,
            {
                key =
                    tostring(
                        v83.key
                        or v83.ftfId
                        or v83.id
                        or ""
                    ),
                ftfId = v83.ftfId,
                name = v83.name,
                quantity =
                    tonumber(v83.quantity or 0)
                    or 0,
                invalid =
                    v83.invalid == true
            }
        )
    end

    if #v160 == 0 then
        DEBUG("Pedido sem itens")

        return true,
            "nenhum item restante"
    end

    local v183 =
        v178(v81.orderId)

    local v184 =
        tonumber(
            v81.progress
            and v81.progress.tradesCompleted
            or 0
        )
        or 0

    local v22, v173, v177 =
        pcall(function()
            while #v160 > 0 do
                DEBUG(
                    "Restam "
                    .. tostring(#v160)
                    .. " tipos de item"
                )

                v73("aguardando pedidos")

                local v103 =
                    v95(v96)

                if not v103 then
                    DEBUG(
                        "CLIENTE NÃO ESTÁ NO SERVIDOR"
                    )

                    return false,
                        "cliente não está neste servidor"
                end

                DEBUG(
                    "Cliente está no servidor"
                )

                v73("entrega pendente")

                local v185, v186 =
                    v139(v96)

                if not v185 then
                    DEBUG(
                        "Falha ao iniciar trade: "
                        .. tostring(v186)
                    )

                    return false, v186
                end

                local v159 =
                    v186

                if not v128(v96) then
                    DEBUG(
                        "Trade abriu com jogador errado"
                    )

                    return false,
                        "a trade abriu com outro jogador"
                end

                DEBUG(
                    "Trade confirmada com "
                    .. tostring(v96)
                )

                v73("entregando marretas")

                local v168, v164, v187 =
                    v158(
                        v159,
                        v160
                    )

                if not v168 then
                    DEBUG(
                        "Falha preparando oferta: "
                        .. tostring(v187)
                    )

                    return false,
                        v187
                        or "não consegui preparar a oferta"
                end

                local Accept =
                    v99(
                        v159,
                        "Body",
                        "OfferFrame",
                        "AcceptButton"
                    )

                if not Accept then
                    DEBUG(
                        "AcceptButton NÃO encontrado"
                    )

                    return false,
                        "AcceptButton não encontrado"
                end

                DEBUG(
                    "AcceptButton encontrado"
                )

                -- CORREÇÃO: v157(Accept) REMOVIDO
                DEBUG(
                    "Clicando AcceptButton..."
                )

                local AcceptOK, v188 =
                    v109(Accept)

                if not AcceptOK then
                    DEBUG(
                        "Falha ao clicar AcceptButton: "
                        .. tostring(v188)
                    )

                    return false, v188
                end

                DEBUG(
                    "AcceptButton clicado"
                )

                local v189 =
                    v90(
                        v2.v4,
                        function()
                            return not v102(v159)
                        end,
                        0.12
                    )

                if not v189 then
                    DEBUG(
                        "Trade não fechou dentro do tempo"
                    )

                    return false,
                        "cliente não confirmou a trade a tempo"
                end

                DEBUG(
                    "Trade fechou"
                )

                task.wait(v2.v5)

                local v190 =
                    v172(v168)

                local v191, v192 =
                    v149(
                        v164,
                        v190
                    )

                if v191 == false then
                    DEBUG(
                        "Estoque não confirmou"
                    )

                    return false,
                        "trade fechou mas a entrega não foi confirmada: "
                        .. tostring(v192)
                end

                v184 += 1

                local v176 =
                    v81.orderId
                    .. ":"
                    .. tostring(v184)
                    .. ":"
                    .. tostring(
                        math.floor(
                            os.clock() * 1000
                        )
                    )

                local v193 =
                    v174(
                        v81.orderId,
                        v176,
                        v168,
                        v191 == true
                        and "trade concluída + estoque conferido"
                        or tostring(v192)
                    )

                DEBUG(
                    "Progresso salvo na API"
                )

                v160 =
                    v179(
                        v160,
                        v168
                    )

                if #v160 > 0 then
                    v73("entrega pendente")
                end

                task.wait(0.8)
            end

            v73("marretas entregues")

            DEBUG(
                "TODAS AS TRADES CONCLUÍDAS"
            )

            return true,
                "todas as trades concluídas"
        end)

    v183.ativo = false

    if not v22 then
        DEBUG(
            "ERRO INTERNO: "
            .. tostring(v173)
        )

        return false,
            tostring(v173)
    end

    return v173, v177
end

local function v194(v175, v91)
    pcall(function()
        HTTP(
            "POST",
            "/api/delivery/"
            .. v175
            .. "/release",
            {
                retryAfterSeconds =
                    v91 or 20
            }
        )
    end)
end

local function v195(v175, v22, v177)
    DEBUG(
        "Confirmando pedido na API: "
        .. tostring(v175)
    )

    return HTTP(
        "POST",
        "/api/delivery/"
        .. v175
        .. "/confirm",
        {
            success = v22,
            detail = v177 or "",
            retryAfterSeconds = 20
        }
    )
end

-- v196 COM DEBUG COMPLETO
local function v196()
    if v13 then
        return
    end

    v13 = true

    DEBUG("================================")
    DEBUG("VERIFICANDO NOVO PEDIDO")
    DEBUG("Worker: " .. tostring(v2.WORKER))

    local v22, v197 =
        pcall(function()
            local v81, v24 =
                HTTP(
                    "GET",
                    "/api/delivery/next?worker="
                    .. HttpService:UrlEncode(
                        v2.WORKER
                    )
                )

            DEBUG(
                "Status /delivery/next: "
                .. tostring(v24)
            )

            if v24 == 204 then
                DEBUG(
                    "API retornou 204: nenhum pedido disponível"
                )

                v73("aguardando pedidos")

                return
            end

            if not v81 then
                DEBUG(
                    "API não retornou dados do pedido"
                )

                v73("aguardando pedidos")

                return
            end

            DEBUG("Pedido recebido da API")

            if v81.orderId then
                DEBUG(
                    "OrderID: "
                    .. tostring(v81.orderId)
                )
            else
                DEBUG("ERRO: orderId ausente")
            end

            if v81.nick then
                DEBUG(
                    "Cliente: "
                    .. tostring(v81.nick)
                )
            else
                DEBUG("ERRO: nick ausente")
            end

            if not v81.orderId
                or not v81.nick then

                warn(
                    "[KyanStore] pedido inválido"
                )

                return
            end

            v80(v81)

            DEBUG(
                "Itens no pedido: "
                .. tostring(
                    #(v81.items or {})
                )
            )

            local v103 =
                v95(v81.nick)

            if not v103 then
                DEBUG(
                    "CLIENTE NÃO ESTÁ NO SERVIDOR"
                )

                v73("aguardando pedidos")

                v194(
                    v81.orderId,
                    20
                )

                return
            end

            DEBUG(
                "CLIENTE ENCONTRADO NO SERVIDOR"
            )

            print(
                "[KyanStore] entrega:",
                v81.orderId,
                "->",
                v81.nick
            )

            local OK, v177 =
                v182(v81)

            if OK then
                DEBUG(
                    "Entrega concluída. Confirmando..."
                )

                local v88, v198 =
                    v195(
                        v81.orderId,
                        true,
                        v177
                        or "entrega concluída"
                    )

                DEBUG(
                    "Status confirmação: "
                    .. tostring(v198)
                )

                if v198
                    and v198 >= 200
                    and v198 < 300 then

                    v73(
                        "marretas entregues"
                    )

                    DEBUG(
                        "PEDIDO CONFIRMADO COM SUCESSO"
                    )

                    task.wait(2)

                    v80(nil)

                    v73(
                        "aguardando pedidos"
                    )
                else
                    DEBUG(
                        "API NÃO CONFIRMOU O PEDIDO"
                    )

                    warn(
                        "[KyanStore] API não confirmou:",
                        v198
                    )
                end
            else
                DEBUG(
                    "ENTREGA FALHOU: "
                    .. tostring(v177)
                )

                v73(
                    "aguardando pedidos"
                )

                v195(
                    v81.orderId,
                    false,
                    v177
                    or "trade falhou"
                )

                warn(
                    "[KyanStore] entrega pausada:",
                    v177
                )
            end
        end)

    if not v22 then
        DEBUG(
            "ERRO NO PROCESSO PRINCIPAL: "
            .. tostring(v197)
        )

        warn(
            "[KyanStore] erro:",
            v197
        )
    end

    DEBUG("FIM DA VERIFICAÇÃO")
    DEBUG("================================")

    v13 = false
end

-- INICIALIZAÇÃO
print(
    "[KyanStore] worker iniciado como",
    v12.Name
)

DEBUG(
    "Worker iniciado: "
    .. tostring(v12.Name)
)

DEBUG(
    "Aguardando pedidos da API..."
)

task.spawn(function()
    local ultimaSync = 0
    local ultimaTentativa = 0

    while true do
        task.wait(5)

        local agora =
            os.time()

        local solicitado = false

        pcall(function()
            solicitado =
                FOI_SOLICITADO()
        end)

        local automatico =
            agora - ultimaSync >= 60

        if solicitado
            or (
                automatico
                and agora - ultimaTentativa >= 30
            ) then

            ultimaTentativa =
                agora

            local ok, resultado =
                pcall(
                    SINCRONIZAR
                )

            if ok and resultado then
                ultimaSync =
                    agora
            end

            if v14.v72 then
                if ok and resultado then
                    v14.v72.Text =
                        "worker ativo • estoque sincronizado • aguardando pedidos"
                elseif ok then
                    v14.v72.Text =
                        "worker ativo • estoque: abra o inventario nas marretas • aguardando pedidos"
                else
                    v14.v72.Text =
                        "worker ativo • estoque: erro na sincronizacao • aguardando pedidos"
                end
            end
        end
    end
end)

while task.wait(
    v2.INTERVALO
) do
    v196()
end
