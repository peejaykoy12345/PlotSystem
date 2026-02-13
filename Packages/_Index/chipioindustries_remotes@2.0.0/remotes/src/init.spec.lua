return function()
	describe("Remotes.lua", function()
		local args = {
			{},
			5143,
			"Yeehaw"
		}

		table.freeze(args)

		local Remotes = require(script.Parent)
		local Llama = require(script.Parent.Parent.Llama)

		it("should create remote folders", function()
			expect(Remotes._eventFolder).to.be.ok()
			expect(Remotes._functionFolder).to.be.ok()
			expect(Remotes._eventFolder:IsA("Folder")).to.equal(true)
			expect(Remotes._functionFolder:IsA("Folder")).to.equal(true)
		end)

		it("should be frozen", function()
			expect(function()
				Remotes.test = 5
			end).to.throw()

			expect(function()
				Remotes._config.scope = "sdfogjnsdj"
			end).to.throw()
		end)

		describe("_getRemoteAsync", function()
			it("should make remote on server", function()
				local hasYielded = false
				task.defer(function()
					hasYielded = true
				end)
				local remote = Remotes:_getRemoteAsync("myRemote1", "RemoteEvent", Remotes._eventFolder)
				expect(hasYielded).to.equal(false)
				expect(remote).to.be.a("userdata")
				expect(remote:IsA("RemoteEvent")).to.equal(true)
			end)
		end)
	end)
end