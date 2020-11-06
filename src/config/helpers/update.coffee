$$updateBuilder = (docDesc) ->

  (fieldsLevel, updateMask, options) -> # (fields) ->

    if options?.hasOwnProperty('noRev')

      noRev = !!options.noRev

      options = Object.assign({}, options);

      delete options.noRev

    unless updateMask

      access = docDesc.$$access(fieldsLevel)

      mask = access.update.add 'id, delete', {strict: false}

      if (noRev) then mask.remove 'rev', strict: false

      mask.lock()

    else

      mask = updateMask

    docDesc.fields.$$fix fieldsLevel, Object.assign {}, options, {mask, newVal: false} # (options) ->

# ----------------------------

module.exports = $$updateBuilder
