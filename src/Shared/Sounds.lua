local Sounds = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local TweenUtil = require(ReplicatedStorage.Modules.Utils.TweenUtil)
local Binder = require(ReplicatedStorage.Modules.Binder)

local DEFAULT_FADE_DURATION = 0.5

local soundTemplates: { [string]: Sound } = {}

local function fade(sound: Sound, duration: number, goalVolume: number)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
	return TweenUtil.tween(sound, tweenInfo, { Volume = goalVolume })
end

-------------------------------------------------------------------------------
-- PUBLIC
-------------------------------------------------------------------------------
function Sounds.create(name: string, parent: Instance?)
	local sound = soundTemplates[name]
	if not sound then
		error(("Sound %s doesn't exist"):format(name))
	end

	sound = sound:Clone()
	sound.Parent = parent or Workspace

	return sound
end

function Sounds.play(name: string, dontRemove: boolean?, parent: any?, timePosition: number?, pitch: number?): Sound?
	--[[
	local sound = Sounds.create(name, parent)
	sound.TimePosition = timePosition or 0

	if pitch then
		local effect = Instance.new("PitchShiftSoundEffect")
		effect.Octave = pitch
		effect.Parent = sound
	end

	if dontRemove then
		sound:Play()
		return sound
	end

	-- WARN: Is looped
	if sound.Looped then
		warn(("PlayOnRemove'd a looped sound (%s)"):format(name))
	end

	sound.PlayOnRemove = true
	sound:Destroy()
	*]]
end

function Sounds.fadeIn(sound: Sound, duration: number?)
	local goalVolume = Binder.bindFirst(sound, "InitialVolume", sound.Volume)
	sound.Volume = 0
	sound.Playing = true
	return fade(sound, duration or DEFAULT_FADE_DURATION, goalVolume)
end

function Sounds.fadeOut(sound: Sound, duration: number?, atEnd: boolean?, destroyAfter: boolean?)
	task.spawn(function()
		if not sound.IsLoaded then
			sound.Loaded:Wait()
		end

		duration = duration or DEFAULT_FADE_DURATION

		local delayTime
		if atEnd then
			delayTime = math.max(0, sound.TimeLength - duration - sound.TimePosition)
			duration = math.min(duration, delayTime)
		else
			delayTime = 0
		end

		task.delay(delayTime, function()
			local tween = fade(sound, duration, 0)

			if destroyAfter then
				tween.Completed:Connect(function()
					sound:Destroy()
				end)
			end
		end)
	end)
end

function Sounds.toggleGroupVolume(name: string, toggle: boolean)
	local group = SoundService:FindFirstChild(name)
	if not group then
		error(("Sound group %s doesn't exist"):format(name))
	end

	local initVolume = Binder.bindFirst(group, "InitialVolume", group.Volume)
	group.Volume = if toggle then initVolume else 0
end

function Sounds.getSoundsInCategory(categoryName: string)
	local sounds = {}

	for _, category: Folder in  (SoundService:GetDescendants()) do
		if category.Name == categoryName and category:IsA("Folder") then
			for _, child in  (category:GetChildren()) do
				table.insert(sounds, child.Name)
			end

			return sounds
		end
	end

	error(("Sound category %s doesn't exist"):format(categoryName))
end

-------------------------------------------------------------------------------
-- INTIIALIZATION
-------------------------------------------------------------------------------
for _, group in  (SoundService:GetChildren()) do
	group = group :: SoundGroup
	if group:IsA("SoundGroup") then
		for _, sound in  (group:GetDescendants()) do
			sound = sound :: Sound
			if sound:IsA("Sound") then
				local name = sound.Name

				-- CONTINUE: Sound is a duplicate
				if soundTemplates[name] then
					warn(("Duplicate sound (%s)"):format(sound:GetFullName()))
					continue
				end

				soundTemplates[name] = sound
				sound.SoundGroup = group
			end
		end
	end
end

return Sounds
