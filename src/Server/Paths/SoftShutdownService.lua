local SoftShutdownService = {}

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Paths = require(ServerScriptService.Paths)
local Remotes = require(Paths.Shared.Remotes)

local placeId = game.PlaceId

local isProxyServerValue = Instance.new("BoolValue")
isProxyServerValue.Name = "ProxyServer"
isProxyServerValue.Value = false
isProxyServerValue.Parent = Workspace

local shuttingDown = false

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function SoftShutdownService.isProxyServer()
	return game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
end

function SoftShutdownService.isShuttingDown()
	return shuttingDown
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
if SoftShutdownService.isProxyServer() then
	isProxyServerValue.Value = true

	local timeout = 5
	local function teleportOut(player: Player)
		task.wait(timeout)
		timeout /= 2
		TeleportService:Teleport(placeId, player)
	end

	Players.PlayerAdded:Connect(teleportOut)
	for _, player in (Players:GetPlayers()) do
		teleportOut(player)
	end
else
	game:BindToClose(function()
		shuttingDown = true

		if #Players:GetPlayers() == 0 then
			return
		end

		if game.JobId == "" then
			return -- Offline
		end

		-- Leaving
		Remotes.fireAllClients("SoftShutdown")

		task.wait(2)
		local reservedServerCode = TeleportService:ReserveServer(game.PlaceId)

		TeleportService:TeleportToPrivateServer(game.PlaceId, reservedServerCode, Players:GetPlayers())
		Players.PlayerAdded:Connect(function(player)
			TeleportService:TeleportToPrivateServer(game.PlaceId, reservedServerCode, { player })
		end)

		while #Players:GetPlayers() > 0 do
			task.wait(1)
		end
	end)
end

Remotes.declareEvent("SoftShutdown")

return SoftShutdownService
