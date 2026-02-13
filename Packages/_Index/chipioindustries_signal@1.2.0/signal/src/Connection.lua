--[[
	Connection.new(function callback)
	Connection:disconnect()
]]

local Connection = {}
Connection.__index = Connection

function Connection.new(callback)
	assert(typeof(callback) == "function", "callback is not a function")

	local self = {
		_callback = callback;
	}

	setmetatable(self, Connection)

	table.freeze(self)

	return self
end

function Connection:disconnect()
	self._callback()
end

return Connection