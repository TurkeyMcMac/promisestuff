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

local promisestuff = ...

function promisestuff.after(time)
	local channel = promisestuff.channel()
	minetest.after(time, channel.send, channel)
	return channel
end

local function emerge_callback(blockpos, action, calls_remaining, param)
	if action == minetest.EMERGE_CANCELLED or
	   action == minetest.EMERGE_ERRORED then
		local hash = minetest.hash_node_position(blockpos)
		if param.fails then
			param.fails[hash] = action
		else
			param.fails = {[hash] = action}
		end
	end
	if calls_remaining == 0 then
		-- Defer resumption to avoid blocking the emerge thread.
		minetest.after(0, param.channel.send, param.channel,
			param.fails == nil, param.fails)
	end
end
function promisestuff.emerge_area(pos1, pos2)
	local channel = promisestuff.channel()
	minetest.emerge_area(pos1, pos2, emerge_callback, {channel = channel})
	return channel
end

function promisestuff.handle_async(func, ...)
	local channel = promisestuff.channel()
	minetest.handle_async(func, function(...) channel(...) end, ...)
	return channel
end
