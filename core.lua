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

local promisestuff = {}

local getmetatable, setmetatable, assert, select, ipairs =
	getmetatable, setmetatable, assert, select, ipairs
local unpack = unpack or table.unpack
local co_running, co_resume, co_yield =
	coroutine.running, coroutine.resume, coroutine.yield

local _ENV = {}
if setfenv then setfenv(1, _ENV) end

promisestuff.version = {major = 0, minor = 3, patch = 0}
promisestuff.versionstring = ("%d.%d.%d"):format(
	promisestuff.version.major,
	promisestuff.version.minor,
	promisestuff.version.patch)

-- Internal Functions --

local function fast_pack(...)
	local n_values = select("#", ...)
	local values
	if n_values == 1 then
		values = ...
	elseif n_values > 1 then
		values = {...}
	end
	return values, n_values
end

local function fast_unpack(values, n_values)
	if n_values == 1 then
		return values
	elseif n_values > 1 then
		return unpack(values, 1, n_values)
	end
end

local channel_methods = {}
channel_methods.__index = channel_methods

-- Primitives --

function promisestuff.channel()
	return setmetatable({}, channel_methods)
end

function promisestuff.is_channel(v)
	return getmetatable(v) == channel_methods
end

function channel_methods:receiver(cb)
	assert(cb ~= nil, "Invalid invocation of channel method 'receiver'")
	assert(self.cb == nil, "Method 'receiver' called twice on one channel")
	local n_args = self.n_args
	if n_args ~= nil then
		local args = self.args
		self.args = nil -- Allow for garbage collection
		self.cb = true
		cb(fast_unpack(args, n_args))
	else
		self.cb = cb
	end
end

function channel_methods:send(...)
	assert(self.n_args == nil, "Attempt to send to a channel a second time")
	local cb = self.cb
	if cb ~= nil then
		self.cb = true -- Allow for garbage collection
		self.n_args = true
		cb(...)
	else
		self.args, self.n_args = fast_pack(...)
	end
end
channel_methods.__call = channel_methods.send

-- Utilities --

function promisestuff.promise(promise)
	local channel = promisestuff.channel()
	promise(channel)
	return channel
end

function promisestuff.id(...)
	local channel = promisestuff.channel()
	channel(...)
	return channel
end

function channel_methods:wrap(wrapper)
	assert(wrapper ~= nil, "Invalid invocation of channel method 'wrap'")
	local wrapped = promisestuff.channel()
	self:receiver(function(...) wrapped(wrapper(...)) end)
	return wrapped
end

function channel_methods:if_wrap(wrapper)
	assert(wrapper ~= nil, "Invalid invocation of channel method 'if_wrap'")
	local wrapped = promisestuff.channel()
	self:receiver(function(...)
		if ... then
			wrapped(wrapper(...))
		else
			wrapped(...)
		end
	end)
	return wrapped
end

function channel_methods:chain(adapter)
	assert(adapter ~= nil, "Invalid invocation of channel method 'chain'")
	local chain = promisestuff.channel()
	self:receiver(function(...) adapter(...):receiver(chain) end)
	return chain
end

function channel_methods:if_chain(adapter)
	assert(adapter ~= nil,
		"Invalid invocation of channel method 'if_chain'")
	local chain = promisestuff.channel()
	self:receiver(function(...)
		if ... then
			adapter(...):receiver(chain)
		else
			chain(...)
		end
	end)
	return chain
end

function promisestuff.barrier(channels)
	local barrier = promisestuff.channel()
	local n_left = #channels
	local function receiver()
		n_left = n_left - 1
		if n_left == 0 then barrier() end
	end
	for _, channel in ipairs(channels) do
		channel:receiver(receiver)
	end
	return barrier
end

function promisestuff.collection(channels)
	local collection = promisestuff.channel()
	local results = {}
	local n_left = #channels
	for i, channel in ipairs(channels) do
		channel:receiver(function(...)
			results[i] = {n = select("#", ...), ...}
			n_left = n_left - 1
			if n_left == 0 then collection(results) end
		end)
	end
	return collection
end

function promisestuff.first(channels)
	local first = promisestuff.channel()
	local receptacle = first
	local function receiver(...)
		if receptacle then
			receptacle(...)
			receptacle = nil
		end
	end
	for _, channel in ipairs(channels) do
		channel:receiver(receiver)
	end
	return first
end

function channel_methods:await()
	local co = co_running()
	assert(co, "Channel method 'await' called outside a coroutine")
	local yielded = false
	local n_retvals
	local retvals
	self:receiver(function(...)
		if yielded then
			co_resume(co, ...)
		else
			retvals, n_retvals = fast_pack(...)
		end
	end)
	if n_retvals ~= nil then
		return fast_unpack(retvals, n_retvals)
	else
		yielded = true
		return co_yield()
	end
end

return promisestuff
