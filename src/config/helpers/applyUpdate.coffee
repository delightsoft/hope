{isResult} = require '../../utils/_err'

$$applyUpdate = (docModel) ->

  processLevel = (result, model, docLvl, docUpdateLvl, updateMask) ->

    do (res = undefined) -> # (model, level, updateMask) ->

      propName = undefined

      result.context (Result.prop propName), ->

        for propName, propValue of docUpdateLvl

          unless model.fields.hasOwnProperty(propName)

            result 'validate.unknownField', value: propValue

          else

            field = model.fields[propName]

            unless updateMask.get(field.$$index)

              result.error 'validate.unexpectedField', value: propValue

            else

              if (field.type == 'structure' or field.type == 'subtable') and typeof propValue == 'object' and propValue != null

                processLevel result, field, (docLvl[propName] || (docLvl[propName] = {})), propValue, updateMask

              else

                docLvl = propValue

        return

      return

    return # processLevel =

  (result, doc, docUpdate, options) -> # $$applyUpdate = (docModel) ->

    unless isResult(result)

      isNewResult = true

      options = doc

      doc = result

    access = undefined

    if options != undefined

      invalidArg 'options', options unless typeof options == 'object' and options != null and not Array.isArray(options)

      for optName, optValue of options

        switch optName

          when 'access' then access = optValue

          else unknownOption optName

    access = docModel.$$access doc unless access

    {updateMask} = access

    processLevel result, docModel, doc, docUpdate updateMask # (doc, options) ->

    result.throwIfError() if isNewResult

    return # (result, doc, options) ->

# ----------------------------

module.exports = $$applyUpdate

