$$getBuilder = (docDesc) ->

  (fieldsLevel, updateMask, options) -> # (fields) ->

    unless updateMask

      access = docDesc.$$access(fieldsLevel)

      mask = docDesc.fields.$$calc('id,rev,deleted').or(access.update)

    docDesc.fields.$$fix fieldsLevel, Object.assign {}, options, {mask} # (options) ->

# ----------------------------

module.exports = $$getBuilder
