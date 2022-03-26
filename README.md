# `promisestuff`

This library implements promises for Lua. It was intended for use with Minetest,
but you can use it for other stuff by just including "core.lua". So far I have
tested the core with Lua 5.1 and Lua 5.4. If you are embedding the mod in
another Minetest mod and want to include the Minetest-specific functionality,
you can load "minetest.lua" with your API table as an argument. This will put
the extra functions into the API table. "init.lua" loads the API in this way.

I have documented the [core API](doc/core.md) as well as the [Minetest-specific
API](doc/minetest.md).

All files in this repository are licensed under the MIT license.
