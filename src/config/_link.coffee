Result = require '../result'

BitArray = require '../bitArray'

calc = require '../tags/_calc'

hasOwnProperty = Object::hasOwnProperty

{isResult} = require '../utils/_err'

link = (config, noHelpers) ->

  freeze = (obj) ->

    if noHelpers then return obj

    if obj.hasOwnProperty('_mask')

      obj.list # force mask to compute list

    Object.freeze obj

  EMPTY_LIST = freeze []

  EMPTY_MAP_WITH_TAGS = freeze ({$$list: EMPTY_LIST, $$tags: EMPTY_TAGS})

  EMPTY_MAP = freeze ({$$list: EMPTY_LIST})

  EMPTY_MASK = freeze (new BitArray EMPTY_MAP)

  EMPTY_TAGS = freeze {all: EMPTY_MASK}

  EMPTY_FLAT_MAP = freeze ({$$list: EMPTY_LIST, $$flat: freeze {$$list: EMPTY_LIST}, $$tags: EMPTY_TAGS})

  EMPTY_MAP_WITH_TAGS = Object.freeze {$$list: [], $$tags: EMPTY_TAGS}

  linkSortedMap = (collection, noIndex, noFreeze) ->

    if collection == undefined

      return if noIndex then EMPTY_MAP else EMPTY_MAP_WITH_TAGS

    res = {}

    for v, i in collection.list

      res[v.name] = v

      v.$$index = i unless noIndex

    res.$$list = collection.list

    linkTags res, collection if collection.tags

    if noFreeze then res else (freeze res) # linkSortedMap =

  linkFlatMap = (collection, prop, noIndex, noMask) ->

    return EMPTY_FLAT_MAP if collection == undefined

    map = {}

    list = []

    _linkLevel = (level, prefix = '') ->

      for v in level

        v.$$index = list.length unless noIndex

        list.push v

        v[prop] = _linkLevel v[prop], "#{prefix}#{v.name}." if v.hasOwnProperty prop

        map["#{prefix}#{v.name}"] = v

      linkSortedMap {list: level}, true, prefix == '' # _linkLevel

    res = _linkLevel collection.list

    (res.$$flat = map).$$list = freeze list

    freeze map

    linkTags res, collection if collection.tags

    unless noMask

      masks = []

      buildMask = (list) ->

        for item in list

          v.set item.$$index for v in masks

          if item.hasOwnProperty(prop)

            masks.push item.$$mask = mask = new BitArray res

            buildMask item[prop].$$list

            masks.pop()

        return # buildMask =

      buildMask res.$$list

    freeze res # linkFlatMode =

  linkTags = (res, collection) ->

    tags =

      all: freeze (new BitArray res).invert()

    tags[k] = freeze (new BitArray res.$$flat?.$$list || res.$$list, v) for k, v of collection.tags

    tags = res.$$tags = freeze tags

    cache = Object.create(null)

    unless noHelpers

      noCache = (result, expr) ->

        unless typeof result == 'object' && result != null && result.hasOwnProperty('isError')

          localResult = true

          result = new Result()

          expr = result

        res = calc result, res, expr

        result.throwIfError() if localResult

        res # noCache =

      res.$$calc = (result, expr) ->

        unless typeof result == 'object' && result != null && result.hasOwnProperty('isError')

          expr = result

          result = undefined

        return cache[expr] if hasOwnProperty.call cache, expr

        result = new Result() unless result

        cache[expr] = noCache result, expr # res.$$calc =

      res.$$calc.noCache = noCache

    return # linkTags =

  linkUDTypes = (config, list) ->

    for type in list

      type.refers = (config.docs[refName] for refName in type.refers) if type.hasOwnProperty('refers')

      type.enum = linkSortedMap type.enum, true, false if type.hasOwnProperty('enum')

    return # linkUDTypes =

  linkFields = (config, list) ->

    for field in list

      if field.hasOwnProperty('udType')

        udt = config.udtypes[field.udType]

        udtList = [udt.name]

        while udt.hasOwnProperty('udType')

          udt = config.udtypes[udt.udType]

          udtList.push udt.name

        field.udType = freeze udtList

      field.refers = (config.docs[refName] for refName in field.refers) if field.hasOwnProperty('refers')

      field.enum = linkSortedMap field.enum, true if field.hasOwnProperty('enum')

      freeze field

    return # linkFields =

  config.udtypes = linkSortedMap config.udtypes, true, false

  linkUDTypes config, config.udtypes.$$list

  config.docs = linkSortedMap config.docs, true, false

  for doc in config.docs.$$list

    doc.fields = linkFlatMap doc.fields, 'fields', false, false

    linkFields config, doc.fields.$$flat.$$list

    doc.actions = linkSortedMap doc.actions, false, false

    doc.states = linkSortedMap doc.states, true, false

    for state in doc.states.$$list

      state.view = freeze (new BitArray doc.fields.$$flat.$$list, state.view)

      state.update = freeze (new BitArray doc.fields.$$flat.$$list, state.update)

      state.transitions = linkSortedMap state.transitions, true, false

      for transition in state.transitions.$$list

        transition.next = doc.states[transition.next]

        freeze transition

      freeze state

  config.api = linkSortedMap config.api, true, false

  for api in config.api.$$list

    api.methods = linkSortedMap api.methods, false, false

    for method in api.methods.$$list

      method.arguments = linkFlatMap method.arguments, 'fields', false, false

      linkFields config, method.arguments.$$flat.$$list

      method.result = linkFlatMap method.result, 'fields', false, false

      linkFields config, method.result.$$flat.$$list

      freeze method

    freeze api

  config # link =

# ----------------------------

module.exports = link
