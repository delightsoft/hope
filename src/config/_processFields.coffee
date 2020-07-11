Result = require '../result'

flatMap = require '../flatMap'

copyExtra = require './_copyExtra'

{compile: compileType, compile: {_typeProps: typeProps, _extraProps: extraProps}} = require '../types'

{compile: compileTags} = require '../tags'

processFields = (result, doc, config, fieldsProp = 'fields', noSystemItems) ->

  unless doc.$$src.hasOwnProperty(fieldsProp)

    result.error 'dsc.missingProp', value: fieldsProp

    return

  result.context (Result.prop fieldsProp), -> # processFields

    flatMapOpts = index: true, mask: true

    unless noSystemItems

      flatMapOpts.before = [
        {name: 'id', type: 'string(40)', tags: 'system', required: true}
        {name: 'rev', type: 'int', tags: 'system'}
      ]

      flatMapOpts.after = [
        {name: 'created', type: 'timestamp', tags: 'system'}
        {name: 'modified', type: 'timestamp', tags: 'system'}
        {name: 'deleted', type: 'boolean', tags: 'system'}
      ]

      flatMapOpts.reservedNames = ['id', 'rev', 'created', 'modified', 'deleted']

    res = flatMap result, doc.$$src[fieldsProp], 'fields', flatMapOpts

    unless result.isError

      _processLevel = (level) ->

        copyExtra result, level

        field = undefined

        result.context ((path) -> (Result.prop field.name) path), ->

          for field in level.$$list

            result.isError = false

            compileType result, field.$$src, field, context: 'field'

            if field.hasOwnProperty('udType') && config.udtypes != 'failed'

              unless config.udtypes && config.udtypes.hasOwnProperty(field.udType)

                result.error 'dsc.unknownType', value: field.udType

              else

                udt = config.udtypes[field.udType]

                field.type = udt.type

                field[prop] = udt[prop] for prop in typeProps when udt.hasOwnProperty(prop)

                field[prop] = udt[prop] for prop in extraProps when udt.hasOwnProperty(prop)

                udtList = [udt.name]

                parentUdt = udt

                while parentUdt.hasOwnProperty('udType')

                  parentUdt = config.udtypes[parentUdt.udType]

                  udtList.push parentUdt.name

                field.udType = udtList

                if udt.hasOwnProperty('extra')

                  if field.hasOwnProperty('extra')

                    field.extra = Object.assign {}, udt.extra, field.extra

                  else

                    field.extra = udt.extra

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
