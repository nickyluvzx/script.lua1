--[[
===============================================================================
   FARM + GUARDA  v3.13                para Delta Executor        (MM2)
===============================================================================
   AQUI TEM TUDO JUNTO:
     [FARM]   mapeia TODAS as moedas validas do mapa e escolhe a melhor:
              perto de voce e LONGE do murder (moeda na area do murder perde
              pontos). Marca de vermelho com linha, voa atravessando
              parede/chao, encosta, confirma e vai pra proxima.
     [GUARDA] murder fica verde neon; se chegar perto, sai DISPARADO pra
              longe (70 studs/s, arranque imediato) e nao volta a farmar
              enquanto ele nao afastar de verdade.
     [ESTATICO] com o farm desligado, o personagem fica travado no lugar
              (de pe se estiver no chao, flutuando se estiver no ar). Era isso
              que faltava pra ele nao descer pra baixo do mapa.
     [BOLSA]  a bolsa do MM2 e 50 moedas. Chegou em 50, ele RESETA o
              personagem pra esvaziar e volta a farmar.
              - SE VOCE FOR O MURDER: continua FARMANDO normalmente, mas
                quando a bolsa enche ele NAO reseta: fica ESTATICO onde
                estiver, esperando a partida acabar.
     [SEM MOEDA] sem moeda no mapa NAO e bolsa cheia: e intervalo entre
              partidas / lobby. Fica parado esperando, sem resetar.
              Morreu, mataram ou a partida acabou? A proxima vida comeca com
              a bolsa vazia - sem reset nenhum.
     [LOBBY x PARTIDA] o lobby tem as moedas do mapa no Workspace, mas elas
              estao longe e/ou invisiveis. Ele so farma quando detecta partida
              de verdade: faca do murder, arma do xerife, ou moeda valida
              dentro de CONFIG.distanciaMaxima. Fora disso, fica parado.
     [TELEPORTE DO SERVIDOR] no lobby ele NAO trava o personagem (trava no
              lobby impede o servidor de te teleportar pro mapa). E a trava,
              quando usada em partida, solta sozinha se o servidor te mover.

   UI PENSADA PRA CELULAR (botao grande, sem depender de teclado):
     AUTO FARM: LIGAR / DESLIGAR
     GUARDA:    LIGAR / DESLIGAR
     RESETAR BOLSA
     velocidade - / +

   ATALHOS (PC):  RightShift = farm    F2 = guarda    F3 = painel

   AVISOS:
     * automatizar o MM2 viola os Termos de Uso da Roblox - risco de ban e seu
     * o reset mata o seu personagem (Humanoid.Health = 0) pra renascer e
       limpar a bolsa. Como murder isso NUNCA acontece (ele fica estatico)
     * se o jogo mudar o nome das moedas/faca, ajuste padroesNome/padroesFaca
===============================================================================
]]

--=============================================================================
-- 1) CONFIGURACAO
--=============================================================================
local CONFIG = {
	-- ---- FARM ----
	velocidade         = 30,    -- studs/s (16 = andar)
	variacaoVelocidade = 0.15,
	alturaAproximacao  = 2.5,
	esperaColeta       = 0.2,
	retentativas       = 1,
	cooldownColeta     = 10,
	tempoSemMoeda      = 25,    -- s sem moeda = intervalo/lobby (NAO reseta)
	distanciaMaxima    = 250,   -- moeda mais longe que isso e de outro mapa/lobby
	limiteTeleporte    = 40,    -- pulo maior que isso = o servidor teleportou
	capacidadeBolsa    = 50,    -- bolsa do MM2 = 50 moedas
	zerarBolsaAoRenascer = false, -- nao zera a bolsa ao renascer (a conta segue)
	tempoLobby         = 5,     -- s fora de partida = partida acabou, zera a bolsa
	graceColeta        = 2.5,   -- s pra confirmar moeda que demora pra sumir
	resetEspera        = 6,     -- s esperando o respawn depois do reset

	-- ---- GUARDA ----
	distanciaPerigo    = 45,
	distanciaPerigoCega = 15,   -- sem visao, so foge se estiver colado
	usarVisao          = true,  -- parede no meio = nao foge
	alturaPerigo       = 12,    -- diferenca de altura maxima pra contar como perto
	raioPerigoMoeda    = 60,    -- moeda dentro disso do murder perde pontos
	pesoMoedaLongeMurder = 3,   -- quanto mais longe do murder, melhor a nota
	distanciaFuga      = 65,    -- dispara pra longe (sem atravessar o mapa)
	subidaFuga         = 10,
	velocidadeFuga     = 70,    -- studs/s (sai disparado, nao passeia)
	corNeon            = Color3.fromRGB(0, 255, 90),
	mostrarTag         = true,

	-- ---- GERAL ----
	usarNoclip         = true,
	estatico           = true,
	exigirCaraDeMoeda  = true,  -- so aceita moeda com CoinVisual/CoinContainer
	usarContadorJogo   = true,  -- usa o contador de moedas do jogo, se achar
	debugRemotes       = false, -- mostra no F9 os remotes de moeda (diagnostico)
	antiAfk            = true,
	mostrarPainel      = true,
	padroesNome        = { "coin", "coins", "moeda", "moedas", "cash", "money" },
	padroesFaca        = { "knife", "faca", "dagger", "murder" },
	padroesArma        = { "gun", "pistol", "revolver", "sheriff" },
	teclaFarm          = Enum.KeyCode.RightShift,
	teclaGuarda        = Enum.KeyCode.F2,
	teclaPainel        = Enum.KeyCode.F3,
}

--=============================================================================
-- 2) SERVICOS E HELPERS
--=============================================================================
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui       = game:GetService("StarterGui")
local Workspace        = game:GetService("Workspace")
local RunService       = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
	task.wait(0.2)
	LocalPlayer = Players.LocalPlayer
end
if not game:IsLoaded() then
	game.Loaded:Wait()
end

local function safe(fn, ...)
	local ok, a = pcall(fn, ...)
	if ok then
		return a
	end
	return nil
end

local VirtualUser = safe(function()
	return game:GetService("VirtualUser")
end)

local function aviso(titulo, texto, duracao)
	safe(function()
		StarterGui:SetCore("SendNotification", {
			Title = tostring(titulo),
			Text = tostring(texto),
			Duration = duracao or 4,
		})
	end)
end

local function log(texto)
	print("[Farm+Guarda] " .. tostring(texto))
end

local function getRig()
	local char = LocalPlayer.Character
	if not char or not char.Parent then
		return nil, nil, nil
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp or hum.Health <= 0 then
		return nil, nil, nil
	end
	return char, hum, hrp
end

-- se ja tinha uma versao rodando, manda parar (evita dois controlando o corpo)
do
	local anterior = safe(function()
		return getgenv().MM2FarmGuarda
	end)
	if type(anterior) == "table" and type(anterior.desligar) == "function" then
		pcall(anterior.desligar)
	end
end

--=============================================================================
-- 3) ESTADO
--=============================================================================
local estado = {
	ativo         = true,
	farmLigado    = false,
	guarda        = true,    -- ja comeca vigiando (e segurando estatico)
	travado       = false,
	modoDePe      = false,
	fugindo       = false,
	resetando     = false,
	situacao      = "carregando",
	murder        = nil,
	souMurder     = false,
	temArma       = false,   -- alguem com a arma do xerife = partida rolando
	emPartida     = false,   -- detectou partida de verdade (nao lobby)
	dist          = math.huge,
	distVertical  = math.huge,
	mesmaAltura   = false,   -- murder no mesmo andar/nivel?
	temVisao      = false,   -- da pra ver o murder (sem parede no meio)?
	jogo          = nil,     -- valor do contador de moedas do jogo (se existir)
	jogoBase      = nil,     -- valor do contador no inicio da contagem
	jogoMudou     = false,   -- o contador do jogo ja mudou? (senao usa o script)
	semPartidaDesde = nil,   -- desde quando ele nao detecta partida
	bolsaZerada   = false,   -- ja zerou a bolsa nesse intervalo?
	moedas        = 0,       -- bolsa (zera quando reseta)
	total         = 0,       -- total da sessao
	alvo          = nil,
	posTrava      = nil,
	semMoedaDesde = os.clock(),
	ultimaFuga    = 0,
	ultimoPerigo  = 0,
	noclipLigado  = false,
	coletadas     = {},
	ignoradas     = {},
	pendentes     = {},      -- [moeda] = hora do toque (confirmando se sumiu)
}

local Ui = {}

local BG       = Color3.fromRGB(22, 22, 28)
local BG2      = Color3.fromRGB(34, 34, 43)
local TEXT     = Color3.fromRGB(236, 236, 245)
local TEXT_DIM = Color3.fromRGB(150, 150, 168)
local VERDE    = Color3.fromRGB(0, 200, 130)
local NEON     = Color3.fromRGB(0, 255, 90)
local CINZA    = Color3.fromRGB(70, 70, 84)
local LARANJA  = Color3.fromRGB(235, 150, 60)
local VERMELHO = Color3.fromRGB(220, 60, 70)

--=============================================================================
-- 4) NOCLIP CONTINUO + CONTROLE DO HUMANOID
--=============================================================================
local colisaoOriginal = {}

