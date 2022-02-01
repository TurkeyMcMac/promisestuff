local promisestuff = {}

local setmetatable, assert, select, ipairs, unpack =
	setmetatable, assert, select, ipairs, unpack or table.unpack
local co_running, co_resume, co_yield =
	coroutine.running, coroutine.resume, coroutine.yield

local _ENV = {}
if setfenv then setfenv(1, _ENV) end

-- Internal Functions --

local function fast_pack(...)
	local n_values = select("#", ...)
	local values
	if n_values == 1 then
		values = select(1, ...)
	elseif n_values > 1 then
		values = {...}
	end
	return values, n_values
end

local function fast_unpack(values, n_values)
	if n_values == 1 then
		return values
	elseif n_values == 0 then
		return
	else
		return unpack(values, 1, n_values)
	end
end

local channel_methods = {}
channel_methods.__index = channel_methods

-- Primitives --

function promisestuff.channel()
	return setmetatable({}, channel_methods)
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
	assert(self.n_args == nil, "Method 'send' called twice on one channel")
	local cb = self.cb
	if cb ~= nil then
		self.cb = true -- Allow for garbage collection
		self.n_args = true
		cb(...)
	else
		self.args, self.n_args = fast_pack(...)
	end
end

-- Utilities --

function promisestuff.id(...)
	local channel = promisestuff.channel()
	channel:send(...)
	return channel
end

function channel_methods:wrap(wrapper)
	assert(wrapper ~= nil, "Invalid invocation of channel method 'wrap'")
	local wrapped = promisestuff.channel()
	self:receiver(function(...) wrapped:send(wrapper(...)) end)
	return wrapped
end

function channel_methods:chain(adapter)
	assert(adapter ~= nil, "Invalid invocation of channel method 'chain'")
	local chain = promisestuff.channel()
	self:receiver(function(...)
		adapter(...):receiver(function(...) chain:send(...) end)
	end)
	return chain
end

function promisestuff.barrier(channels)
	local barrier = promisestuff.channel()
	local n_left = #channels
	local function receiver()
		n_left = n_left - 1
		if n_left == 0 then barrier:send() end
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
			if n_left == 0 then collection:send(results) end
		end)
	end
	return collection
end

function promisestuff.first(channels)
	local first = promisestuff.channel()
	local receptacle = first
	local function receiver(...)
		if receptacle then
			receptacle:send(...)
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
