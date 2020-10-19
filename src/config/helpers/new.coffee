EMPTY = {}

$$newBuilder = (fields) ->

  mask = if fields.$$tags?.system then {mask: fields.$$tags.system.invert()} else undefined

  mask.mask.set(fields.state.$$index) if mask and fields.state

  (options) -> # (fields) ->

    fields.$$fix EMPTY, Object.assign {}, mask, options # (options) ->

# ----------------------------

module.exports = $$newBuilder
