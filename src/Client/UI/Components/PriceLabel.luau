--!strict
local PriceLabel = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Client = ReplicatedStorage.Client
local CurrencyConstants = require(Shared.Currency.CurrencyConstants)
local TextLabelUtil = require(Client.UI.Utils.TextLabelUtil)
local TemplateUtil = require(Shared.Utils.TemplateUtil)
local StringUtil = require(Shared.Utils.StringUtil)
local Images = require(Shared.Images)
local UIScaleController = require(Client.UI.UIScaleController)
local ComponentUtil = require(Client.UI.Utils.ComponentUtil)
local Component = require(Client.UI.Components.Component)

export type PriceLabel = Component.Component & {
	Mount: (PriceLabel, GuiObject, boolean?) -> (),
	Remount: (PriceLabel, GuiObject, boolean?) -> (),
	GetParent: (PriceLabel) -> GuiObject,
	Align: (PriceLabel, Enum.HorizontalAlignment) -> (),
	EnableOwned: (PriceLabel) -> (),
	SetPrice: (PriceLabel, CurrencyConstants.Price, Color3?) -> (),
}

function PriceLabel.new(showDelta: boolean?)
	local priceLabel = Component.new() :: PriceLabel

	-------------------------------------------------------------------------------
	-- PRIVATE MEMBERS
	-------------------------------------------------------------------------------
	local components = TemplateUtil.cloneChildren(ComponentUtil.getPlayerGui().Components.PriceLabel)

	local label = components.TextLabel
	local icon: ImageLabel = components.Icon
	local uiListLayout: UIListLayout = components.UIListLayout

	local textSize: number

	-------------------------------------------------------------------------------
	-- PRIVATE METHODS
	-------------------------------------------------------------------------------

	local function setText(text: string)
		label.TextSize = textSize
		TextLabelUtil.setScaleableText(label, text)
	end

	-------------------------------------------------------------------------------
	-- PUBLIC MEMBERS
	-------------------------------------------------------------------------------

	-- Set price before mounting
	function priceLabel:Mount(parent, hideBackground)
		label.Parent = parent
		icon.Parent = parent
		uiListLayout.Parent = parent

		local ancestor = label:FindFirstAncestorWhichIsA("GuiObject")
		if ancestor then
			textSize = ancestor.AbsoluteSize.Y / UIScaleController.getScale()
		end

		parent.BackgroundTransparency = if hideBackground then 1 else parent.BackgroundTransparency
	end

	function priceLabel:Remount(parent, hideBackground)
		priceLabel:Mount(parent, hideBackground)
	end

	function PriceLabel:GetParent()
		return label.Parent
	end

	function priceLabel:Align(alignment)
		uiListLayout.HorizontalAlignment = alignment
	end

	function priceLabel:EnableOwned()
		setText("Owned")
		label.TextColor3 = Color3.fromRGB(255, 255, 255)

		icon.Visible = false
	end

	function priceLabel:SetPrice(price: CurrencyConstants.Price, color)
		if price.Currency == "Coins" or price.Currency == "Hearts" then
			setText(`{if showDelta then "-" else ""}{StringUtil.getCompactNumber(price.Amount)}`)
			icon.Image = Images.Currencies[price.Currency]
			icon.Visible = true
		elseif price.Currency == "DevProduct" or price.Currency == "GamePass" then
			setText(" " .. (if price.PriceInRobux then StringUtil.commafiedNumber(tostring(price.PriceInRobux)) else "nil"))
			icon.Visible = false
		else
			setText("Free")

			icon.Visible = false
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
		end

		label.TextColor3 = color or label.TextColor3
	end

	-------------------------------------------------------------------------------
	-- LOGIC
	-------------------------------------------------------------------------------

	for _, component in pairs(components :: any) do
		priceLabel:GetMaid():Add(component)
	end

	return priceLabel
end

return PriceLabel
