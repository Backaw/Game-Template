local PriceLabel = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Component = require(Paths.Controllers.UI.Components.Component)
local CurrencyConstants = require(Paths.Shared.Currency.CurrencyConstants)
local TemplateUtil = require(Paths.Shared.Utils.TemplateUtil)
local UIScaleController = require(Paths.Controllers.UI.UIScaleController)
local Images = require(Paths.Shared.Images)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local TextLabelUtil = require(Paths.Controllers.UI.Utils.TextLabelUtil)
local UIUtil = require(Paths.Controllers.UI.Utils.UIUtil)

export type PriceLabel = typeof(PriceLabel.new())

function PriceLabel.new()
	local priceLabel = Component.new()

	-------------------------------------------------------------------------------
	-- PRIVATE MEMBERS
	-------------------------------------------------------------------------------
	local components = TemplateUtil.cloneChildren(Paths.UI.Components.PriceLabel)

	local label: TextLabel = components.TextLabel
	local icon: ImageLabel = components.Icon
	local listLayout: UIListLayout = components.UIListLayout

	local textSize: number

	local maid = priceLabel:GetMaid()

	-------------------------------------------------------------------------------
	-- PRIVATE METHODS
	-------------------------------------------------------------------------------
	local function setText(text: string)
		label.TextSize = textSize
		task.defer(function()
			TextLabelUtil.setScaleableText(label, text)
		end)
	end

	-------------------------------------------------------------------------------
	-- PUBLIC MEMBERS
	-------------------------------------------------------------------------------
	-- Set price before mounting
	function priceLabel:Mount(container: GuiObject, hideBackground: boolean?)
		label.Parent = container
		icon.Parent = container
		listLayout.Parent = container

		textSize = label:FindFirstAncestorWhichIsA("GuiObject").AbsoluteSize.Y / UIScaleController.getScale()
		container.BackgroundTransparency = if hideBackground then 1 else container.BackgroundTransparency

		maid:RemoveIfExits("Parent")
		maid:Add(container, "Parent")

		UIUtil.mountZIndex(container, true)
	end

	function priceLabel:Align(alignment: Enum.HorizontalAlignment)
		listLayout.HorizontalAlignment = alignment
	end

	function priceLabel:GetText()
		return label
	end

	function priceLabel:EnableOwned()
		setText("Owned")
		label.TextColor3 = Color3.fromRGB(255, 255, 255)

		icon.Visible = false
	end

	function priceLabel:SetPrice(price: CurrencyConstants.Price)
		if not label.Parent then
			warn("Must mount textlabel before setting price")
			return
		end

		local currency = price.Currency

		if currency == CurrencyConstants.Currencies.Cash then
			setText(StringUtil.getCompactNumber(price.Amount))
			icon.Image = Images.Currencies[currency] :: typeof(icon.Image)

			icon.Visible = true
		elseif currency == CurrencyConstants.Currencies.DevProduct or currency == CurrencyConstants.Currencies.GamePass then
			setText(("%s"):format(if price.PriceInRobux then StringUtil.commafiedNumber(tostring(price.PriceInRobux)) else "nil"))
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
			icon.Visible = false
		else
			setText("Free")
			label.TextColor3 = Color3.fromRGB(255, 255, 255)

			icon.Visible = false
		end
	end

	function priceLabel:UseTemplate(image: string, text: string)
		setText(text)

		icon.Image = image :: typeof(icon.Image)
		icon.Visible = true
	end

	return priceLabel
end

return PriceLabel
