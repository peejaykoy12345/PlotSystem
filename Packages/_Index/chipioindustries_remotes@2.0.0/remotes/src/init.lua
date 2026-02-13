--[[
	Remotes.new({
		scope = "myScope";
	})
	Remotes:getAll()
	Remotes:getEventAsync(name)
	Remotes:getFunctionAsync(name)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DefaultConfig = require(script.DefaultConfig)

local Llama = require(script.Parent.Llama)
local Rapscallion = require(script.Parent.Rapscallion).new()

local SCOPE_FOLDER_PREFIX = "REMOTES_"

local function getRouteAsync(origin, route)
	if RunService:IsServer() then
		return Rapscallion:buildRoute(origin, route)
	elseif RunService:IsClient() then
		return Rapscallion:waitForRoute(origin, route)
	end
end

local Remotes = {}
Remotes.__index = Remotes

function Remotes.new(config: DefaultConfig.Config?)
	config = Llama.Dictionary.join(DefaultConfig, config or {})

	assert(typeof(config.scope) == "string", "scope must be a string")

	local scopeFolder = getRouteAsync(ReplicatedStorage, SCOPE_FOLDER_PREFIX .. config.scope)

	local self = {
		_config = config;
		_eventFolder = getRouteAsync(scopeFolder, "Events");
		_functionFolder = getRouteAsync(scopeFolder, "Functions");
	}

	setmetatable(self, Remotes)

	table.freeze(self)
	table.freeze(config)

	return self
end

function Remotes:_getRemoteAsync(name: string, className: string, folder: Instance, _isClientOverride: boolean?)
	local remote = folder:FindFirstChild(name)
	local created = false

	if not remote then
		if (not _isClientOverride) and RunService:IsServer() then
			remote = Instance.new(className)
			remote.Name = name
			remote.Parent = folder
			created = true
		else
			return folder:WaitForChild(name, false)
		end
	end

	return remote, created
end

function Remotes:getAll()
	local result = {
		events = {};
		functions = {};
	}

	for _, event in pairs(self._eventFolder:GetChildren()) do
		result.events[event.Name] = event
	end

	for _, func in pairs(self._functionFolder:GetChildren()) do
		result.functions[func.Name] = func
	end

	return result
end

function Remotes:getEventAsync(name: string)
	local remote, _created = self:_getRemoteAsync(name, "RemoteEvent", self._eventFolder)
	return remote
end

function Remotes:getFunctionAsync(name: string)
	local remote, _created = self:_getRemoteAsync(name, "RemoteFunction", self._functionFolder)
	return remote
end

return Remotes.new()