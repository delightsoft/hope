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

      clone[prop] = unlinkLevel clone[prop] if clone.hasOwnProperty prop

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

  res[k] = v._mask for k, v of tags when k != 'all'

  res # unlinkTags =

unlinkField = (field) ->

  field.udType = field.udType[0] if field.hasOwnProperty('udType')

  field.refers = (ref.name for ref in field.refers) if field.hasOwnProperty('refers')

  return

unlinkUDType = (field) ->

  field.refers = (ref.name for ref in field.refers) if field.hasOwnProperty('refers')

  return

unlinkMethods = (methods) ->

  for method in methods.$$list

    res = lightClone method

    res.input = unlinkMap method.input if res.input.$$list.length > 0

    res.output = unlinkMap method.output if res.output.$$list.length > 0

    res

unlink = (config) ->

  newConfig = lightClone config

  unless config.udtypes.$$list.length > 0

    delete newConfig.udtypes

  else

    newConfig.udtypes = unlinkSortedMap newConfig.udtypes, unlinkUDType

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

        console.info 139, api

        unless api.hasOwnProperty('methods')

          delete api.methods

        else

          api.methods = unlinkSortedMap api.methods

          for method in api.methods.list

            console.info 143, method.input

            method.input = unlinkFlatMap method.input, 'fields', unlinkField if method.input.$$list.length > 0

            console.info 146, method.input

            method.output = unlinkFlatMap method.output, 'fields', unlinkField if method.output.$$list.length > 0

  newConfig

# ----------------------------

module.exports = unlink