local function aplicarNoclip()
	local char = LocalPlayer.Character
	if not char then
		return
	end
	local partes = char:GetDescendants()
	for i = 1, #partes do
		local d = partes[i]
		if d:IsA("BasePart") and d.CanCollide then
			colisaoOriginal[d] = true
			pcall(function()
				d.CanCollide = false
			end)
		end
	end
end

local function restaurarColisao()
	for inst in pairs(colisaoOriginal) do
		if inst.Parent then
			pcall(function()
				inst.CanCollide = true
			end)
		end
	end
	colisaoOriginal = {}
end

local function prepararVoo(hum, hrp)
	if hum then
		pcall(function()
			hum.PlatformStand = true
			if hum:GetState() ~= Enum.HumanoidStateType.Physics then
				hum:ChangeState(Enum.HumanoidStateType.Physics)
			end
		end)
	end
	if hrp then
		pcall(function()
			hrp.CanCollide = false
		end)
	end
end

local function devolverControle()
	local _, hum = getRig()
	if hum then
		safe(function()
			hum.PlatformStand = false
		end)
		safe(function()
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
		safe(function()
			hum:ChangeState(Enum.HumanoidStateType.Running)
		end)
	end
end

local passosNoclip = 0
RunService.Stepped:Connect(function()
	if not estado.noclipLigado then
		return
	end

	aplicarNoclip()

	passosNoclip = passosNoclip + 1
	if passosNoclip % 20 == 0 and not estado.modoDePe then
		local _, hum, hrp = getRig()
		if hum and (estado.travado or estado.fugindo) then
			prepararVoo(hum, hrp)
		end
	end
end)

--=============================================================================
-- 5) CHAO
--=============================================================================
local function acharChaoAbaixo(posicao)
	local params = RaycastParams.new()
	pcall(function()
		params.FilterType = Enum.RaycastFilterType.Exclude
	end)
	local char = LocalPlayer.Character
	if char then
		pcall(function()
			params.FilterDescendantsInstances = { char }
		end)
	end
	pcall(function()
		params.IgnoreWater = true
	end)

	local resultado = safe(function()
		return Workspace:Raycast(posicao, Vector3.new(0, -300, 0), params)
	end)
	if resultado then
		return resultado.Position
	end
	return nil
end

--=============================================================================
-- 6) MURDER: DETECCAO E DESTAQUE VERDE NEON
--=============================================================================
local destaque = { char = nil, highlight = nil, billboard = nil }

local function limparDestaque()
	if destaque.highlight then
		pcall(function()
			destaque.highlight:Destroy()
		end)
	end
	if destaque.billboard then
		pcall(function()
			destaque.billboard:Destroy()
		end)
	end
	destaque.char = nil
	destaque.highlight = nil
	destaque.billboard = nil
end

local function aplicarDestaque(plr)
	local char = plr and plr.Character
	if not char or not char.Parent then
		limparDestaque()
		return
	end
	if destaque.char == char and destaque.highlight and destaque.highlight.Parent then
		return
	end

	limparDestaque()

	pcall(function()
		local h = Instance.new("Highlight")
		h.Name = "MurderNeon"
		h.FillColor = CONFIG.corNeon
		h.FillTransparency = 0.45
		h.OutlineColor = CONFIG.corNeon
		h.OutlineTransparency = 0
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.Adornee = char
		h.Parent = char
		destaque.highlight = h
	end)

	if CONFIG.mostrarTag then
		pcall(function()
			local alvo = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char
			local gui = Instance.new("BillboardGui")
			gui.Name = "MurderTag"
			gui.Size = UDim2.new(0, 92, 0, 24)
			gui.StudsOffset = Vector3.new(0, 2.6, 0)
			gui.AlwaysOnTop = true
			gui.MaxDistance = 250
			gui.Adornee = alvo
			gui.Parent = alvo

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.GothamBold
			label.TextSize = 14
			label.TextColor3 = CONFIG.corNeon
			label.TextStrokeTransparency = 0.4
			label.Text = "MURDER"
			label.Parent = gui

			destaque.billboard = gui
		end)
	end

	destaque.char = char
end

local function nomeCombinaLista(nome, lista)
	local n = string.lower(tostring(nome))
	for _, padrao in ipairs(lista) do
		if string.find(n, padrao, 1, true) then
			return true
		end
	end
	return false
end

local function temFerramenta(plr, padroes)
	local char = plr.Character
	if char then
		for _, obj in ipairs(char:GetChildren()) do
			if obj:IsA("Tool") and nomeCombinaLista(obj.Name, padroes) then
				return true
			end
		end
	end

	local bp = plr:FindFirstChildOfClass("Backpack")
	if bp then
		for _, obj in ipairs(bp:GetChildren()) do
			if obj:IsA("Tool") and nomeCombinaLista(obj.Name, padroes) then
				return true
			end
		end
	end

	return false
end

local function temFaca(plr)
	return temFerramenta(plr, CONFIG.padroesFaca)
end

local function temArma(plr)
	return temFerramenta(plr, CONFIG.padroesArma)
end

local function temAtributoMurder(plr)
	local alvos = { plr }
	if plr.Character then
		table.insert(alvos, plr.Character)
	end

	for _, obj in ipairs(alvos) do
		local ok, attrs = pcall(function()
			return obj:GetAttributes()
		end)
		if ok and type(attrs) == "table" then
			for nome, valor in pairs(attrs) do
				if valor == true then
					local n = string.lower(tostring(nome))
					if string.find(n, "murder", 1, true) or string.find(n, "assassin", 1, true) then
						return true
					end
				end
			end
		end
	end

	return false
end

-- varre os jogadores UMA vez e devolve:
--   murder = quem esta com a faca (ou atributo de murder)
--   arma   = se tem a arma do xerife no mapa (partida rolando)
local function varrerPapeis()
	local murder = nil
	local arma = false
	local jogadores = Players:GetPlayers()

	for i = 1, #jogadores do
		local plr = jogadores[i]

		local okA, gun = pcall(function()
			return temArma(plr)
		end)
		if okA and gun then
			arma = true
		end

		if plr ~= LocalPlayer then
			local okF, faca = pcall(function()
				return temFaca(plr) or temAtributoMurder(plr)
			end)
			if okF and faca and not murder then
				murder = plr
			end
		end
	end

	return murder, arma
end

local function souMurder()
	local ok, eh = pcall(function()
		return temFaca(LocalPlayer) or temAtributoMurder(LocalPlayer)
	end)
	return ok and eh == true
end

--=============================================================================
-- 7) MOEDAS: DETECCAO E VALIDACAO
--=============================================================================
local moedas    = {}
local moedasSet = {}

local function nomeCombina(nome)
	local n = string.lower(tostring(nome))
	for _, padrao in ipairs(CONFIG.padroesNome) do
		if string.find(n, padrao, 1, true) then
			return true
		end
	end
	return false
end

local function temVisualDeMoeda(parte)
	local ok, desc = pcall(function()
		return parte:GetDescendants()
	end)
	if ok then
		for _, d in ipairs(desc) do
			if d:IsA("BasePart")
				and string.find(string.lower(tostring(d.Name)), "visual", 1, true) then
				return true
			end
		end
	end
	return false
end

local function ehMoeda(parte)
	if not parte:IsA("BasePart") then
		return false
	end
	if not parte:IsDescendantOf(Workspace) then
		return false
	end

	local char = LocalPlayer.Character
	if char and parte:IsDescendantOf(char) then
		return false
	end

	local cam = Workspace.CurrentCamera
	if cam and parte:IsDescendantOf(cam) then
		return false
	end

	-- moeda do MM2 e Coin_Server com um CoinVisual dentro. O visual e o
	-- "CoinContainer" NAO sao moedas — so a Coin_Server e.
	local nomeParte = string.lower(tostring(parte.Name))
	if string.find(nomeParte, "visual", 1, true)
		or string.find(nomeParte, "container", 1, true) then
		return false
	end

	if not nomeCombina(parte.Name) then
		local pai0 = parte.Parent
		if not (pai0 and pai0 ~= Workspace and nomeCombina(pai0.Name)) then
			return false
		end
	end

	-- so aceita moeda "de verdade": tem CoinVisual dentro ou esta dentro de um
	-- CoinContainer. Decoracao do mapa com "coin" no nome fica de fora.
	if CONFIG.exigirCaraDeMoeda then
		local pai = parte.Parent
		local dentroDeContainer = pai and pai ~= Workspace
			and string.find(string.lower(tostring(pai.Name)), "container", 1, true) ~= nil

		if not temVisualDeMoeda(parte) and not dentroDeContainer then
			return false
		end
	end

	return true
end

local function moedaExiste(moeda)
	if not moeda or not moeda.Parent then
		return false
	end
	local ok, noMapa = pcall(moeda.IsDescendantOf, moeda, Workspace)
	return ok and noMapa == true
end

local function temAtributoColetada(moeda)
	local ok, attrs = pcall(function()
		return moeda:GetAttributes()
	end)
	if not ok or type(attrs) ~= "table" then
		return false
	end
	for nome, valor in pairs(attrs) do
		if valor == true then
			local n = string.lower(tostring(nome))
			if string.find(n, "collect", 1, true)
				or string.find(n, "taken", 1, true)
				or string.find(n, "grabbed", 1, true) then
				return true
			end
		end
	end
	return false
