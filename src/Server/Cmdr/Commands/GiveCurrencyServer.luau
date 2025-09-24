local ServerStorage = game:GetService("ServerStorage")
local CurrencyService = require(ServerStorage.Server.CurrencyService)

return function(_, player: Player, currency: string, amount: number)
	CurrencyService.transact(player, currency, amount)
end
