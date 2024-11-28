local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ProductService = require(Paths.Services.Products.ProductService)
local ProductConstants = require(Paths.Shared.Products.ProductConstants)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)

local productToGamepass = ProductUtil.getCmdrGamepasses()

return function(_, player: Player, productName: string)
	local id = productToGamepass[productName]

	for _, products in  (ProductConstants.Products) do
		for _, product in  (products) do
			if productName == product.Name and productToGamepass[productName] == id then
				ProductService.giveGamepass(player, id)
				ProductService.giveProduct(player, product)
				return
			end
		end
	end
end