end

-- visivel = a propria peca OU uma casca visivel dentro dela (CoinVisual).
-- A Coin_Server pode ser invisivel (hitbox) e mesmo assim ser a moeda de
-- verdade; antes o filtro de transparencia matava ela.
local function moedaVisivel(moeda)
	local ok, transparencia, transparenciaLocal = pcall(function()
		return moeda.Transparency, moeda.LocalTransparencyModifier
	end)
	if not ok then
		return false
	end

	if (transparencia or 0) < 0.99 and (transparenciaLocal or 0) < 0.99 then
		return true
	end

	local okDesc, desc = pcall(function()
		return moeda:GetDescendants()
	end)
	if okDesc then
		for _, d in ipairs(desc) do
			if d:IsA("BasePart") then
				local okT, t = pcall(function()
					return d.Transparency
				end)
				if okT and (t or 0) < 0.99 then
					return true
				end
			end
		end
	end

	return false
end

-- a moeda (ou a casca visivel dela) tem que aceitar toque
local function moedaTocavel(moeda)
	local ok, canTouch = pcall(function()
		return moeda.CanTouch
	end)
	if ok and canTouch then
		return true
	end

	local okDesc, desc = pcall(function()
		return moeda:GetDescendants()
	end)
	if okDesc then
		for _, d in ipairs(desc) do
			if d:IsA("BasePart") then
				local ok2, ct = pcall(function()
					return d.CanTouch
				end)
				if ok2 and ct then
					return true
				end
			end
		end
	end

	return false
end

local function moedaValida(moeda)
	if not moedaExiste(moeda) then
		return false
	end

	local pegueiEm = estado.coletadas[moeda]
	if pegueiEm and (os.clock() - pegueiEm) < (CONFIG.cooldownColeta or 10) then
		return false
	end

	if estado.ignoradas[moeda] then
		return false
	end
	if temAtributoColetada(moeda) then
		return false
	end

	if not moedaTocavel(moeda) then
		return false
	end

	if not moedaVisivel(moeda) then
		return false
	end

	if moeda.Size and (moeda.Size.X < 0.05 or moeda.Size.Y < 0.05 or moeda.Size.Z < 0.05) then
		return false
	end

	return true
end

local function registrarMoeda(inst)
	if moedasSet[inst] or estado.ignoradas[inst] then
		return
	end
	if not ehMoeda(inst) then
		return
	end
	moedasSet[inst] = true
	table.insert(moedas, inst)

	if CONFIG.debugRemotes then
		print("[CoinFarm] moeda registrada: " .. inst:GetFullName())
	end
end

local function limparMoedas()
	for i = #moedas, 1, -1 do
		local m = moedas[i]
		if not m or not m.Parent then
			if m then
				moedasSet[m] = nil
				estado.coletadas[m] = nil
				estado.ignoradas[m] = nil
			end
			table.remove(moedas, i)
		end
	end
end

-- escolhe a melhor moeda: perto de mim e LONGE do murder.
-- Sem murder (ou sendo eu o murder), e a mais perto mesmo.
local function proximaMoeda()
	limparMoedas()

	local _, _, hrp = getRig()
	if not hrp then
		return nil
	end

	local origem = hrp.Position

	local posMurder = nil
	if estado.murder and estado.murder.Character then
		local mhrp = estado.murder.Character:FindFirstChild("HumanoidRootPart")
		if mhrp then
			posMurder = mhrp.Position
		end
	end

	local raio = CONFIG.raioPerigoMoeda or 45
	local peso = CONFIG.pesoMoedaLongeMurder or 2
	local melhor, melhorNota = nil, -math.huge

	for _, m in ipairs(moedas) do
		if moedaValida(m) then
			local okD, d = pcall(function()
				return (m.Position - origem).Magnitude
			end)

			if okD and d and d <= CONFIG.distanciaMaxima then
				-- comeca punindo a distancia ate mim (perto e bom)
				local nota = -d

				if posMurder then
					local okM, dM = pcall(function()
						return (m.Position - posMurder).Magnitude
					end)
					if okM and dM then
						-- longe do murder soma pontos
						nota = nota + math.min(dM, 150) * peso
						-- perto do murder perde MUITO ponto
						if dM < raio then
							nota = nota - (raio - dM) * 5
						end
					end
				end

				if nota > melhorNota then
					melhor, melhorNota = m, nota
				end
			end
		end
	end

	return melhor
end

local function contarMoedasBoas()
	limparMoedas()

	local _, _, hrp = getRig()
	local origem = hrp and hrp.Position or nil
	local total = 0

	for _, m in ipairs(moedas) do
		if moedaValida(m) then
			if not origem then
				total = total + 1
			else
				local ok, d = pcall(function()
					return (m.Position - origem).Magnitude
				end)
				if ok and d and d <= CONFIG.distanciaMaxima then
					total = total + 1
				end
			end
		end
	end

	return total
end

-- tem alguma moeda de verdade (visivel e valida) dentro do raio?
local function temMoedaPerto(distMax)
	local _, _, hrp = getRig()
	if not hrp then
		return false
	end

	local origem = hrp.Position
	local limite = distMax or CONFIG.distanciaMaxima

	for _, m in ipairs(moedas) do
		if moedaValida(m) then
			local ok, d = pcall(function()
				return (m.Position - origem).Magnitude
			end)
			if ok and d and d <= limite then
				return true
			end
		end
	end

	return false
end

--=============================================================================
-- 7.1) CONTADOR DE MOEDAS DO JOGO (leaderstats / atributo / ProfileData)
--=============================================================================
-- O script conta as moedas que ele mesmo confirma, mas o ideal e ler o numero
-- do proprio jogo. Fontes, em ordem:
--   1) leaderstats (IntValue/NumberValue com nome de moeda)
--   2) atributo do Player
--   3) ReplicatedStorage.Modules.ProfileData (a tabela viva que o jogo usa)
--   (e o GetProfileData/RemoteEvents aparecem no F9 com debugRemotes = true)
local contadorJogo = nil

local PADROES_CONTADOR = { "coin", "moeda", "currency", "cash", "candy", "candie" }

local function caminhoEhContador(caminho)
	local n = string.lower(caminho)
	for _, p in ipairs(PADROES_CONTADOR) do
		if string.find(n, p, 1, true) then
			return true
		end
	end
	return false
end

local function scanMoedasNaTabela(tbl, depth, prefixo, achados, visitados)
	if type(tbl) ~= "table" or depth > 4 then
		return
	end
	if visitados[tbl] then
		return
	end
	visitados[tbl] = true

	for k, v in pairs(tbl) do
		if type(k) == "string" then
			local caminho = prefixo .. k

			if type(v) == "number" then
				if caminhoEhContador(caminho) then
					achados[#achados + 1] = {
						caminho = caminho,
						tabela = tbl,
						chave = k,
					}
				end
			elseif type(v) == "table" then
				scanMoedasNaTabela(v, depth + 1, caminho .. ".", achados, visitados)
			end
		end
	end
end

local function requireSeguro(inst)
	if not inst or not inst:IsA("ModuleScript") then
		return nil
	end
	local ok, res = pcall(require, inst)
	if ok and type(res) == "table" then
		return res
	end
	return nil
end

local function acharPerfil()
	local rs = game:GetService("ReplicatedStorage")

	local mods = rs:FindFirstChild("Modules")
	if mods then
		local p = requireSeguro(mods:FindFirstChild("ProfileData"))
		if p then
			return p
		end
	end

	local p = requireSeguro(rs:FindFirstChild("ProfileData"))
	if p then
		return p
	end

	local ms = rs:FindFirstChild("ModuleScripts")
	if ms then
		p = requireSeguro(ms:FindFirstChild("ProfileData"))
		if p then
			return p
		end
	end

	-- fallback: qualquer ModuleScript com "profile"/"playerdata" no nome
	local tentativas = 0
	for _, inst in ipairs(rs:GetDescendants()) do
		if inst:IsA("ModuleScript") and tentativas < 25 then
			local n = string.lower(inst.Name)
			if string.find(n, "profile", 1, true) or string.find(n, "playerdata", 1, true) then
				tentativas = tentativas + 1
				local res = requireSeguro(inst)
				if res then
					return res
				end
			end
		end
	end

	return nil
end

