# The Minetest-Specific API of `promisestuff`

Where the Minetest API is amenable to promises, `promisestuff` provides utility
functions that wrap the Minetest API. Unfortunately, this does not include the
HTTP API, as it is restricted to specific mods, and sharing the API with
`promisestuff` would be insecure.

## `promisestuff.after(time)`

Promises to send the returned channel zero values after `time` seconds using the
mechanism of `minetest.after`.

## `promisestuff.emerge_area(pos1, pos2)`

Promises to emerge the mapblocks containing the area from `pos1` to `pos2`.
When the area has been emerged, the returned channel is sent one to two values.
The first value is whether the emergence succeeded entirely. If this is false,
the second value is a table mapping from mapblock position hashes to emerge
actions (like `minetest.EMERGE_ERRORED`.) The pairs of this table specify which
mapblocks failed to emerge and, for each one, what type of failure occurred.
