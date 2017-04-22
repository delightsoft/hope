Result = require '../result'

flatMap = require '../flatMap'

{compile: compileType, compile: {_typeProps: typeProps}} = require '../types'

{compile: compileTags} = require '../tags'

processFields = (result, doc, config) ->

  unless doc.$$src.hasOwnProperty('fields')

    result.error 'dsc.missingProp', value: 'fields'

    return

  result.context (Result.prop 'fields'), -> # processFields

    res = flatMap result, doc.$$src.fields, 'fields', index: true, mask: true

    unless result.isError

      _processLevel = (level) ->

        field = undefined

        result.context ((path) -> (Result.item field.name) path), ->

          for field in level.$$list

            result.isError = false

            compileType result, field.$$src, field, context: 'field'

            if field.hasOwnProperty('udType') && config.hasOwnProperty('udtypes') # missing 'udtypes' means that udtypes compilation failed

              unless config.udtypes.hasOwnProperty(field.udType)

                result.error 'dsc.unknownType', value: field.udType

              else

                udt = config.udtypes[field.udType]

                field.type = udt.type

                field[prop] = udt[prop] for prop in typeProps when udt.hasOwnProperty(prop)

                udtList = [udt.name]

                while udt.hasOwnProperty('udType')

                  udt = config.udtypes[udt.udType]

                  udtList.push udt.name

                field.udType = udtList

            unless result.isError

              if field.hasOwnProperty('fields')

                result.context (Result.prop 'fields'), ->

                  _processLevel field.fields

          return # result.context

        return # _processLevel =

      _processLevel res

      compileTags result, res

      flatMap.finish result, res, 'fields', skipProps: ['tags']

      res unless result.isError # result.context

# ----------------------------

module.exports = processFields
