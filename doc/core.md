# The Core API of `promisestuff`

A "promise" is an abstract concept. It is a contract stating that at some point
in the future, some process will occur, after which zero or more values will be
delivered back to the caller's control. Promises can be composed; for example,
one might promise to deliver the values delivered by two other promises after
both have been fulfilled. This library facilitates promise creation and
composition through the use of "channels".

Channels are the concrete basis of this library. Channels can be used to
transfer a single message consisting of a sequence of zero or more values. The
message can only be received by a receiver callback. This callback can only be
set once, before or after the message is sent. Within this document, setting a
channel's receiver callback may be referred to as "consuming" the channel.

## Primitives

### `promisestuff.channel()`

Returns a new, unique channel. 

### `channel:send(...)`

Sends the passed values to the channel. This should only be called within the
implementation of a promise.

Calling this method more than once on one channel is an error.

Note: `promise.send` will remain the same function throughout the lifetime of
`promise`.

### `channel:receiver(cb)`

Sets the receiver callback for the channel. The callback must be a callable
value. When values are sent to the channel, they will be passed as arguments to
the callback. If values have already been sent, the callback will be called
immediately.

Calling this method consumes the channel. Calling it again on the same channel
is an error.

## Utilities

### `promisestuff.promise(promise)`

Creates a new channel. `promise` is a callable value describing a promise to
send the channel some value(s); it is called with the channel as its first
argument. The channel is then returned.

### `promisestuff.id(...)`

Returns a channel that has been sent the passed values.

### `channel:wrap(wrapper)`

Consumes the channel and returns a new channel. When the consumed channel
receives values, they are passed to `wrapper`, which is a callable value. The
resulting return values of `wrapper` are sent to the new channel.

### `channel:chain(adapter)`

Consumes the channel and returns a new channel. When the consumed channel
receives values, they are passed to `adapter`, which is a callable value.
`adapter` returns another channel, which is consumed. When this channel receives
values, they are sent to the channel returned by the `chain` method.

### `promisestuff.barrier(channels)`

`channels` is a list of channels. All these channels are consumed. A new channel
is returned. Once all the consumed channels have received values, the new
channel is sent a sequence of zero values. The values received by the consumed
channels are just discarded.

### `promisestuff.collection(channels)`

`channels` is a list of channels. All these channels are consumed. A new channel
is returned. Each time one of the consumed channels receives values, they are
recorded in a table. Given such a table in variable `t`, the values can be
retrieved with `unpack(t, 1, t.n)`. The table is recorded in a list, its index
the same as that of the corresponding channel. Once all the channels have
received values, the list is sent to the new channel.

### `promisestuff.first(channels)`

`channels` is a list of channels. All these channels are consumed. A new channel
is returned. The first of the consumed channels to receive values sends these
values to the new channel. Values received by the other channels are discarded.

### `channel:await()`

Consumes the channel. Effectively, the current coroutine yields until the
channel receives values. Once it does, the coroutine is resumed, and `await`
returns the received values.

This method may only be called within a coroutine, of course.