local function acharContadorJogo()
	-- 1) leaderstats
	local ls = LocalPlayer:FindFirstChild("leaderstats")
	if ls then
		for _, v in ipairs(ls:GetChildren()) do
			if (v:IsA("IntValue") or v:IsA("NumberValue"))
				and nomeCombinaLista(v.Name, CONFIG.padroesNome) then
				return { tipo = "valor", inst = v, nome = v.Name }
			end
		end
	end

	-- 2) atributo do Player
	local ok, attrs = pcall(function()
		return LocalPlayer:GetAttributes()
	end)
	if ok and type(attrs) == "table" then
		for nome, valor in pairs(attrs) do
			if type(valor) == "number" and nomeCombinaLista(nome, CONFIG.padroesNome) then
				return { tipo = "atributo", nome = nome }
			end
		end
	end

	-- 3) perfil ao vivo do jogo (a mesma tabela da GUI do MM2)
	local perfil = acharPerfil()
	if perfil then
		local achados = {}
		scanMoedasNaTabela(perfil, 1, "", achados, {})

		if #achados > 0 then
			-- prefere Candies (moeda do evento), depois Coins
			local melhor, melhorPeso = nil, -1
			for _, a in ipairs(achados) do
				local caminho = string.lower(a.caminho)
				local peso = 1
				if string.find(caminho, "candies", 1, true) or string.find(caminho, "candy", 1, true) then
					peso = 4
				elseif string.find(caminho, "coins", 1, true) then
					peso = 3
				elseif string.find(caminho, "coin", 1, true) then
					peso = 2
				end

				if peso > melhorPeso
					or (peso == melhorPeso and melhor and #a.caminho < #melhor.caminho) then
					melhor, melhorPeso = a, peso
				end
			end

			if melhor then
				return {
					tipo = "tabela",
					tabela = melhor.tabela,
					chave = melhor.chave,
					caminho = melhor.caminho,
				}
			end
		end
	end

	return nil
end

local function lerContadorJogo()
	if not contadorJogo then
		return nil
	end

	if contadorJogo.tipo == "atributo" then
		local ok, v = pcall(function()
			return LocalPlayer:GetAttribute(contadorJogo.nome)
		end)
		if ok and type(v) == "number" then
			return v
		end
		return nil
	end

	if contadorJogo.tipo == "valor" then
		local ok, v = pcall(function()
			return contadorJogo.inst.Value
		end)
		if ok and type(v) == "number" then
			return v
		end
		return nil
	end

	if contadorJogo.tipo == "tabela" then
		local ok, v = pcall(function()
			return contadorJogo.tabela[contadorJogo.chave]
		end)
		if ok and type(v) == "number" then
			return v
		end
		return nil
	end

	return nil
end

-- A "bolsa da partida" pelo contador do jogo e a DIFERENCA desde o comeco
-- (o jogo guarda o total; a partida e a variacao). Se o contador nunca mexer,
-- continua valendo a contagem do proprio script.
local function atualizarContadorJogo()
	local v = lerContadorJogo()

	if v == nil then
		estado.jogo = nil
		return
	end

	estado.jogo = v

	if estado.jogoBase == nil then
		estado.jogoBase = v
		return
	end

	local delta = v - estado.jogoBase
	if delta < 0 then
		estado.jogoBase = v
		delta = 0
	end

	if delta > 0 then
		estado.jogoMudou = true
	end

	if CONFIG.usarContadorJogo and estado.jogoMudou then
		estado.moedas = math.floor(delta + 0.5)
	end
end

-- o jogo manda ChangeInventoryItem("Materials", "Candies2026", novoTotal) a
-- cada moeda: e o contador mais direto que existe (o log do espiao mostrou)
local function hookarContadorPorRemote()
	local rs = game:GetService("ReplicatedStorage")

	for _, inst in ipairs(rs:GetDescendants()) do
		if inst:IsA("RemoteEvent") and string.lower(inst.Name) == "changeinventoryitem" then
			pcall(function()
				inst.OnClientEvent:Connect(function(material, item, total)
					if type(total) ~= "number" then
						return
					end

					local alvo = string.lower(tostring(material)) .. " " .. string.lower(tostring(item))
					if not (string.find(alvo, "candie", 1, true) or string.find(alvo, "coin", 1, true)) then
						return
					end

					if estado.jogoBase == nil then
						estado.jogoBase = total
						estado.jogo = total
						return
					end

					local delta = total - estado.jogoBase
					if delta < 0 then
						estado.jogoBase = total
						delta = 0
					end

					estado.jogo = total
					if delta > 0 then
						estado.jogoMudou = true
					end
					if CONFIG.usarContadorJogo and estado.jogoMudou then
						estado.moedas = math.floor(delta + 0.5)
					end
				end)
			end)
			print("[Farm+Guarda] contador via remote: " .. inst:GetFullName())
			return
		end
	end
end

-- sniffer opcional: mostra no F9 os remotes de moeda que o jogo dispara
local function farejarRemotes()
	if not CONFIG.debugRemotes then
		return
	end

	local rs = game:GetService("ReplicatedStorage")

	for _, inst in ipairs(rs:GetDescendants()) do
		if inst:IsA("RemoteEvent") then
			local n = string.lower(inst.Name)
			local interessante = string.find(n, "coin", 1, true)
				or string.find(n, "moeda", 1, true)
				or string.find(n, "collect", 1, true)
				or string.find(n, "reward", 1, true)
			if interessante then
				print("[CoinFarm][remote] encontrado: " .. inst:GetFullName())
				pcall(function()
					inst.OnClientEvent:Connect(function(...)
						local args = { ... }
						local partes = {}
						for i = 1, math.min(#args, 4) do
							partes[#partes + 1] = tostring(args[i])
						end
						print("[CoinFarm][remote] " .. inst.Name .. " -> " .. table.concat(partes, ", "))
					end)
				end)
			end
		end
	end
end

--=============================================================================
-- 8) MARCA DO ALVO (moeda vermelha + linha)
--=============================================================================
local marca = {
	moeda = nil,
	highlight = nil,
	selection = nil,
	beam = nil,
	attPersonagem = nil,
	attMoeda = nil,
}

local function limparMarca()
	if marca.highlight then
		pcall(function()
			marca.highlight:Destroy()
		end)
	end
	if marca.selection then
		pcall(function()
			marca.selection:Destroy()
		end)
	end
	if marca.beam then
		pcall(function()
			marca.beam:Destroy()
		end)
	end
	if marca.attPersonagem then
		pcall(function()
			marca.attPersonagem:Destroy()
		end)
	end
	if marca.attMoeda then
		pcall(function()
			marca.attMoeda:Destroy()
		end)
	end
	marca.moeda = nil
	marca.highlight = nil
	marca.selection = nil
	marca.beam = nil
	marca.attPersonagem = nil
	marca.attMoeda = nil
end

-- acha a peca que realmente aparece na tela (a moeda pode ser um hitbox
-- invisivel com um CoinVisual visivel dentro)
local function parteVisivelDentro(moeda)
	local ok, t = pcall(function()
		return moeda.Transparency
	end)
	if ok and (t or 0) < 0.99 then
		return moeda
	end

	local okD, desc = pcall(function()
		return moeda:GetDescendants()
	end)
	if okD then
		for _, d in ipairs(desc) do
			if d:IsA("BasePart") then
				local ok2, t2 = pcall(function()
					return d.Transparency
				end)
				if ok2 and (t2 or 0) < 0.99 then
					return d
				end
			end
		end
	end

	return moeda
end

local function marcarAlvo(moeda)
	limparMarca()

	local _, _, hrp = getRig()
	if not hrp or not moeda or not moeda.Parent then
		return
	end

	local cor = Color3.fromRGB(255, 45, 45)
	local adornado = parteVisivelDentro(moeda)

	local okHighlight = pcall(function()
		local h = Instance.new("Highlight")
		h.Name = "FarmAlvo"
		h.FillColor = cor
		h.FillTransparency = 0.35
		h.OutlineColor = cor
		h.OutlineTransparency = 0
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.Adornee = adornado
		h.Parent = adornado
		marca.highlight = h
	end)

	if not okHighlight then
		pcall(function()
			local box = Instance.new("SelectionBox")
			box.Name = "FarmAlvo"
			box.Adornee = adornado
			box.Color3 = cor
			box.LineThickness = 0.06
			box.SurfaceTransparency = 0.85
			box.Parent = adornado
			marca.selection = box
		end)
	end

	pcall(function()
		local a1 = Instance.new("Attachment")
		a1.Name = "FarmPonta"
		a1.Parent = hrp

		local a2 = Instance.new("Attachment")
		a2.Name = "FarmPonta"
		a2.Parent = adornado

		local beam = Instance.new("Beam")
		beam.Name = "FarmLinha"
		beam.Attachment0 = a1
		beam.Attachment1 = a2
		beam.Color = ColorSequence.new(cor)
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.Width0 = 0.06
		beam.Width1 = 0.06
		beam.Segments = 1
		beam.CurveSize0 = 0
		beam.CurveSize1 = 0
		beam.FaceCamera = true
		beam.Parent = hrp

		marca.beam = beam
		marca.attPersonagem = a1
		marca.attMoeda = a2
	end)

	marca.moeda = moeda
end

--=============================================================================
-- 9) VOO
--=============================================================================
local vooToken = 0

local function cframeAlvo(posicao, baseCF)
	local flat = Vector3.new(posicao.X - baseCF.Position.X, 0, posicao.Z - baseCF.Position.Z)
	if flat.Magnitude > 2 then
		return CFrame.lookAt(posicao, posicao + flat.Unit)
	end
	return CFrame.new(posicao) * (baseCF - baseCF.Position)
end

local function segurar(cf, duracao)
	local char = LocalPlayer.Character
	local t0 = os.clock()
	while os.clock() - t0 < duracao do
		if LocalPlayer.Character ~= char then
			return
		end
		local _, _, hrp = getRig()
		if not hrp then
			return
		end
		-- servidor teleportou? larga o personagem
		if (hrp.Position - cf.Position).Magnitude > (CONFIG.limiteTeleporte or 40) then
			return
		end
		pcall(function()
			hrp.CFrame = cf
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end)
		task.wait()
	end
end

-- o murder esta na linha de visao? parede no meio = nao
local function temVisaoDoMurder(hrp, murder)
	if not CONFIG.usarVisao then
		return true
	end
	if not hrp or not murder then
		return false
	end

	local char = murder.Character
	if not char then
		return false
	end

	local mhrp = char:FindFirstChild("HumanoidRootPart")
	if not mhrp then
		return false
	end

	local origem = hrp.Position + Vector3.new(0, 1.2, 0)
	local alvo = mhrp.Position + Vector3.new(0, 1.2, 0)

	local params = RaycastParams.new()
	pcall(function()
		params.FilterType = Enum.RaycastFilterType.Exclude
	end)
	params.FilterDescendantsInstances = { char, LocalPlayer.Character }
	pcall(function()
		params.IgnoreWater = true
	end)

	local resultado = safe(function()
		return Workspace:Raycast(origem, alvo - origem, params)
	end)

	if not resultado then
		return true
	end

	-- moeda/efeito no meio do caminho nao conta como parede
	if nomeCombina(resultado.Instance.Name) then
		return true
	end

	return false
end

local function perigoAgora()
	if not estado.guarda or estado.souMurder or not estado.murder then
		return false
	end
	if estado.mesmaAltura ~= true then
		return false
	end
	if estado.dist > CONFIG.distanciaPerigo then
		return false
	end

	-- colado nele: foge mesmo com parede no meio (pode virar a esquina)
	if estado.dist <= (CONFIG.distanciaPerigoCega or 15) then
		return true
	end

	-- de longe so foge se estiver vendo ele (sem parede)
	return estado.temVisao == true
end

-- predicado opcional: se devolver false no meio, o voo aborta
-- opcoes: { velocidade = number, disparado = true }  (disparado = arranque)
local function voarPara(destino, predicado, opcoes)
	opcoes = opcoes or {}

	local _, hum, hrp = getRig()
	if not hrp or not destino then
		return false
	end

	vooToken = vooToken + 1
	local meuToken = vooToken

	local inicio = hrp.CFrame
	local dist = (destino.Position - inicio.Position).Magnitude
	if dist < 0.4 then
		pcall(function()
			hrp.CFrame = destino
		end)
		return true
	end

	local vel = math.max(tonumber(opcoes.velocidade or CONFIG.velocidade) or 30, 1)
	if not opcoes.velocidade then
		vel = vel * (1 + (math.random() * 2 - 1) * (CONFIG.variacaoVelocidade or 0))
	end
	local tempo = math.max(dist / vel, 0.05)

	prepararVoo(hum, hrp)

	local ultimo = inicio
	local t0 = os.clock()
	while true do
		if vooToken ~= meuToken or not estado.ativo then
			return false
		end
		if predicado and not predicado() then
			return false
		end

		-- o servidor teleportou no meio do voo? aceita e aborta (nunca puxa
		-- o personagem de volta pro mapa antigo)
		if (hrp.Position - ultimo.Position).Magnitude > (CONFIG.limiteTeleporte or 40) then
			return false
		end

		local a = (os.clock() - t0) / tempo
		if a >= 1 then
			break
		end

		local suave
		if opcoes.disparado then
			-- arranque: sai na velocidade maxima e alivia perto do fim
			suave = 1 - (1 - a) * (1 - a)
		else
			suave = a * a * (3 - 2 * a)
		end

		local alvoCF = inicio:Lerp(destino, suave)

		local ok = pcall(function()
			hrp.CFrame = alvoCF
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end)
		if not ok then
			break
		end
		ultimo = alvoCF
		task.wait()
	end

	pcall(function()
		hrp.CFrame = destino
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end)

	return true
end

local function voarAteAlvo(moeda)
	local _, _, hrp = getRig()
	if not hrp or not moeda then
		return false
	end

	local destino = cframeAlvo(moeda.Position + Vector3.new(0, CONFIG.alturaAproximacao, 0), hrp.CFrame)

	return voarPara(destino, function()
		return moedaExiste(moeda)
			and moedaVisivel(moeda)
			and estado.farmLigado
			and not estado.resetando
			and estado.emPartida
			and not perigoAgora()
	end)
end

--=============================================================================
-- 10) COLETA
--=============================================================================
local function encostarMoeda(moeda, duracao)
	local char = LocalPlayer.Character
	local t0 = os.clock()

	while os.clock() - t0 < duracao do
		if not moedaExiste(moeda) or LocalPlayer.Character ~= char then
			return
		end
		local _, _, hrp = getRig()
		if not hrp then
			return
		end
		-- se o servidor me teleportou, nao puxa de volta pra moeda
		if (hrp.Position - moeda.Position).Magnitude > (CONFIG.limiteTeleporte or 40) then
			return
		end
		pcall(function()
			hrp.CFrame = CFrame.new(moeda.Position) * (hrp.CFrame - hrp.CFrame.Position)
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end)
		task.wait()
	end
