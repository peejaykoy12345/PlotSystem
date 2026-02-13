---
sidebar_position: 2
---

# Usage

Begin by requiring the module.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)
```

To create a new Signal instance, call the constructor. The constructor does not receive any arguments.

```lua
local signal = Signal.new()
```

## Connections

Connections are objects returned by the `connect` function.

```lua
local signal = Signal.new()

local function myConnectedFunction()

end

local connection = signal:connect(myConnectedFunction)
```

These connections can only be used to disconnect the connection later down the line.

```lua
local connection = signal:connect(myConnectedFunction)

-- ...somewhere down the line...

connection:disconnect()
```

## Firing Events

Calling the `fire` function of a signal will run all connected functions. Any parameters sent to the function will be forwarded to the connected functions.

```lua
local signal = Signal.new()

local function myConnectedFunction(value)
	print("Signal fired with this value:", value)
end

signal:connect(myConnectedFunction)

signal:fire("Hello world!")
```
