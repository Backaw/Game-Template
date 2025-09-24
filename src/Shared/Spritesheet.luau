--!strict
local Spritesheet = {}

function Spritesheet.new(texture: string)
	local spritesheet = {}

	local sprites: { [string]: {
		Position: Vector2,
		Size: Vector2,
	} } = {}

	function spritesheet:AddSprite(id: any, position: Vector2, size: Vector2)
		assert(not sprites[id], ("%s already exists"):format(tostring(id)))
		sprites[id] = {
			Position = position,
			Size = size,
		}
	end

	function spritesheet:ApplySprite(id: any, guiObject: ImageLabel | ImageButton)
		if not id then
			guiObject.Image = ""
			return
		end

		-- ERROR: Sprite doesn't exist
		local sprite = sprites[id]
		if not sprite then
			error(("%s is not a valid sprite"):format(tostring(id)))
		end

		guiObject.Image = texture
		guiObject.ImageRectOffset = sprite.Position
		guiObject.ImageRectSize = sprite.Size
	end

	return spritesheet
end

return Spritesheet
