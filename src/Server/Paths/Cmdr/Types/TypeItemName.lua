local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrUtil = require(ReplicatedStorage.Modules.Utils.CmdrUtil)
local ItemUtil = require(ReplicatedStorage.Modules.Items.ItemUtil)
local TableUtil = require(ReplicatedStorage.Modules.Utils.TableUtil)

return function(registry)
	-- We have to create a uniqe productId type for each productType
	for itemType, items in  (ItemUtil.getItems()) do
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
