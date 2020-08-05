$$setBuilder = (fields) ->

  mask = if fields.$$tags?.system then {mask: fields.$$tags.system.invert()} else undefined

  (fieldsLevel, update, options) -> # (fields) ->

    fields.$$fix fieldsLevel, Object.assign {}, options, {update} # (options) ->

# ----------------------------

module.exports = $$setBuilder
