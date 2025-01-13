local TabbedWindow = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Signal = require(Paths.Shared.Signal)
local Button = require(Paths.Controllers.UI.Components.Button)

export type TabbedWindow = typeof(TabbedWindow.new())
export type Window = GuiObject | (boolean) -> ()

function TabbedWindow.new(
	names: { string },
	constructor: (string, number) -> (Button.Button, Window),
	onTabSelectedToggled: ((Button.Button, boolean) -> ()) | nil
)
	local tabbedWindow = {}

	-------------------------------------------------------------------------------
	-- PRIVATE VARIABLES
	-------------------------------------------------------------------------------
	local windows: { [string]: Window } = {}
	local tabs: { [string]: Button.Button } = {}

	local activeWindow: string

	-------------------------------------------------------------------------------
	-- PUBLIC VARIABLES
	-------------------------------------------------------------------------------
	tabbedWindow.ActiveChanged = Signal.new() --> (newTab : string, lastTab: string)

	-------------------------------------------------------------------------------
	-- PRIVATE FUNCTIONS
	-------------------------------------------------------------------------------
	local function toggleWindow(window: Window, toggle: boolean)
		if typeof(window) == "Instance" then
			window.Visible = toggle
		else
			window(toggle)
		end
	end

	-------------------------------------------------------------------------------
	-- PUBLIC FUNCTIONS
	-------------------------------------------------------------------------------
	function tabbedWindow:Open(name: string)
		-- ERROR: Tab doesn't exist
		if not tabs[name] then
			error(("Tab %s doesn't exist"):format(name))
		end

		-- RETURN: Tab is already opened
		if activeWindow == name then
			return
		end

		toggleWindow(windows[activeWindow], false)
		toggleWindow(windows[name], true)

		local lastActive = activeWindow
		activeWindow = name

		if onTabSelectedToggled then
			onTabSelectedToggled(tabs[lastActive], false)
			onTabSelectedToggled(tabs[name], true)
		end

		tabbedWindow.ActiveChanged:Fire(name, lastActive)
	end

	function tabbedWindow:GetWindow(name: string)
		return assert(windows[name], ("Tab %s doesn't exist"):format(name))
	end

	function tabbedWindow:GetTabButton(name: string)
		return assert(tabs[name], ("Tab %s doesn't exist"):format(name))
	end

	function tabbedWindow:GetActive()
		return activeWindow
	end

	-------------------------------------------------------------------------------
	-- Initialization
	-------------------------------------------------------------------------------
	for i, name in pairs(names) do
		-- ERROR: Tab name already exists
		if tabs[name] then
			error(("Tab %s already exists"):format(name))
		end

		activeWindow = activeWindow or name

		local tab, window = constructor(name, i)
		tabs[name] = tab
		windows[name] = window

		tab:GetGuiObject().Name = name

		local isOpened = activeWindow == name

		if typeof(window) == "Instance" then
			window.Name = name
		end

		toggleWindow(window, isOpened)

		if onTabSelectedToggled then
			onTabSelectedToggled(tab, name == activeWindow)
		end

		tab.Clicked:Connect(function()
			tabbedWindow:Open(name)
		end)
	end

	return tabbedWindow
end

return TabbedWindow
