$$setBuilder = (fields) ->

  (fieldsLevel, update, options) -> # (fields) ->

    fields.$$fix fieldsLevel, Object.assign {}, options, {update} # (options) ->

# ----------------------------

module.exports = $$setBuilder
