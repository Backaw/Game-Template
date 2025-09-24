local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local ProductConstants = require(ReplicatedStorage.Shared.Products.ProductConstants)
local ProductUtil = require(ReplicatedStorage.Shared.Products.ProductUtil)
local ProductService = require(ServerStorage.Server.Products.ProductService)

local productToGamepass = ProductUtil.getCmdrGamepasses()

return function(_, player: Player, productName: string)
	local id = productToGamepass[productName]

	for _, products in ProductConstants.Products do
		for _, product in products do
			if productName == product.Name and productToGamepass[productName] == id then
				ProductService.giveGamepass(player, id)
				ProductService.giveProduct(player, product)
				return
			end
		end
	end
end
