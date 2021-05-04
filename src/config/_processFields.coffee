Result = require '../result'

deepClone = require '../utils/_deepClone'

flatMap = require '../flatMap'

bitArray = require '../bitArray'

copyExtra = require './_copyExtra'

{compile: compileType, compile: {_typeProps: typeProps, _extraProps: extraProps}} = require '../types'

{compile: compileTags} = require '../tags'

processCustomValidate = require '../validate/processCustomValidate'

processFields = (result, doc, config, fieldsProp = 'fields', noSystemItems, udtContext) ->

  unless doc.$$src.hasOwnProperty(fieldsProp)

    result.error 'dsc.missingProp', value: fieldsProp

    return

  result.context (Result.prop fieldsProp), -> # processFields

    flatMapOpts = {}

    unless noSystemItems

      flatMapOpts.before = [
        {name: 'id', type: 'nanoid', tags: 'field, system, index, unique, hide'}
        {name: 'rev', type: 'int', init: 0, tags: 'field, system, hide'}
      ]

      flatMapOpts.after = [
        {name: 'options', type: 'json', tags: 'field, system, index, hide'}
        {name: 'created', type: 'timestamp', tags: 'field, system, index, hide'}
        {name: 'modified', type: 'timestamp', tags: 'field, system, index, hide'}
        {name: 'deleted', type: 'boolean', init: false, tags: 'field, system, hide'}
      ]

      flatMapOpts.after.unshift name: 'state', type: 'string(100)', init: 'new', tags: 'field, system, index' if doc.$$src.states

      flatMapOpts.reservedNames = ['id', 'rev', 'state', 'options', 'created', 'modified', 'deleted']

    resValue = flatMap result, doc.$$src[fieldsProp], 'fields', flatMapOpts

    unless result.isError

      _processLevel = (level) ->

        copyExtra result, level

        field = undefined

        result.context ((path) -> (Result.prop field.name) path), ->

          for field in level.$$list

            result.isError = false

            skipProcessSublevel = false

            compileType result, field.$$src, field, context: 'field'

            if field.hasOwnProperty('udType') and typeof config.udtypes == 'object'

              unless config.udtypes.hasOwnProperty(field.udType)

                result.error 'dsc.unknownType', value: field.udType

              else

                udt = config.udtypes[field.udType]

                src = Object.assign {}, udt

                delete src.udType

                for prop in typeProps when field.$$src.hasOwnProperty(prop) # derive type props

                  src[prop] = field.$$src[prop]

                for prop in extraProps when field.$$src.hasOwnProperty(prop) # derive type props

                  src[prop] = field.$$src[prop]

                delete field[prop] for prop of field when not ~['name', 'extra'].indexOf(prop) and not prop.startsWith('$$')

                compileType result, src, field, context: 'field', udType: true # перекомпилируем, на случай если переопределены свойства базового типа

                if src.fields

                  skipProcessSublevel = true

                  field.fields = deepClone src.fields, all: true

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

                unless skipProcessSublevel

                  result.context (Result.prop 'fields'), ->

                    _processLevel field.fields

            field.validate = field.$$src.validate if processCustomValidate result, field.$$src, level, undefined, config.$$src?.validators

          return # result.context

        return # _processLevel =

      _processLevel resValue

      unless result.isError

        if udtContext

#          _clearIndex = (list) =>
#
#            for item in list
#
#              delete item.$$src
#
#              _clearIndex item.fields.$$list if item.fields
#
#          _clearIndex resValue.$$list

        else

          flatMap.index result, resValue, 'fields', mask: true

          unless result.isError

            compileTags result, resValue

          unless result.isError

            flatMap.finish result, resValue, 'fields', skipProps: ['type', 'tags', 'required', 'null']

      resValue unless result.isError # result.context

# ----------------------------

module.exports = processFields
