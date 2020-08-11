$$getBuilder = (fields) ->

  (fieldsLevel, mask, options) -> # (fields) ->

    fields.$$fix fieldsLevel, Object.assign {}, options, {mask} # (options) ->

# ----------------------------

module.exports = $$getBuilder
