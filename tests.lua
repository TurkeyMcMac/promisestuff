--[[
MIT License

Copyright (c) 2022 Jude Melton-Houghton

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

local promisestuff = dofile("promisestuff.lua")

describe("promisestuff", function()
	it("receiver before send", function()
		local channel = promisestuff.channel()
		local out
		channel:receiver(function(x) out = x end)
		channel:send(1)
		assert.same(1, out)
	end)

	it("send before receiver", function()
		local channel = promisestuff.channel()
		local out
		channel:send(1)
		channel:receiver(function(x) out = x end)
		assert.same(1, out)
	end)

	it("send nothing", function()
		local channel = promisestuff.channel()
		channel:send()
		channel:receiver(function(...)
			assert.same(0, select("#", ...))
		end)
	end)

	it("send nil", function()
		local channel = promisestuff.channel()
		channel:send(nil)
		channel:receiver(function(...)
			assert.same(1, select("#", ...))
			assert.same(nil, select(1, ...))
		end)
	end)

	it("send double nil", function()
		local channel = promisestuff.channel()
		channel:send(nil, nil)
		channel:receiver(function(...)
			assert.same(2, select("#", ...))
			assert.same(nil, select(1, ...))
			assert.same(nil, select(2, ...))
		end)
	end)

	it("promise", function()
		local channel = promisestuff.promise(function(channel)
			channel:send(1)
		end)
		local out
		channel:receiver(function(v) out = v end)
		assert.same(1, out)
	end)

	it("id", function()
		local channel = promisestuff.id(1, nil, 5)
		local a, b, c
		channel:receiver(function(x, y, z) a, b, c = x, y, z end)
		assert.same(1, a)
		assert.same(nil, b)
		assert.same(5, c)
	end)

	it("wrap", function()
		local channel = promisestuff.channel()
		local wrapped = channel:wrap(function(x) return x + 1 end)
		local out
		wrapped:receiver(function(x) out = x end)
		channel:send(1)
		assert.same(2, out)
	end)

	it("chain", function()
		local channel1 = promisestuff.channel()
		local chained = channel1:chain(function(x)
			return promisestuff.id(x + 1)
		end)
		local out
		chained:receiver(function(x) out = x end)
		channel1:send(1)
		assert.same(2, out)
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
		assert.same(1, out1)
		assert.same(false, done)
		channel2:send(2)
		assert.same(1, out1)
		assert.same(2, out2)
		assert.same(true, done)
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
			assert.same(2, results[1].n)
			assert.same(2, results[2].n)
		end)
		channel1:send(1, 1)
		assert.same(0, out1)
		assert.same(1, out2)
		channel2:send(3, 4)
		assert.same(4, out1)
		assert.same(6, out2)
	end)

	it("first", function()
		local channel1 = promisestuff.channel()
		local channel2 = promisestuff.channel()
		local first = promisestuff.first{channel1, channel2}
		local out
		first:receiver(function(x) out = x end)
		channel1:send(1)
		assert.same(1, out)
		channel2:send(2)
		assert.same(1, out)
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
		assert.same(-1, out)
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
		assert.same(3, out)
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
