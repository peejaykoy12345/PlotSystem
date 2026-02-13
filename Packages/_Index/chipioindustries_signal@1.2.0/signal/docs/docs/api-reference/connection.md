---
sidebar_position: 2
---

# Connection

An object that runs the given callback when disconnected.

## Constructor

```lua
local function myFunction()
	print("disconnected")
end

local connection = Connection.new(myFunction)
```

### Parameters

|Type|Name|Default|Description|
|-|-|-|-|
|`function`|`callback`||The callback to run when [`disconnect`](#disconnect) is called.|

## Functions

|Return Type|Signature|Description|
|-|-|-|
|void|[`disconnect()`](#disconnect)|Run the callback.|

## disconnect

This function runs the Connection's callback.