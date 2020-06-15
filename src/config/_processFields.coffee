Result = require '../result'

flatMap = require '../flatMap'

copyExtra = require './_copyExtra'

{compile: compileType, compile: {_typeProps: typeProps}} = require '../types'

{compile: compileTags} = require '../tags'

processFields = (result, doc, config, fieldsProp = 'fields') ->

  unless doc.$$src.hasOwnProperty(fieldsProp)

    result.error 'dsc.missingProp', value: fieldsProp

    return

  result.context (Result.prop fieldsProp), -> # processFields

    res = flatMap result, doc.$$src[fieldsProp], 'fields', index: true, mask: true

    unless result.isError

      _processLevel = (level) ->

        copyExtra result, level

        field = undefined

        result.context ((path) -> (Result.prop field.name) path), ->

          for field in level.$$list

            result.isError = false

            compileType result, field.$$src, field, context: 'field'

            if field.$$src.hasOwnProperty('required')

              unless typeof (value = field.$$src.required) == 'boolean'

                result.error (Result.prop 'required'), 'dsc.invalidValue', value: value

              else

                field.required = value if value

            if field.hasOwnProperty('udType') && config.udtypes != 'failed'

              unless config.udtypes && config.udtypes.hasOwnProperty(field.udType)

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

      flatMap.finish result, res, 'fields', skipProps: ['tags', 'required', 'null']

      res unless result.isError # result.context

# ----------------------------

module.exports = processFields
