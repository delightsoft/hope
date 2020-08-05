EMPTY = {}

$$newBuilder = (fields) ->

  mask = if fields.$$tags?.system then {mask: fields.$$tags.system.invert()} else undefined

  (options) -> # (fields) ->

    fields.$$fix EMPTY, Object.assign {}, mask, options # (options) ->

# ----------------------------

module.exports = $$newBuilder
