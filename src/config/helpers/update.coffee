$$updateBuilder = (docDesc) ->

  (fieldsLevel, updateMask, options) -> # (fields) ->

    if options?.hasOwnProperty('noRev')

      noRev = !! options.noRev

      options = Object.assign({}, options);

      delete options.noRev

    unless updateMask

      access = docDesc.$$access(fieldsLevel)

      mask = docDesc.fields.$$calc((if noRev then 'id,deleted' else 'id,rev,deleted'), {strict: false}).or(access.update)

    else

      mask = updateMask

    docDesc.fields.$$fix fieldsLevel, Object.assign {}, options, {mask, newVal: false} # (options) ->

# ----------------------------

module.exports = $$updateBuilder