end

local fti = firetouchinterest

-- devolve:
--   "coletada" = sumiu enquanto eu encostava (CONTA como minha)
--   "pendente" = encostei e ela ainda esta la (confirma no grace period)
--   "sumiu"    = ja nao existia antes de eu encostar (outro pegou, NAO conta)
local function coletar(moeda)
	if not moedaExiste(moeda) or not moedaValida(moeda) then
		return "sumiu"
	end

	local antes = moeda.Position
	local tentativas = 1 + math.max(CONFIG.retentativas or 0, 0)

	for i = 1, tentativas do
		if not estado.ativo or not estado.farmLigado or estado.resetando then
			return "pendente"
		end

		local _, _, hrp = getRig()
		if not hrp then
			return "pendente"
		end
		if not moedaExiste(moeda) then
			return "coletada"
		end

		if CONFIG.usarFiretouch and type(fti) == "function" then
			pcall(function()
				fti(hrp, moeda, 0)
				fti(hrp, moeda, 1)
			end)
		end

		encostarMoeda(moeda, CONFIG.esperaColeta)

		if not moedaExiste(moeda) then
			return "coletada"
		end
		if not moedaValida(moeda) then
			return "coletada"
		end

		-- moeda que "renasce" em outro lugar tambem foi coletada
		local okMudou, mudou = pcall(function()
			return (moeda.Position - antes).Magnitude > 3
		end)
		if okMudou and mudou then
			return "coletada"
		end
	end

	return "pendente"
end

--=============================================================================
-- 11) TRAVA ESTATICA
--=============================================================================
local travaConn = nil

local function soltarTrava()
	estado.travado = false
	estado.modoDePe = false
	estado.posTrava = nil
	if travaConn then
		pcall(function()
			travaConn:Disconnect()
		end)
		travaConn = nil
	end
end

local function travarEm(cf)
	soltarTrava()

	estado.posTrava = cf
	estado.travado = true

	local chao = acharChaoAbaixo(cf.Position)
	if chao and (cf.Position.Y - chao.Y) <= 6 then
		-- no chao: fica DE PE, com colisao normal
		estado.modoDePe = true
		estado.noclipLigado = false
		restaurarColisao()
		devolverControle()
	else
		-- no ar: fica travado flutuando (noclip + Physics)
		estado.modoDePe = false
		estado.noclipLigado = CONFIG.usarNoclip
		local _, humAgora, hrpAgora = getRig()
		prepararVoo(humAgora, hrpAgora)
	end

	-- Stepped roda ANTES da fisica e depois de aplicar o que veio do servidor:
	-- se o servidor teleportou, da pra ver o pulo e soltar a trava antes de
	-- reescrever a posicao antiga.
	travaConn = RunService.Stepped:Connect(function()
		if not estado.travado or not estado.posTrava then
			return
		end
		local _, _, hrp = getRig()
		if not hrp then
			return
		end

		-- SE O SERVIDOR TELEPORTOU (entrar no mapa, trocar de partida), aceita
		-- o lugar novo e solta a trava. NUNCA puxa de volta pro lugar antigo.
		local d = (hrp.Position - estado.posTrava.Position).Magnitude
		if d > (CONFIG.limiteTeleporte or 40) then
			soltarTrava()
			estado.situacao = "teleporte do servidor - trava solta"
			return
		end

		pcall(function()
			hrp.CFrame = estado.posTrava
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end)
	end)
end

local function soltarControle()
	soltarTrava()
	estado.noclipLigado = false
	restaurarColisao()
	devolverControle()
end

-- devolve o personagem ao normal se ele estiver preso (plataform stand,
-- estado Physics ou noclip). Importante no lobby: personagem "preso" pode
-- atrapalhar o servidor de te teleportar pra partida.
local function garantirControleNormal(hum)
	if estado.travado or estado.noclipLigado then
		soltarControle()
		return
	end
	if not hum then
		return
	end
	if hum.PlatformStand then
		soltarControle()
		return
	end
	local ok, st = pcall(function()
		return hum:GetState()
	end)
	if ok and st == Enum.HumanoidStateType.Physics then
		soltarControle()
	end
end

--=============================================================================
-- 12) BOLSA CHEIA -> RESET
--=============================================================================
-- valor usado pra bolsa: o do jogo (delta) quando disponivel; senao o script
local function valorBolsa()
	if CONFIG.usarContadorJogo and estado.jogoMudou
		and estado.jogo and estado.jogoBase then
		local v = estado.jogo - estado.jogoBase
		if v < 0 then
			v = 0
		end
		return v
	end
	return estado.moedas
