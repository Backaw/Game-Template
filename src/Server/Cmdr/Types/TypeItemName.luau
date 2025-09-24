local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemUtil = require(ReplicatedStorage.Shared.Items.ItemUtil)
local CmdrUtil = require(ReplicatedStorage.Shared.Utils.CmdrUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

return function(registry)
	-- We have to create a uniqe productId type for each productType
	for itemType, items in (ItemUtil.getItems()) do
		local function stringsGetter()
			return TableUtil.getKeys(items)
		end

		local function stringToObject(itemName: string)
			return itemName
		end

		local typeName = ItemUtil.getCmdrTypeName(itemType)
		registry:RegisterType(typeName, CmdrUtil.createTypeDefinition(typeName, stringsGetter, stringToObject))
	end
end
