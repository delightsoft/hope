$$updateBuilder = (docDesc) ->

  (fieldsLevel, updateMask, options) -> # (fields) ->

    unless updateMask

      access = docDesc.$$access(fieldsLevel)

      mask = docDesc.fields.$$calc('id,rev,deleted', {strict: false}).or(access.update)

    else

      mask = updateMask

    docDesc.fields.$$fix fieldsLevel, Object.assign {}, options, {mask, newVal: false} # (options) ->

# ----------------------------

module.exports = $$updateBuilder
