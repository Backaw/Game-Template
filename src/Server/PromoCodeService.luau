--!strict
local PromoCodeService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local PromoCodeConstants = require(ReplicatedStorage.Shared.Constants.PromoCodeConstants)
local PlayerDataService = require(ServerStorage.Server.Data.PlayerDataService)
local RewardService = require(ServerStorage.Server.RewardService)

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function isValidCode(code: string)
	return PromoCodeConstants.Codes[code] ~= nil
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

PromoCodeConstants.Remotes.RedeemCode:OnServerInvoked(function(player, code)
	if isValidCode(code) then
		local info = PromoCodeConstants.Codes[code]
		local address = "RedeemedCodes." .. code

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
	end

	return PromoCodeConstants.State.DoesNotExist
end)

return PromoCodeService
