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

    EMPTY.$$tags.all.list

    return EMPTY # processActions =

  result.context (Result.prop 'actions'), -> # processActions =

    sortedMapOpts = index: true

    unless noSystemItems

      sortedMapOpts.before = [
        # TODO: Think of replacement of 'value'
        {name: 'create', tags: 'system'}
        {name: 'retrieve', tags: 'system'}
        {name: 'update', tags: 'system'}
        {name: 'delete', tags: 'system'}
        {name: 'restore', tags: 'system'}
      ]

      sortedMapOpts.reservedName = ['create', 'retrieve', 'update', 'delete', 'restore']

    res = sortedMap result, doc.$$src.actions or {}, sortedMapOpts

    unless result.isError

      action = undefined

      result.context ((path) -> (Result.prop action.name) path), ->

        for action in res.$$list when action.hasOwnProperty('$$src')

          if action.$$src.hasOwnProperty('arguments')

            action.arguments = processFields result, action, config, 'arguments', true

        return # result.context

      copyExtra result, res

      compileTags result, res

      sortedMap.finish result, res, skipProps: ['tags']

      res unless result.isError # processActions =

# ----------------------------

module.exports = processActions
