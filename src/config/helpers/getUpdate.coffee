$$getUpdate = (docModel) ->

  processLevel = (model, level, updateMask) ->

    do (res = undefined) -> # (model, level, updateMask) ->

      model.fields.$$list.forEach (field) ->

        if level.hasOwnProperty(field.name) and updateMask.get(field.$$index)

          (res || (res = {}))[field.name] =

            if field.type == 'structure' or field.type == 'subtable'

              processLevel field, level[field.name], updateMask

            else

              level[field.name]

      res # do (res = undefined) ->

  (doc, options) -> # $$getUpdate = (docModel) ->

    access = undefined

    if options != undefined

      invalidArg 'options', options unless typeof options == 'object' and options != null and not Array.isArray(options)

      for optName, optValue of options

        switch optName

          when 'access' then access = optValue

          else unknownOption optName

    access = docModel.$$access doc unless access

    {updateMask} = access

    processLevel docModel, doc, updateMask # (doc, options) ->

# ----------------------------

module.exports = $$getUpdate

