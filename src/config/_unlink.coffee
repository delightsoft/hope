{lightClone} = require '../utils'

unlinkSortedMap = (collection, process) ->

  res =

    list:

      for item in collection.$$list

        newItem = lightClone item

        process? newItem

        newItem

  if collection.$$tags

    res.tags = unlinkTags collection.$$tags

  res # unlinkSortedMap =

unlinkFlatMap = (collection, prop, process) ->

  unlinkLevel = (level) ->

    for item in level

      clone = (lightClone item)

      clone[prop] = unlinkLevel clone[prop].$$list if clone.hasOwnProperty prop

      process? clone

      clone

  res =

    list:

      unlinkLevel collection.$$list

  if collection.$$tags

    res.tags = unlinkTags collection.$$tags

  res # unlinkFlatMap =

unlinkTags = (tags) ->

  res = {}

  res[k] = v._mask for k, v of tags when not ~['all', 'none'].indexOf(k)

  res # unlinkTags =

unlinkField = (field) ->

  field.refers = (ref.name for ref in field.refers) if field.hasOwnProperty('refers')

  field.enum = unlinkSortedMap field.enum if field.hasOwnProperty('enum')

  delete field._validate

  return

unlink = (config) ->

  newConfig = lightClone config

  unless config.docs.$$list.length > 0

    delete newConfig.docs

  else

    newConfig.docs = unlinkSortedMap newConfig.docs

    for newDoc in newConfig.docs.list

      newDoc.fields = unlinkFlatMap newDoc.fields, 'fields', unlinkField

      newDoc.actions = unlinkSortedMap newDoc.actions

      newDoc.states = unlinkSortedMap newDoc.states

      for newState in newDoc.states.list

        newState.view = newState.view._mask

        newState.update = newState.update._mask

        newState.transitions = unlinkSortedMap newState.transitions

        for newTran in newState.transitions.list

          newTran.next = newTran.next.name

  unless newConfig.api.$$list.length > 0

    delete newConfig.api

  else

    newConfig.api = unlinkSortedMap newConfig.api

    for api in newConfig.api.list

      unless api.methods.$$list.length > 0

        delete api.methods

      else

        unless api.hasOwnProperty('methods')

          delete api.methods

        else

          api.methods = unlinkSortedMap api.methods

          for method in api.methods.list

            method.arguments = unlinkFlatMap method.arguments, 'fields', unlinkField if method.arguments.$$list.length > 0

            method.result = unlinkFlatMap method.result, 'fields', unlinkField if method.result.$$list.length > 0

  newConfig

# ----------------------------

module.exports = unlink
