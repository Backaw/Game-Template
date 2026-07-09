local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemConstants = require(ReplicatedStorage.Shared.Items.ItemConstants)

return function()
	local issues: { string } = {}

	for itemType in pairs(ItemConstants.Types) do
		local requirement = ItemConstants.EquippedItemsRequirement[itemType]
		local slots = ItemConstants.EquipSlots[itemType]

		if requirement == nil then
			table.insert(issues, `Item type "{itemType}" is missing EquippedItemsRequirement`)
		end
		if slots == nil then
			table.insert(issues, `Item type "{itemType}" is missing EquipSlots`)
		end
		if requirement and slots and requirement > slots then
			table.insert(issues, `Item type "{itemType}": EquippedItemsRequirement ({requirement}) must be <= EquipSlots ({slots})`)
		end
	end

	return issues
end
