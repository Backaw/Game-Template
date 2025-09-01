local PromoCodeService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ServerScriptService.Paths
local Shared = ReplicatedStorage.Modules
local Remotes = require(Shared.Remotes)
local PromoCodeConstants = require(Shared.Constants.PromoCodeConstants)
local PlayerDataService = require(Services.Data.PlayerDataService)
local RewardService = require(Services.RewardService)

Remotes.bindFunctions({
	RedeemCode = function(player: Player, code: string)
		local info = PromoCodeConstants.Codes[code]
		local address = "RedeemedCodes." .. code

		-- RETURN: Code doesn't exist
		if not info then
			return PromoCodeConstants.State.DoesNotExist
		end

		if PlayerDataService.get(player, address) then
			return PromoCodeConstants.State.UsedAlready
		end

		if info.BestBy > os.time() then
			PlayerDataService.set(player, address, true)
			RewardService.award(player, info.Reward, "PromoCode")

			return PromoCodeConstants.State.Success
		else
			return PromoCodeConstants.State.Expired
		end
	end,
})

return PromoCodeService
