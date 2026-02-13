return function()
	describe("Connection.lua", function()
		local Connection = require(script.Parent.Connection)

		it("should build and fire a callback", function()
			local result = false

			local function callback()
				result = true
			end

			local connection = Connection.new(callback)

			connection:disconnect()

			expect(result).to.equal(true)
		end)

		it("should disconnect multiple times without erroring", function()
			local result = 0

			local function callback()
				result += 1
			end

			local connection = Connection.new(callback)

			connection:disconnect()
			connection:disconnect()

			expect(result).to.equal(2)
		end)

		it("should throw on invalid callback", function()
			expect(function()
				Connection.new()
			end).to.throw()
		end)
	end)
end