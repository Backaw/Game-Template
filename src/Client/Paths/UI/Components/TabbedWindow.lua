local TabbedWindow = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Signal = require(Paths.Shared.Signal)
local Button = require(Paths.Controllers.UI.Components.Button)

export type TabbedWindow = typeof(TabbedWindow.new())

function TabbedWindow.new(
	names: { string },
	constructor: (string, number) -> (Button.Button, GuiObject),
	onTabSelectedToggled: ((Button.Button, boolean) -> ()) | nil
)
	local tabbedWindow = {}

	-------------------------------------------------------------------------------
	-- PRIVATE MEMBERS
	-------------------------------------------------------------------------------
	local windows: { [string]: GuiObject } = {}
	local tabs: { [string]: Button.Button } = {}

	local activeWindow: string

	-------------------------------------------------------------------------------
	-- PUBLIC MEMBERS
	-------------------------------------------------------------------------------
	tabbedWindow.ActiveChanged = Signal.new() --> (newTab : string, lastTab: string)

	-------------------------------------------------------------------------------
	-- PUBLIC METHODS
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

		windows[activeWindow].Visible = false

		windows[name].Visible = true

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

	function tabbedWindow:GetOpened()
		return activeWindow
	end

	-------------------------------------------------------------------------------
	-- Initialization
	-------------------------------------------------------------------------------
	for i, name in  (names) do
		-- ERROR: Tab name already exists
		if tabs[name] then
			error(("Tab %s already exists"):format(name))
		end

		activeWindow = activeWindow or name

		local tab, window = constructor(name, i)
		tabs[name] = tab
		windows[name] = window

		tab:GetGuiObject().Name = name
		window.Name = name

		local isOpened = activeWindow == name
		window.Visible = isOpened

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
