---
sidebar_position: 1
---

# Signal

An object that runs multiple connected callback functions when fired.

## Constructor

```lua
local signal = Signal.new()
```

## Functions

|Return Type|Signature|Description|
|-|-|-|
|[`Connection`](connection)|[`connect(function callback)`](#connect)|Connect the given function to the Signal.|
|void|[`fire(...)`](#fire)|Run all connected callbacks, passing along any provided arguments.|
|...|`wait()`|Yields until the signal is fired and returns the arguments.|

## connect

This function connects the given `callback` to the Signal to be called when the Signal is fired. It returns a [`Connection`](connection) that can be used to disconnect the callback.

### Parameters

|Type|Name|Default|Description|
|-|-|-|-|
|`function`|callback||The function to be connected to the Signal.|

## fire

This function runs all of the Signal's connected callbacks. The callback will be spawned in their own threads, meaning errors or yields will not suspend the thread that fired the Signal.

### Parameters

|Type|Name|Default|Description|
|-|-|-|-|
|`Variant`|...||Any number of arguments to be passed to the callbacks.|

## wait

This function yields until the signal is fired and returns the arguments.
