local promisestuff = dofile("promisestuff.lua")

describe("promisestuff", function()
	it("receiver before send", function()
		local channel = promisestuff.channel()
		local out
		channel:receiver(function(x) out = x end)
		channel:send(1)
		assert.same(out, 1)
	end)

	it("send before receiver", function()
		local channel = promisestuff.channel()
		local out
		channel:send(1)
		channel:receiver(function(x) out = x end)
		assert.same(out, 1)
	end)

	it("send nil", function()
		local channel = promisestuff.channel()
		channel:send(nil)
		channel:receiver(function(...)
			assert.same(select("#", ...), 1)
			assert.same(select(1, ...), nil)
		end)
	end)

	it("send double nil", function()
		local channel = promisestuff.channel()
		channel:send(nil, nil)
		channel:receiver(function(...)
			assert.same(select("#", ...), 2)
			assert.same(select(1, ...), nil)
			assert.same(select(2, ...), nil)
		end)
	end)

	it("id", function()
		local channel = promisestuff.id(1, nil, 5)
		local a, b, c
		channel:receiver(function(x, y, z) a, b, c = x, y, z end)
		assert.same(a, 1)
		assert.same(b, nil)
		assert.same(c, 5)
	end)

	it("wrap", function()
		local channel = promisestuff.channel()
		local wrapped = channel:wrap(function(x) return x + 1 end)
		local out
		wrapped:receiver(function(x) out = x end)
		channel:send(1)
		assert.same(out, 2)
	end)

	it("chain", function()
		local channel1 = promisestuff.channel()
		local chained = channel1:chain(function(x)
			return promisestuff.id(x + 1)
		end)
		local out
		chained:receiver(function(x) out = x end)
		channel1:send(1)
		assert.same(out, 2)
	end)

	it("barrier", function()
		local out1, out2
		local channel1 = promisestuff.channel()
		local channel2 = promisestuff.channel()
		local barrier = promisestuff.barrier{
			channel1:wrap(function(x) out1 = x end),
			channel2:wrap(function(x) out2 = x end),
		}
		local done = false
		barrier:receiver(function() done = true end)
		channel1:send(1)
		assert.same(out1, 1)
		assert.same(done, false)
		channel2:send(2)
		assert.same(out1, 1)
		assert.same(out2, 2)
		assert.same(done, true)
	end)

	it("collection", function()
		local channel1 = promisestuff.channel()
		local channel2 = promisestuff.channel()
		local collection = promisestuff.collection{channel1, channel2}
		local out1 = 0
		local out2 = 1
		collection:receiver(function(results)
			out1 = out1 + results[1][1] + results[2][1]
			out2 = out2 + results[1][2] + results[2][2]
			assert.same(results[1].n, 2)
			assert.same(results[2].n, 2)
		end)
		channel1:send(1, 1)
		assert.same(out1, 0)
		assert.same(out2, 1)
		channel2:send(3, 4)
		assert.same(out1, 4)
		assert.same(out2, 6)
	end)

	it("first", function()
		local channel1 = promisestuff.channel()
		local channel2 = promisestuff.channel()
		local first = promisestuff.first{channel1, channel2}
		local out
		first:receiver(function(x) out = x end)
		channel1:send(1)
		assert.same(out, 1)
		channel2:send(2)
		assert.same(out, 1)
	end)

	it("await with yield", function()
		local channel = promisestuff.channel()
		local out = 0
		local co = coroutine.create(function(x)
			local a, b = channel:await()
			out = x + a - b
		end)
		coroutine.resume(co, 1)
		channel:send(2, 4)
		assert.same(out, -1)
	end)

	it("await without yield", function()
		local channel = promisestuff.channel()
		local out = 0
		local co = coroutine.create(function(x)
			local a, b = channel:await()
			out = x + a - b
		end)
		channel:send(4, 2)
		coroutine.resume(co, 1)
		assert.same(out, 3)
	end)

	it("double receiver before send", function()
		local channel = promisestuff.channel()
		channel:receiver(function() end)
		assert.has_errors(function()
			channel:receiver(function() end)
		end)
	end)

	it("double send before receiver", function()
		local channel = promisestuff.channel()
		channel:send()
		assert.has_errors(function() channel:send() end)
	end)

	it("double receiver after send", function()
		local channel = promisestuff.channel()
		channel:send()
		channel:receiver(function() end)
		assert.has_errors(function()
			channel:receiver(function() end)
		end)
	end)

	it("double send after receiver", function()
		local channel = promisestuff.channel()
		channel:receiver(function() end)
		channel:send()
		assert.has_errors(function() channel:send() end)
	end)

	it("double receiver around send", function()
		local channel = promisestuff.channel()
		channel:receiver(function() end)
		channel:send()
		assert.has_errors(function()
			channel:receiver(function() end)
		end)
	end)

	it("double send around receiver", function()
		local channel = promisestuff.channel()
		channel:send()
		channel:receiver(function() end)
		assert.has_errors(function() channel:send() end)
	end)
end)
