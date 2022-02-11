std = "min"

max_line_length = 80

files["promisestuff.lua"] = {
	-- These are used conditionally, so it's fine.
	read_globals = {"unpack", "table.unpack", "setfenv"},
}

files["tests.lua"] = {
	read_globals = {"describe", "it", "assert.same", "assert.has_errors"},
}

files["init.lua"] = {
	globals = {"promisestuff"},
	read_globals = {"minetest"},
}