end

local function bolsaCheia()
	local cap = CONFIG.capacidadeBolsa or 0
	if cap <= 0 then
		return false
	end
	return valorBolsa() >= cap
end

local function resetar(motivo)
	if estado.resetando or estado.fugindo then
		return
	end

	-- REGRA DE OURO: como murder nunca reseta, fica estatico
	if estado.souMurder then
		estado.situacao = "sou o murder - nao reseto"
		return
	end

	-- se o murder esta perto, resolver a fuga primeiro
	if perigoAgora() then
		return
	end

	estado.resetando = true
	estado.situacao = "bolsa cheia - resetando"
	log("resetando (" .. tostring(motivo) .. ") - bolsa: " .. tostring(estado.moedas))

	estado.alvo = nil
	limparMarca()
	soltarControle()

	local charAntes = LocalPlayer.Character

	pcall(function()
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Health = 0
		end
	end)

	pcall(function()
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			char:BreakJoints()
		end
	end)

	-- espera o personagem NOVO nascer (nao basta a vida antiga sumir)
	local t0 = os.clock()
	while estado.ativo and (os.clock() - t0) < (CONFIG.resetEspera + 6) do
		local char, hum2 = getRig()
		if char and char ~= charAntes and hum2 and hum2.Health > 0 then
			break
		end
		task.wait(0.25)
	end

	estado.moedas = 0
	estado.jogoBase = nil
	estado.jogoMudou = false
	estado.coletadas = {}
	estado.ignoradas = {}
	estado.pendentes = {}
	estado.semMoedaDesde = os.clock()
	estado.resetando = false
	estado.situacao = "renasceu - retomando"
end

-- conta UMA moeda na bolsa (so quando a coleta foi confirmada)
local function contarMoeda()
	estado.moedas = estado.moedas + 1
	estado.total = estado.total + 1
end

-- partida acabou (lobby/intervalo): a bolsa da partida zera, porque o proximo
-- round comeca a contar do zero
local function zerarBolsa()
	estado.moedas = 0
	estado.jogoBase = nil
	estado.jogoMudou = false
	estado.coletadas = {}
	estado.ignoradas = {}
	estado.pendentes = {}
end

-- moeda que encostamos mas nao sumiu na hora: conta so se ela sumir dentro do
-- grace period. Se nao sumir, desiste (nao conta) - evita contar moeda que
-- sumiu sozinha no fim da partida.
local function verificarPendentes()
	local agora = os.clock()
	local grace = CONFIG.graceColeta or 2.5

	for moeda, info in pairs(estado.pendentes) do
		local t = (type(info) == "table" and info.t) or agora

		if (agora - t) > grace then
			estado.ignoradas[moeda] = true
			estado.pendentes[moeda] = nil
		elseif not moedaExiste(moeda) then
			estado.pendentes[moeda] = nil
			estado.coletadas[moeda] = agora
			contarMoeda()
		elseif type(info) == "table" and info.pos then
			-- moeda que se moveu (renasceu) tambem conta
			local ok, mudou = pcall(function()
				return (moeda.Position - info.pos).Magnitude > 3
			end)
			if ok and mudou then
				estado.pendentes[moeda] = nil
				estado.coletadas[moeda] = agora
				contarMoeda()
			end
		end
	end
end

--=============================================================================
-- 13) FUGA
--=============================================================================
local function destinoDeFuga(hrp, murder)
	local minha = hrp.Position
	local dir = nil

	local mhrp = murder and murder.Character and murder.Character:FindFirstChild("HumanoidRootPart")
	if mhrp then
		local d = Vector3.new(minha.X - mhrp.Position.X, 0, minha.Z - mhrp.Position.Z)
		if d.Magnitude >= 1 then
			dir = d.Unit
		end
	end

	if not dir then
		local ang = math.random() * math.pi * 2
		dir = Vector3.new(math.cos(ang), 0, math.sin(ang))
	end

	local alvo = minha
		+ dir * CONFIG.distanciaFuga
		+ Vector3.new(0, CONFIG.subidaFuga, 0)

	return CFrame.lookAt(alvo, alvo + dir)
end

local function fugir(murder)
	if estado.fugindo or estado.resetando then
		return
	end

	estado.fugindo = true
	estado.ultimaFuga = os.clock()
	estado.situacao = "fugindo do murder"

	soltarTrava()
	estado.noclipLigado = CONFIG.usarNoclip

	local _, hum, hrp = getRig()
	if not hrp then
		estado.fugindo = false
		return
	end
	prepararVoo(hum, hrp)

	local destino = destinoDeFuga(hrp, murder)
	voarPara(destino, function()
		return estado.guarda and not estado.souMurder
	end, {
		velocidade = CONFIG.velocidadeFuga,
		disparado = true,
	})

	local _, _, hrpNovo = getRig()
	if hrpNovo and estado.guarda then
		travarEm(hrpNovo.CFrame)
		estado.situacao = "estatico (longe do murder)"
	end

	estado.fugindo = false
end

--=============================================================================
-- 14) PASSO DO FARM (um ciclo)
--=============================================================================
local function passoFarm(hum, hrp)
	if estado.resetando then
		return
	end

	-- 0) LOBBY: as moedas do mapa continuam no Workspace, mas sao de outro
	-- lugar (longe e/ou invisiveis). Nao voa atras delas e NAO TRAVA: trava
	-- no lobby faz o servidor nao conseguir te teleportar pro mapa.
	if not estado.emPartida then
		estado.alvo = nil
		limparMarca()
		garantirControleNormal(hum)
		estado.situacao = "lobby/intermission - esperando a partida"
		return
	end

	-- 1) bolsa cheia -> reseta (so durante a partida, nao no lobby)
	if bolsaCheia() then
		resetar("bolsa cheia")
		return
	end

	local moeda = proximaMoeda()

	if moeda then
		estado.semMoedaDesde = os.clock()

		-- checagem dupla: se outro jogador pegou a moeda nesse meio tempo,
		-- nem sai voando pra um lugar vazio
		task.wait(0.12)
		if not estado.farmLigado or not estado.emPartida then
			return
		end
		if not moedaExiste(moeda) or not moedaValida(moeda) then
			estado.coletadas[moeda] = os.clock()
			return
		end

		soltarTrava()
		estado.noclipLigado = CONFIG.usarNoclip
		estado.alvo = moeda
		marcarAlvo(moeda)
		estado.situacao = "voando ate a moeda"

		local chegou = voarAteAlvo(moeda)

		if estado.ativo and estado.farmLigado then
			if chegou then
				if moedaExiste(moeda) and moedaValida(moeda) then
					estado.situacao = "coletando"
					local resultado = coletar(moeda)

					if resultado == "coletada" then
						contarMoeda()
					elseif resultado == "pendente" then
						-- encostei mas ela ainda nao sumiu: confirma no grace
						estado.pendentes[moeda] = { t = os.clock(), pos = moeda.Position }
					end
				end

				estado.coletadas[moeda] = os.clock()
			elseif not moedaExiste(moeda) then
				-- sumiu no meio do voo: ja era de alguem
				estado.coletadas[moeda] = os.clock()
			end
		end

		estado.alvo = nil
		limparMarca()

		if estado.farmLigado and bolsaCheia() then
			resetar("bolsa cheia")
		end
		return
	end

	-- 2) sem moeda nenhuma
	estado.alvo = nil
	limparMarca()

	if not estado.travado then
		travarEm(hrp.CFrame)
	end

	local parado = os.clock() - estado.semMoedaDesde

	if parado >= CONFIG.tempoSemMoeda then
		-- SEM moeda NAO quer dizer bolsa cheia: pode ser intervalo entre
		-- partidas, lobby, ou a partida acabou. So reseta se a contagem
		-- realmente chegou no limite da bolsa.
		if bolsaCheia() then
			resetar("bolsa cheia")
		else
			estado.situacao = "intervalo/lobby - esperando a partida"
		end
	else
		estado.situacao = "procurando moedas"
		segurar(hrp.CFrame, 0.15)
	end
end

--=============================================================================
-- 15) MONITOR DO MURDER (roda separado pra nao travar durante o voo)
--=============================================================================
local function monitorMurder()
	while estado.ativo do
		local ok, murder, arma = pcall(varrerPapeis)
		if ok then
			estado.murder = murder
			estado.temArma = arma == true
		end
		estado.souMurder = souMurder()

		-- PARTIDA DE VERDADE? tem faca, tem arma do xerife, eu sou o murder,
		-- ou tem moeda de verdade (visivel e valida) perto de mim.
		-- No lobby/intermission nada disso acontece.
		estado.emPartida = (murder ~= nil)
			or estado.souMurder
			or estado.temArma
			or temMoedaPerto(CONFIG.distanciaMaxima)

		-- ficou tempo suficiente fora de partida = a partida anterior acabou:
		-- zera a bolsa pra proxima comecar do zero
		if estado.emPartida then
			estado.semPartidaDesde = nil
			estado.bolsaZerada = false
		else
			if estado.semPartidaDesde == nil then
				estado.semPartidaDesde = os.clock()
			end
			if not estado.bolsaZerada
				and (os.clock() - estado.semPartidaDesde) >= (CONFIG.tempoLobby or 5) then
				zerarBolsa()
				estado.bolsaZerada = true
				log("fora de partida: bolsa zerada (a proxima comeca do zero)")
			end
		end

		if murder then
			aplicarDestaque(murder)

			local mhrp = murder.Character and murder.Character:FindFirstChild("HumanoidRootPart")
			local _, _, hrp = getRig()
			if mhrp and hrp then
				local delta = hrp.Position - mhrp.Position
				estado.dist = delta.Magnitude
				estado.distVertical = math.abs(delta.Y)
				-- murder no andar de baixo/cima NAO conta como perto
				estado.mesmaAltura = estado.distVertical <= (CONFIG.alturaPerigo or 12)
				estado.temVisao = temVisaoDoMurder(hrp, murder)
			else
				estado.dist = math.huge
				estado.distVertical = math.huge
				estado.mesmaAltura = false
				estado.temVisao = false
			end
		else
			limparDestaque()
			estado.dist = math.huge
			estado.distVertical = math.huge
			estado.mesmaAltura = false
			estado.temVisao = false
		end

		task.wait(0.15)
	end
