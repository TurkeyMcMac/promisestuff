std = "min"

max_line_length = 80

files["core.lua"] = {
	-- These are used conditionally, so it's fine.
	read_globals = {"unpack", "table.unpack", "setfenv"},
}

files["minetest.lua"] = {
	read_globals = {"minetest"},
}

files["spec/core_spec.lua"] = {
	read_globals = {"describe", "it", "assert"},
}

files["init.lua"] = {
	read_globals = {"minetest"},
}
