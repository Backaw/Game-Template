local ServerScriptService = game:GetService("ServerScriptService")
local CurrencyService = require(ServerScriptService.Paths.CurrencyService)

return function(_, player: Player, currency: string, amount: number)
	CurrencyService.transact(player, currency, amount)
end