end

--=============================================================================
-- 16) LOOP PRINCIPAL
--=============================================================================
local function loopPrincipal()
	while estado.ativo do
		local _, hum, hrp = getRig()

		if not hrp then
			estado.situacao = "sem personagem (morto/lobby)"
			task.wait(0.4)
		elseif estado.resetando then
			task.wait(0.2)
		else
			local perto = perigoAgora()

			if perto then
				-- PERIGO: sai disparado e, se continuar perto, repete a fuga
				estado.ultimoPerigo = os.clock()
				fugir(estado.murder)
			elseif estado.farmLigado then
				if estado.souMurder and bolsaCheia() then
					-- murder com a bolsa cheia: NAO reseta (regra), entao fica
					-- estatico ate a partida acabar
					estado.semMoedaDesde = os.clock()
					if not estado.travado then
						travarEm(hrp.CFrame)
					end
					estado.situacao = "bolsa cheia (murder) - estatico, sem reset"
				else
					passoFarm(hum, hrp)
				end
			else
				if estado.guarda and CONFIG.estatico and estado.emPartida then
					-- em partida pode travar: e a "base estatica" de verdade
					if not estado.travado then
						travarEm(hrp.CFrame)
					end
					estado.situacao = "estatico (farm desligado)"
				else
					-- no lobby NAO trava: senao o servidor nao te teleporta
					-- pro mapa quando a partida comeca
					garantirControleNormal(hum)
					if not estado.guarda and not estado.farmLigado then
						estado.situacao = "livre (tudo desligado)"
					else
						estado.situacao = "lobby/intermission - esperando a partida"
					end
				end
			end
		end

		task.wait(0.1)
	end
end

--=============================================================================
-- 17) LIGAR / DESLIGAR / UI
--=============================================================================
local function refresh()
	if not Ui.frame then
		return
	end

	local noMapa = contarMoedasBoas()

	if Ui.status then
		Ui.status.Text = estado.situacao
		if estado.resetando or estado.fugindo then
			Ui.status.TextColor3 = VERMELHO
		elseif estado.travado then
			Ui.status.TextColor3 = VERDE
		elseif estado.farmLigado then
			Ui.status.TextColor3 = LARANJA
		else
			Ui.status.TextColor3 = TEXT_DIM
		end
	end

	if Ui.info then
		local cap = (CONFIG.capacidadeBolsa or 0) > 0
			and tostring(CONFIG.capacidadeBolsa)
			or "inf"

		local murderTxt = "nenhum"
		if estado.murder then
			if estado.dist and estado.dist < math.huge then
				murderTxt = string.format("%s - %d studs", estado.murder.Name, math.floor(estado.dist + 0.5))
			else
				murderTxt = estado.murder.Name
			end
			if not estado.mesmaAltura then
				murderTxt = murderTxt .. " (outro andar)"
			elseif not estado.temVisao then
				murderTxt = murderTxt .. " (parede)"
			end
		elseif estado.souMurder then
			murderTxt = "VOCE (nao reseta)"
		end

		local linha1 = string.format("mapa: %d   bolsa: %d/%s", noMapa,
			math.floor(valorBolsa() + 0.5), cap)
		if estado.jogo ~= nil then
			linha1 = linha1 .. string.format("   jogo: %d", math.floor(estado.jogo + 0.5))
		end

		Ui.info.Text = linha1
			.. "\nfarm: " .. (estado.farmLigado and "ON" or "off")
			.. "   guarda: " .. (estado.guarda and "ON" or "off")
			.. "   partida: " .. (estado.emPartida and "SIM" or "NAO")
			.. "\nmurder: " .. murderTxt

		if estado.souMurder then
			Ui.info.TextColor3 = LARANJA
		elseif estado.murder and estado.dist <= CONFIG.distanciaPerigo then
			Ui.info.TextColor3 = VERMELHO
		elseif estado.murder and estado.dist <= CONFIG.distanciaPerigo * 2 then
			Ui.info.TextColor3 = LARANJA
		else
			Ui.info.TextColor3 = NEON
		end
	end

	if Ui.velocidade then
		Ui.velocidade.Text = string.format("%d studs/s", math.floor(CONFIG.velocidade + 0.5))
	end

	if Ui.bFarm then
		if estado.farmLigado then
			Ui.bFarm.Text = "AUTO FARM: DESLIGAR"
			Ui.bFarm.BackgroundColor3 = VERMELHO
			Ui.bFarm.TextColor3 = TEXT
		else
			Ui.bFarm.Text = "AUTO FARM: LIGAR"
			Ui.bFarm.BackgroundColor3 = VERDE
			Ui.bFarm.TextColor3 = Color3.fromRGB(8, 30, 22)
		end
	end

	if Ui.bGuarda then
		if estado.guarda then
			Ui.bGuarda.Text = "GUARDA: DESLIGAR"
			Ui.bGuarda.BackgroundColor3 = VERMELHO
			Ui.bGuarda.TextColor3 = TEXT
		else
			Ui.bGuarda.Text = "GUARDA: LIGAR"
			Ui.bGuarda.BackgroundColor3 = NEON
			Ui.bGuarda.TextColor3 = Color3.fromRGB(8, 30, 22)
		end
	end

	if Ui.bolha then
		if estado.farmLigado then
			Ui.bolha.BackgroundColor3 = VERDE
		elseif estado.guarda then
			Ui.bolha.BackgroundColor3 = NEON
		else
			Ui.bolha.BackgroundColor3 = CINZA
		end
	end
end

local function ligarFarm()
	if estado.farmLigado then
		return
	end

	local _, hum, hrp = getRig()
	if not hrp then
		aviso("Farm", "Seu personagem ainda nao nasceu.", 4)
		return
	end

	estado.farmLigado = true
	estado.semMoedaDesde = os.clock()
	estado.situacao = "farm ligado"

	soltarTrava()
	estado.noclipLigado = CONFIG.usarNoclip
	prepararVoo(hum, hrp)

	refresh()
end

local function desligarFarm()
	if not estado.farmLigado then
		return
	end

	estado.farmLigado = false
	estado.alvo = nil
	limparMarca()
	estado.situacao = "farm desligado"
	refresh()
end

local function ligarGuarda()
	estado.guarda = true
	refresh()
end

local function desligarGuarda()
	estado.guarda = false
	limparDestaque()

	-- se o farm nao manda no corpo, devolve o controle
	if not estado.farmLigado then
		soltarControle()
		estado.situacao = "guarda desligada"
	end

	refresh()
end

--=============================================================================
-- 18) CONSTRUCAO DA INTERFACE
--=============================================================================
local LARGURA = 244
local ALTURA  = 306

local function criar(classe, props, parent)
	local inst = Instance.new(classe)
	for k, v in pairs(props) do
		if k ~= "Parent" then
			inst[k] = v
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function canto(inst, raio)
	safe(function()
		criar("UICorner", { CornerRadius = UDim.new(0, raio or 8) }, inst)
	end)
end

local function contorno(inst)
	safe(function()
		criar("UIStroke", { Color = Color3.fromRGB(52, 52, 66), Thickness = 1 }, inst)
	end)
end

local function montar(gui)
	local pai = nil
	if type(gethui) == "function" then
		pai = safe(gethui)
	end
	if not pai then
		pai = safe(function()
			return game:GetService("CoreGui")
		end)
	end
	local ok = false
	if pai then
		ok = pcall(function()
			gui.Parent = pai
		end)
	end
	if not ok or not gui.Parent then
		gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
end

local function arrastavel(frame, alca)
	local arrastando = false
	local posInicial, inputInicial = nil, nil

	alca.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			arrastando = true
			inputInicial = input.Position
			posInicial = frame.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not arrastando then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - inputInicial
			local cam = Workspace.CurrentCamera
			local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
			local nx = math.clamp(posInicial.X.Offset + delta.X, -(LARGURA - 60), vp.X - 60)
			local ny = math.clamp(posInicial.Y.Offset + delta.Y, 0, vp.Y - 40)
			frame.Position = UDim2.new(posInicial.X.Scale, nx, posInicial.Y.Scale, ny)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			arrastando = false
		end
	end)
end

