BitArray = require '../bitArray'

freeze = (obj) ->

  if '_mask' in obj

    obj.$$list # force mask to compute list

  Object.freeze obj

EMPTY_LIST = freeze []

EMPTY_MAP_WITH_TAGS = freeze ({$$list: EMPTY_LIST, $$tags: EMPTY_TAGS})

EMPTY_MAP = freeze ({$$list: EMPTY_LIST})

EMPTY_MASK = freeze new BitArray EMPTY_MAP

EMPTY_TAGS = freeze {all: EMPTY_MASK}

EMPTY_FLAT_MAP = freeze ({$$list: EMPTY_LIST, $$flat: freeze {$$list: EMPTY_LIST}, $$tags: EMPTY_TAGS})

EMPTY_MAP_WITH_TAGS = Object.freeze({$$list: [], $$tags: EMPTY_TAGS})

linkSortedMap = (collection, noIndex, noFreeze) ->

  if collection == undefined

    return if noIndex then EMPTY_MAP else EMPTY_MAP_WITH_TAGS

  res = {}

  for v, i in collection.list

    res[v.name] = v

    v.$$index = i unless noIndex

  res.$$list = collection.list

  res.$$tags = linkTags res, collection if collection.tags

  if noFreeze then res else freeze res # linkSortedMap =

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

  res.$$tags = freeze tags # linkTags =

linkUDTypes = (config, list) ->

  for type in list

    type.refers = (config.docs[refName] for refName in type.refers) if type.hasOwnProperty('refers')

    type.enum = linkSortedMap type.enum, true if type.hasOwnProperty('enum')

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

link = (config) ->

  config.udtypes = linkSortedMap config.udtypes, true

  linkUDTypes config, config.udtypes.$$list

  config.docs = linkSortedMap config.docs, true

  for doc in config.docs.$$list

    doc.fields = linkFlatMap doc.fields, 'fields'

    linkFields config, doc.fields.$$flat.$$list

    doc.actions = linkSortedMap doc.actions

    doc.states = linkSortedMap doc.states, true

    for state in doc.states.$$list

      state.view = freeze new BitArray doc.fields.$$flat.$$list, state.view

      state.update = freeze new BitArray doc.fields.$$flat.$$list, state.update

      state.transitions = linkSortedMap state.transitions, true

      for transition in state.transitions.$$list

        transition.next = doc.states[transition.next]

        freeze transition

      freeze state

  config.api = linkSortedMap config.api, true

  for api in config.api.$$list

    api.methods = linkSortedMap api.methods

    for method in api.methods.$$list

      method.arguments = linkFlatMap method.arguments, 'fields'

      linkFields config, method.arguments.$$flat.$$list

      method.result = linkFlatMap method.result, 'fields'

      linkFields config, method.result.$$flat.$$list

      freeze method

    freeze api

  config # link =

# ----------------------------

module.exports = link
