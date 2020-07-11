Result = require '../result'

sortedMap = require '../sortedMap'

bitArray = require '../bitArray'

{compile: compileTags} = require '../tags'

copyExtra = require './_copyExtra'

processActions = (result, doc, noSystemItems) ->

  unless doc.$$src.hasOwnProperty('actions') or not noSystemItems

    return { # processActions =

      $$list: []

      $$tags: {all: new bitArray {$$list: []}}}

  result.context (Result.prop 'actions'), -> # processActions =

    sortedMapOpts = index: true

      , getValue: (result, value, res) ->

        if typeof value == 'function'

          # TODO: Check number of parameters in given function

          res.value = value

          return true

        false

    unless noSystemItems

      sortedMapOpts.before = [
        # TODO: Think of replacement of 'value'
        {name: 'create', tags: 'system', value: ->}
        {name: 'retrieve', tags: 'system', value: ->}
        {name: 'update', tags: 'system', value: ->}
        {name: 'delete', tags: 'system', value: ->}
        {name: 'restore', tags: 'system', value: ->}
      ]

      sortedMapOpts.reservedName = ['create', 'retrieve', 'update', 'delete', 'restore']

    res = sortedMap result, doc.$$src.actions or {}, sortedMapOpts

    unless result.isError

      action = undefined

      result.context ((path) -> (Result.prop action.name) path), ->

        for action in res.$$list when action.hasOwnProperty('$$src')

          unless action.$$src.hasOwnProperty('value')

            result.error 'dsc.missingProp', value: 'value'

          else unless typeof action.$$src.value == 'function'

            result.error 'dsc.invalidValue', value: action.$$src.value

          else

            # TODO: Check number of parameters in given function

            action.value = action.$$src.value

        return # result.context

      copyExtra result, res

      compileTags result, res

      sortedMap.finish result, res, skipProps: ['tags']

      res unless result.isError # processActions =

# ----------------------------

module.exports = processActions