local function mudarVisivel(visivel)
	if not Ui.frame then
		return
	end
	Ui.frame.Visible = visivel
	if Ui.bolha then
		Ui.bolha.Visible = not visivel
	end
end

local function construir()
	local screen = criar("ScreenGui", {
		Name = "FarmGuarda",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	})
	montar(screen)
	Ui.screen = screen

	local bolha = criar("TextButton", {
		Name = "Bolha",
		Text = "FG",
		Size = UDim2.new(0, 46, 0, 46),
		Position = UDim2.new(0, 24, 0.3, 0),
		BackgroundColor3 = CINZA,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = TEXT,
		Visible = false,
	}, screen)
	canto(bolha, 23)
	contorno(bolha)
	Ui.bolha = bolha
	bolha.MouseButton1Click:Connect(function()
		mudarVisivel(true)
	end)

	local frame = criar("Frame", {
		Name = "Painel",
		Size = UDim2.new(0, LARGURA, 0, ALTURA),
		Position = UDim2.new(0, 24, 0.25, 0),
		BackgroundColor3 = BG,
		BorderSizePixel = 0,
		Active = true,
	}, screen)
	canto(frame, 12)
	contorno(frame)
	Ui.frame = frame

	local barra = criar("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = BG2,
		BorderSizePixel = 0,
	}, frame)
	canto(barra, 12)
	criar("Frame", {
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 0, 1, -14),
		BackgroundColor3 = BG2,
		BorderSizePixel = 0,
	}, barra)

	criar("TextLabel", {
		Text = "FARM + GUARDA",
		Size = UDim2.new(1, -80, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = NEON,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, barra)

	local fechar = criar("TextButton", {
		Text = "X",
		Size = UDim2.new(0, 26, 0, 22),
		Position = UDim2.new(1, -32, 0.5, -11),
		BackgroundColor3 = Color3.fromRGB(60, 40, 46),
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(255, 170, 170),
	}, barra)
	canto(fechar, 6)
	fechar.MouseButton1Click:Connect(function()
		mudarVisivel(false)
	end)

	arrastavel(frame, barra)

	local content = criar("Frame", {
		Size = UDim2.new(1, 0, 1, -34),
		Position = UDim2.new(0, 0, 0, 34),
		BackgroundTransparency = 1,
	}, frame)

	Ui.status = criar("TextLabel", {
		Text = "carregando",
		Size = UDim2.new(0, 224, 0, 16),
		Position = UDim2.new(0, 10, 0, 4),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = TEXT_DIM,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, content)

	Ui.info = criar("TextLabel", {
		Text = "no mapa: 0",
		Size = UDim2.new(0, 224, 0, 52),
		Position = UDim2.new(0, 10, 0, 22),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextColor3 = NEON,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
	}, content)

	criar("TextLabel", {
		Text = "VELOCIDADE (studs/s)",
		Size = UDim2.new(0, 224, 0, 12),
		Position = UDim2.new(0, 10, 0, 78),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextColor3 = TEXT_DIM,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, content)

	local function botao(texto, x, y, w, h, cor)
		local b = criar("TextButton", {
			Text = texto,
			Size = UDim2.new(0, w, 0, h),
			Position = UDim2.new(0, x, 0, y),
			BackgroundColor3 = cor or CINZA,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextColor3 = TEXT,
		}, content)
		canto(b, 8)
		return b
	end

	local bMenos = botao("-", 10, 92, 34, 26)
	local bMais  = botao("+", 200, 92, 34, 26)

	Ui.velocidade = criar("TextLabel", {
		Text = "30 studs/s",
		Size = UDim2.new(0, 146, 0, 26),
		Position = UDim2.new(0, 49, 0, 92),
		BackgroundColor3 = BG2,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = TEXT,
	}, content)
	canto(Ui.velocidade, 8)

	Ui.bFarm = botao("AUTO FARM: LIGAR", 10, 122, 224, 44, VERDE)
	Ui.bFarm.TextColor3 = Color3.fromRGB(8, 30, 22)

	Ui.bGuarda = botao("GUARDA: DESLIGAR", 10, 170, 224, 36, VERMELHO)

	local bResetar = botao("RESETAR BOLSA", 10, 210, 224, 34)

	criar("TextLabel", {
		Text = "Celular: use os botoes  -  PC: RightShift / F2 / F3",
		Size = UDim2.new(0, 224, 0, 14),
		Position = UDim2.new(0, 10, 0, 250),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 9,
		TextColor3 = Color3.fromRGB(110, 110, 128),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, content)

	Ui.bFarm.MouseButton1Click:Connect(function()
		if estado.farmLigado then
			desligarFarm()
		else
			ligarFarm()
		end
		refresh()
	end)

	Ui.bGuarda.MouseButton1Click:Connect(function()
		if estado.guarda then
			desligarGuarda()
		else
			ligarGuarda()
		end
		refresh()
	end)

	bMenos.MouseButton1Click:Connect(function()
		CONFIG.velocidade = math.clamp(CONFIG.velocidade - 5, 12, 60)
		refresh()
	end)

	bMais.MouseButton1Click:Connect(function()
		CONFIG.velocidade = math.clamp(CONFIG.velocidade + 5, 12, 60)
		refresh()
	end)

	bResetar.MouseButton1Click:Connect(function()
		task.spawn(function()
			resetar("manual")
		end)
		refresh()
	end)

	refresh()

	task.spawn(function()
		while Ui.screen and Ui.screen.Parent do
			refresh()
			task.wait(0.4)
		end
	end)
end

--=============================================================================
-- 19) ANTI-AFK, ATALHOS, RENASCIMENTO E INICIO
--=============================================================================
if CONFIG.antiAfk and VirtualUser then
	pcall(function()
		LocalPlayer.Idled:Connect(function()
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end)
	end)
end

UserInputService.InputBegan:Connect(function(input, processado)
	if processado then
		return
	end

	if input.KeyCode == CONFIG.teclaPainel then
		if Ui.frame and Ui.frame.Visible then
			mudarVisivel(false)
		else
			mudarVisivel(true)
		end
	elseif input.KeyCode == CONFIG.teclaFarm then
		if estado.farmLigado then
			desligarFarm()
		else
			ligarFarm()
		end
		refresh()
	elseif input.KeyCode == CONFIG.teclaGuarda then
		if estado.guarda then
			desligarGuarda()
		else
			ligarGuarda()
		end
		refresh()
	end
end)

LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)

	-- cada vida/partida comeca com a bolsa vazia (morreu, mataram, partida
	-- acabou ou resetou = bolsa nova). O reset de verdade so acontece quando
	-- a contagem chega em CONFIG.capacidadeBolsa.
	if CONFIG.zerarBolsaAoRenascer then
		estado.moedas = 0
		estado.jogoBase = nil
		estado.jogoMudou = false
	end

	limparMarca()
	limparDestaque()
	soltarTrava()
	estado.noclipLigado = false
	restaurarColisao()
	estado.semMoedaDesde = os.clock()

	refresh()
end)

-- varre o que ja estava no mapa
do
	local ok = pcall(function()
		for _, inst in ipairs(Workspace:GetDescendants()) do
			if inst:IsA("BasePart") then
				registrarMoeda(inst)
			end
		end
	end)
	if not ok then
		print("[Farm+Guarda] varredura inicial falhou (segue escutando moeda nova)")
	end
end

-- moeda nascendo daqui pra frente
pcall(function()
	Workspace.DescendantAdded:Connect(function(inst)
		if inst:IsA("BasePart") then
			registrarMoeda(inst)
		end
	end)
end)

if CONFIG.mostrarPainel then
	construir()
end

refresh()

-- threads de trabalho (o farm NAO depende da deteccao do contador)
task.spawn(function()
	while estado.ativo do
		verificarPendentes()
		task.wait(0.15)
	end
end)
task.spawn(function()
	while estado.ativo do
		atualizarContadorJogo()
		task.wait(0.5)
	end
end)
task.spawn(monitorMurder)
task.spawn(loopPrincipal)

-- deteccao do contador em thread separada: se o require do perfil demorar ou
-- travar, o farm continua funcionando normalmente
task.spawn(function()
	contadorJogo = acharContadorJogo()
	if contadorJogo then
		print("[Farm+Guarda] contador do jogo: " .. tostring(contadorJogo.tipo)
			.. " " .. tostring(contadorJogo.caminho or contadorJogo.nome or ""))
	else
		print("[Farm+Guarda] contador do jogo nao encontrado - usando a contagem do script")
	end
	hookarContadorPorRemote()
	farejarRemotes()
end)

if type(getgenv) == "function" then
	pcall(function()
		getgenv().MM2FarmGuarda = {
			config    = CONFIG,
			estado    = estado,
			ligarFarm = ligarFarm,
			pararFarm = desligarFarm,
			ligarGuarda = ligarGuarda,
			desligarGuarda = desligarGuarda,
			resetar   = resetar,
			desligar  = function()
				estado.ativo = false
			end,
		}
	end)
end

print("[Farm+Guarda] carregado - moedas visiveis agora: " .. tostring(#moedas))
print("[Farm+Guarda] botoes na tela: AUTO FARM / GUARDA  (PC: RightShift / F2 / F3)")
aviso("Farm + Guarda", "Use os botoes AUTO FARM e GUARDA na tela.", 5)
