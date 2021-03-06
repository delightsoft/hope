Result = require '../result'

sortedMap = require '../sortedMap'

bitArray = require '../bitArray'

{compile: compileTags} = require '../tags'

copyExtra = require './_copyExtra'

processFields = require './_processFields'

processActions = (result, doc, config, noSystemItems) ->

  unless doc.$$src.hasOwnProperty('actions') or not noSystemItems

    EMPTY =

      $$list: []

      $$tags: {}

    EMPTY.$$tags.all = EMPTY.$$tags.none = new bitArray EMPTY

    EMPTY.$$tags.all.lock()

    return EMPTY # processActions =

  result.context (Result.prop 'actions'), -> # processActions =

    sortedMapOpts = {}

    unless noSystemItems

      sortedMapOpts.before = [
        {name: 'create', tags: 'system'}
        {name: 'retrieve', tags: 'system'}
        {name: 'update', tags: 'system'}
        {name: 'delete', tags: 'system'}
        {name: 'restore', tags: 'system'}
        {name: 'list', tags: 'system'}
      ]

      sortedMapOpts.reservedName = ['create', 'retrieve', 'update', 'delete', 'restore', 'list']

    res = sortedMap result, doc.$$src.actions or {}, sortedMapOpts

    unless result.isError

      action = undefined

      result.context ((path) -> (Result.prop action.name) path), ->

        for action in res.$$list when action.hasOwnProperty('$$src')

          if action.$$src.hasOwnProperty('skipValidate')

            unless typeof action.$$src.skipValidate == 'boolean'

              result.context (Result.prop 'skipValidate'), ->

                result.error 'validate.invalidValue', value: action.$$src.skipValidate

            else

              action.skipValidate = true if action.$$src.skipValidate

          if action.$$src.hasOwnProperty('static')

            unless typeof action.$$src.static == 'boolean'

              result.context (Result.prop 'static'), ->

                result.error 'validate.invalidValue', value: action.$$src.static

            else

              action.static = true if action.$$src.static

          if action.$$src.hasOwnProperty('arguments')

            action.arguments = processFields result, action, config, 'arguments', true

          if action.$$src.hasOwnProperty('result')

            action.result = processFields result, action, config, 'result', true

        return # result.context

      copyExtra result, res

      return if result.isError

      sortedMap.index result, res, mask: true

      return if result.isError

      compileTags result, res

      return if result.isError

      sortedMap.finish result, res, skipProps: ['tags', 'skipValidate', 'static']

      res unless result.isError # processActions =

# ----------------------------

module.exports = processActions
