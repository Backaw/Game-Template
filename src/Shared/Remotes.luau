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
local IS_RUNNING = RunService:IsRunning()

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type Event<T...> = {
	Type: "Event",
	GetEvent: (Event<T...>) -> RemoteEvent,
	OnServerEvent: (Event<T...>, handler: (Player, T...) -> ()) -> RBXScriptConnection,
	OnClientEvent: (Event<T...>, handler: (T...) -> (), ignorePreConnectPackets: boolean?) -> RBXScriptConnection,
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

type PreConnectionData = {
	Connection: RBXScriptConnection,
	Packets: { any },
}

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local networkFolder: Folder
local eventFolder: Folder
local functionFolder: Folder
local unreliableEventFolder: Folder

-- Track pre-connection packets for RemoteEvents (client only)
local preConnectionPackets: { [RemoteEvent]: PreConnectionData } = {}

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

function Remotes.defineEvent<T...>(name: string): Event<T...>
	if not IS_RUNNING then
		return nil :: any
	end

	local definition = {} :: Event<T...>

	definition.Type = "Event"

	if IS_SERVER then
		-- Check for duplicate event names
		if eventFolder:FindFirstChild(name) then
			error(`RemoteEvent "{name}" is already defined. Each remote event must have a unique name.`)
		end

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

		function definition:OnClientEvent(handler: (T...) -> (), ignorePreConnectPackets: boolean?)
			local preConnectData = preConnectionPackets[event]

			-- If there's pre-connection data, handle it and clean up
			if preConnectData then
				preConnectData.Connection:Disconnect()

				-- Replay buffered packets if not ignored
				if not ignorePreConnectPackets then
					for _, packet in preConnectData.Packets do
						task.spawn(function()
							handler(table.unpack(packet, 1, packet.n))
						end)
					end
				end

				-- Clean up
				preConnectionPackets[event] = nil
			end

			return event.OnClientEvent:Connect(handler)
		end
	end

	return definition
end

function Remotes.defineUnreliableEvent<T...>(name: string): UnreliableEvent<T...>
	if not IS_RUNNING then
		return nil :: any
	end

	local definition = {} :: UnreliableEvent<T...>

	definition.Type = "UnreliableEvent"

	if IS_SERVER then
		-- Check for duplicate unreliable event names
		if unreliableEventFolder:FindFirstChild(name) then
			error(`UnreliableRemoteEvent "{name}" is already defined. Each remote event must have a unique name.`)
		end

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

function Remotes.defineFunction<T..., R...>(name: string): Function<T..., R...>
	if not IS_RUNNING then
		return nil :: any
	end

	local definition = {} :: Function<T..., R...>

	definition.Type = "Function"

	if IS_SERVER then
		-- Check for duplicate function names
		if functionFolder:FindFirstChild(name) then
			error(`RemoteFunction "{name}" is already defined. Each remote function must have a unique name.`)
		end

		-- Create RemoteFunction on server (client will invoke it)
		local remoteFunction = InstanceUtil.newNameParent(Instance.new("RemoteFunction"), name, functionFolder) :: RemoteFunction

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

	function Remotes.fireAllOtherClients<T...>(ignoreClient: Player, definition: Event<T...> | UnreliableEvent<T...>, ...: T...)
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
	-- Destroy stale Network folder from previous sessions (prevents duplicate causing client WaitForChild to hang)
	local existing = ReplicatedStorage:FindFirstChild("Network")
	if existing then
		existing:Destroy()
	end

	networkFolder = InstanceUtil.newNameParent(Instance.new("Folder"), "Network", ReplicatedStorage)
	eventFolder = InstanceUtil.newNameParent(Instance.new("Folder"), "Remotes", networkFolder)
	functionFolder = InstanceUtil.newNameParent(Instance.new("Folder"), "RemoteFunction", networkFolder)
	unreliableEventFolder = InstanceUtil.newNameParent(Instance.new("Folder"), "UnreliableRemotes", networkFolder)
else
	if IS_RUNNING then
		networkFolder = ReplicatedStorage:WaitForChild("Network") :: Folder
		eventFolder = networkFolder:WaitForChild("Remotes") :: Folder
		functionFolder = networkFolder:WaitForChild("RemoteFunction") :: Folder
		unreliableEventFolder = networkFolder:WaitForChild("UnreliableRemotes") :: Folder

		-- Start capturing packets for all RemoteEvents as they're created
		local function setupPreConnectionCapture(child: Instance)
			if child:IsA("RemoteEvent") then
				local event = child :: RemoteEvent
				local packets = {}
				local connection = event.OnClientEvent:Connect(function(...)
					table.insert(packets, table.pack(...))
				end)

				preConnectionPackets[event] = {
					Connection = connection,
					Packets = packets,
				}
			end
		end

		-- Capture packets for existing RemoteEvents
		for _, child in eventFolder:GetChildren() do
			setupPreConnectionCapture(child)
		end

		-- Capture packets for future RemoteEvents
		eventFolder.ChildAdded:Connect(setupPreConnectionCapture)
	end
end

return Remotes
