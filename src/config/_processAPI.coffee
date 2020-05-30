{checkDocumentName} = require '../utils'

Result = require '../result'

sortedMap = require '../sortedMap'

processFields = require './_processFields'

copyOptions = require './_copyOptions'

{compile: compileTags} = require '../tags'

processAPI = (result, config) ->

  unless config.$$src.hasOwnProperty('api')

    return {}

  result.context (Result.prop 'api'), -> # processDocs =

    res = sortedMap result, config.$$src.api

    unless result.isError

      api = undefined

      result.context ((path) -> (Result.item api.name) path), ->

        for api in res.$$list

          continue unless api.$$src

          unless api.$$src.hasOwnProperty('methods')

            result.warn 'missingProp', value: 'methods'

          else

            result.context ((path) -> (Result.prop 'methods') path), ->

            api.methods = sortedMap result, api.$$src.methods

            unless result.isError

              method = undefined

              result.context ((path) -> (Result.item method.name) path), ->

                for method in api.methods.$$list

                  continue unless method.$$src

                  for prop in ['input', 'output']

                    unless method.hasOwnProperty(prop)

                      method[prop] = {}

                    else

                      method[prop] = processFields result, method, config, prop

                return # result.context

              copyOptions result, api.methods

              # rule: api.methods.$$list is sorted in alphabetical order of their names
              api.methods.$$list.sort (left, right) -> left.name.localeCompare right.name

              compileTags result, api.methods

              sortedMap.finish result, api.methods, skipProps: ['tags']

        return # result.context

      copyOptions result, res

      # rule: api.$$list is sorted in alphabetical order of their names
      res.$$list.sort (left, right) -> left.name.localeCompare right.name

      compileTags result, res

      sortedMap.finish result, res, skipProps: ['tags']

      unless result.isError

        config.api = res unless result.isError

      return # processDocs = (result, config) ->

# ----------------------------

module.exports = processAPI
