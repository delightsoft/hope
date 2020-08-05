$$getBuilder = (fields) ->

  mask = if fields.$$tags?.system then {mask: fields.$$tags.system.invert()} else undefined

  (fieldsLevel, mask, options) -> # (fields) ->

    fields.$$fix fieldsLevel, Object.assign {}, options, {mask} # (options) ->

# ----------------------------

module.exports = $$getBuilder
