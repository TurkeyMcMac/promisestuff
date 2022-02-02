# `promisestuff`

This library implements promises for Lua. So far I have tested it with Lua 5.1
and Lua 5.4. (You can test it yourself by running `busted tests.lua`.) You can
read about the API in [API.md](API.md). Currently, to include the library in
your program, you must do as follows:
`local promisestuff = dofile("promisestuff")`.
