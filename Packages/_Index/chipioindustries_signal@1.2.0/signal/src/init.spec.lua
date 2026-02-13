return function()
	describe("Signal.lua", function()
		local Signal = require(script.Parent)

		it("Should create and fire a signal", function()
			local result = 0

			local function onSignal(value)
				task.wait(0.2)
				result += value
			end

			local signal = Signal.new()

			signal:connect(onSignal)
			signal:connect(onSignal)

			expect(function()
				signal:connect()
			end).to.throw()

			signal:fire(3)

			expect(result).to.equal(0)

			task.wait(0.3)

			expect(result).to.equal(6)
		end)

		it("should wait for signal firing and provide arguments", function()
			local signal = Signal.new()
			local result1, result2

			task.spawn(function()
				result1, result2 = signal:wait()
			end)

			task.wait()

			expect(result1).to.equal(nil)
			expect(result2).to.equal(nil)

			signal:fire("YEEHAW", true)

			task.wait()

			expect(result1).to.equal("YEEHAW")
			expect(result2).to.equal(true)
		end)
	end)
end