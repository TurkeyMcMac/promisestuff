# The Minetest-Specific API of `promisestuff`

Where the Minetest API is amenable to promises, `promisestuff` provides utility
functions that wrap the Minetest API. Unfortunately, this does not include the
HTTP API, as it is restricted to specific mods, and sharing the API with
`promisestuff` would be insecure.

## `promisestuff.after(time)`

Promises to send the returned channel zero values after `time` seconds using the
mechanism of `minetest.after`.

This function can only be used if `minetest.after` is available.

## `promisestuff.emerge_area(pos1, pos2)`

Promises to emerge the mapblocks containing the area from `pos1` to `pos2`.
When the area has been emerged, the returned channel is sent one to two values.
The first value is whether the emergence succeeded entirely. If this is false,
the second value is a table mapping from mapblock position hashes to emerge
actions (like `minetest.EMERGE_ERRORED`.) The pairs of this table specify which
mapblocks failed to emerge and, for each one, what type of failure occurred.

This function can only be used if `minetest.emerge_area` is available.

## `promisestuff.handle_async(func, ...)`

Promises to execute `func` on an async worker thread with the given arguments
using `minetest.handle_async`. Promises moreover to send the results of the
execution to the returned channel.

This function can only be used if `minetest.handle_async` is available; it was
added during the development of Minetest version 5.6.0.
