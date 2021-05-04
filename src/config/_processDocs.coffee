Result = require '../result'

{checkDocumentName} = require '../utils'

sortedMap = require '../sortedMap'

compileTags = require '../tags/_compile'

processFields = require './_processFields'

processActions = require './_processActions'

processStates = require './_processStates'

processRefers = require './_processRefers'

copyExtra = require './_copyExtra'

processDocs = (result, config, noSystemItems) ->

  unless config.$$src.hasOwnProperty('docs')

    result.error 'dsc.missingProp', value: 'docs'

    return

  result.context (Result.prop 'docs'), -> # processDocs =

    res = sortedMap result, config.$$src.docs, checkName: (v) ->

      return false unless checkDocumentName v

      # rule: 'doc.' is a default namespace
      return "doc.#{v}" if v.indexOf('.') == -1

      return true

    unless result.isError

      doc = undefined

      result.context ((path) -> (Result.prop doc.name) path), ->

        for doc in res.$$list

          result.isError = false

          doc.fields = processFields result, doc, config, 'fields', noSystemItems

          doc.actions = processActions result, doc, config, noSystemItems

          unless result.isError

            doc.states = processStates result, doc, doc.fields, doc.actions

        return # result.context

      # rule: docs.$$list is sorted in alpabetical order of their names
      res.$$list.sort (left, right) -> left.name.localeCompare right.name

      copyExtra result, res

      sortedMap.index result, res, mask: true

      compileTags result, res

      return if result.isError

      sortedMap.finish result, res

      return if result.isError

      processRefers result, res

      config.docs = res unless result.isError

      return # processDocs = (result, config) ->

# ----------------------------

module.exports = processDocs
