local DataTypes = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Shared.Signal)

-- export type Data = string & number & boolean & Store -- | string | number | boolean | Store
export type Data = string | number | boolean | Store
export type Store = { [string]: Data }

export type UpdatedEvent = Signal.Signal<string, any, { [string]: any }>

export type EventMeta = { [string]: any }?

return DataTypes
