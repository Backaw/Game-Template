--!strict
local Remotes = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local InstanceUtil = require(ReplicatedStorage.Shared.Utils.InstanceUtil)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local IS_SERVER = RunService:IsServer()
local _IS_STUDIO = RunService:IsStudio()

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type Event<T...> = {
	Type: "Event",
	GetEvent: (Event<T...>) -> RemoteEvent,
	OnServerEvent: (Event<T...>, handler: (Player, T...) -> ()) -> RBXScriptConnection,
	OnClientEvent: (Event<T...>, handler: (T...) -> ()) -> RBXScriptConnection,
	FireServer: (Event<T...>, T...) -> (),
	FireClient: (Event<T...>, Player, T...) -> (),
}

export type Function<T..., R...> = {
	Type: "Function",
	InvokeServer: (Function<T..., R...>, T...) -> R...,
	OnServerInvoked: (Function<T..., R...>, handler: (Player, T...) -> R...) -> (),
}

export type UnreliableEvent<T...> = {
	Type: "UnreliableEvent",
	GetEvent: (UnreliableEvent<T...>) -> UnreliableRemoteEvent,
	OnServerEvent: (UnreliableEvent<T...>, handler: (Player, T...) -> any?) -> RBXScriptConnection,
	OnClientEvent: (UnreliableEvent<T...>, handler: (T...) -> any?) -> RBXScriptConnection,
	FireServer: (UnreliableEvent<T...>, T...) -> (),
	FireClient: (UnreliableEvent<T...>, Player, T...) -> (),
}

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local networkFolder: Folder
local eventFolder: Folder
local functionFolder: Folder
local unreliableEventFolder: Folder

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

function Remotes.defineEvent<T...>(name: string)
	local definition = {} :: Event<T...>

	definition.Type = "Event"

	if IS_SERVER then
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = eventFolder

		function definition:FireClient(player: Player, ...: T...)
			event:FireClient(player, ...)
		end

		function definition:OnServerEvent(handler: (Player, T...) -> ())
			return event.OnServerEvent:Connect(handler)
		end
	else
		local event = eventFolder:WaitForChild(name) :: RemoteEvent

		function definition:FireServer(...: T...)
			event:FireServer(...)
		end

		function definition:OnClientEvent(handler: (T...) -> ())
			return event.OnClientEvent:Connect(handler)
		end
	end

	return definition
end

function Remotes.defineUnreliableEvent<T...>(name: string)
	local definition = {} :: UnreliableEvent<T...>

	definition.Type = "UnreliableEvent"

	if IS_SERVER then
		local event = Instance.new("UnreliableRemoteEvent")
		event.Name = name
		event.Parent = unreliableEventFolder

		function definition:FireClient(player: Player, ...: T...)
			event:FireClient(player, ...)
		end

		function definition:OnServerEvent(handler: (Player, T...) -> ())
			return event.OnServerEvent:Connect(handler)
		end
	else
		local event = unreliableEventFolder:WaitForChild(name) :: UnreliableRemoteEvent

		function definition:FireServer(...: T...)
			event:FireServer(...)
		end

		function definition:OnClientEvent(handler: (T...) -> ())
			return event.OnClientEvent:Connect(handler)
		end
	end

	return definition
end

function Remotes.defineFunction<T..., R...>(name: string)
	local definition = {} :: Function<T..., R...>

	definition.Type = "Function"

	if IS_SERVER then
		-- Create RemoteFunction on server (client will invoke it)
		local remoteFunction = InstanceUtil.newNameParent("RemoteFunction", name, functionFolder) :: RemoteFunction

		function definition:OnServerInvoked(handler: (Player, T...) -> R...)
			remoteFunction.OnServerInvoke = handler
		end
	else
		local remoteFunction = functionFolder:WaitForChild(name) :: RemoteFunction

		function definition:InvokeServer(...: T...): R...
			return remoteFunction:InvokeServer(...)
		end
	end

	return definition
end

-------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
-------------------------------------------------------------------------------

if IS_SERVER then
	function Remotes.fireClients<T...>(definition: Event<T...> | UnreliableEvent<T...>, clients: { Player }, ...: T...)
		for _, player in clients do
			if definition.Type == "Event" then
				(definition :: Event<T...>):FireClient(player, ...)
			elseif definition.Type == "UnreliableEvent" then
				(definition :: UnreliableEvent<T...>):FireClient(player, ...)
			end
		end
	end

	function Remotes.fireAllClients<T...>(definition: Event<T...> | UnreliableEvent<T...>, ...: T...)
		Remotes.fireClients(definition, Players:GetPlayers(), ...)
	end

	function Remotes.fireAllOtherClients<T...>(definition: Event<T...> | UnreliableEvent<T...>, ignoreClient: Player, ...: T...)
		local players = Players:GetPlayers()

		local index = table.find(players, ignoreClient)
		if index then
			table.remove(players, index)
		end

		Remotes.fireClients(definition, players, ...)
	end
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

-- Initialize folder structure
if IS_SERVER then
	networkFolder = InstanceUtil.newNameParent("Folder", "Network", ReplicatedStorage) :: Folder
	eventFolder = InstanceUtil.newNameParent("Folder", "Remotes", networkFolder) :: Folder
	functionFolder = InstanceUtil.newNameParent("Folder", "RemoteFunction", networkFolder) :: Folder
	unreliableEventFolder = InstanceUtil.newNameParent("Folder", "UnreliableRemotes", networkFolder) :: Folder
else
	networkFolder = ReplicatedStorage:WaitForChild("Network") :: Folder
	eventFolder = networkFolder:WaitForChild("Remotes") :: Folder
	functionFolder = networkFolder:WaitForChild("RemoteFunction") :: Folder
	unreliableEventFolder = networkFolder:WaitForChild("UnreliableRemotes") :: Folder
end

return Remotes
