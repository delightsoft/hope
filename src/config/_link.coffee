Result = require '../result'

BitArray = require '../bitArray'

calc = require '../tags/_calc'

hasOwnProperty = Object::hasOwnProperty

{isResult} = require '../utils/_err'

$$newBuilder = require './helpers/new'

{structure: validateStructure, addValidate} = require '../validate'

$$accessBuilder = require('./helpers/access')

$$validateBuilder = require('./helpers/validate')

$$editValidateBuilderBuilder = require('./helpers/editValidateBuilder')

$$getUpdateBuilder = require('./helpers/getUpdate')

$$applyUpdateBuilder = require('./helpers/applyUpdate')

snakeCase = require('lodash/snakeCase')

link = (config, noHelpers, opts) ->

  if typeof noHelpers == 'object' and noHelpers != null

    methods = noHelpers

    noHelpers = false

  freeze = (obj) ->

    if noHelpers then return obj

    if obj.hasOwnProperty('_mask')

      obj.list # force mask to compute list

    Object.freeze obj

  deepFreeze = (obj) ->

    freeze obj

    deepFreeze fld for fldName, fld of obj when typeof fld == 'object' && fld != null

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

      v.$$index = i unless noIndex

      res[v.name] = if noFreeze then v else freeze v

      deepFreeze v.extra if v.hasOwnProperty('extra')

    res.$$list = collection.list

    linkTags res, collection if collection.tags

    if noFreeze then res else (freeze res) # linkSortedMap =

  linkFlatMap = (collection, prop, noIndex, noMask, noFreeze) ->

    return EMPTY_FLAT_MAP if collection == undefined

    map = {}

    list = []

    _linkLevel = (level, prefix = '') ->

      for v in level

        v.$$index = list.length unless noIndex

        list.push v

        v[prop] = _linkLevel v[prop], "#{prefix}#{v.name}." if v.hasOwnProperty prop

        map["#{prefix}#{v.name}"] = v

      linkSortedMap {list: level}, true, prefix == '' || noFreeze # _linkLevel

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

    if noFreeze then res else (freeze res) # linkFlatMode =

  linkTags = (res, collection) ->

    tags =

      all: freeze (new BitArray res).invert()

    tags[k] = freeze (new BitArray res.$$flat?.$$list || res.$$list, v) for k, v of collection.tags

    tags = res.$$tags = freeze tags

    unless noHelpers

      cache = Object.create(null)

      noCache = (result, expr) ->

        unless typeof result == 'object' && result != null && result.hasOwnProperty('isError')

          localResult = true

          result = new Result()

          expr = result

        r = calc result, res, expr

        result.throwIfError() if localResult

        r # noCache =

      res.$$calc = (result, expr) ->

        unless typeof result == 'object' && result != null && result.hasOwnProperty('isError')

          expr = result

          result = undefined

        return cache[expr] if hasOwnProperty.call cache, expr

        result = new Result() unless result

        cache[expr] = noCache result, expr # res.$$calc =

      res.$$calc.noCache = noCache

    return # linkTags =

  linkFieldsWithHelpers = (obj, prop, prefix, isDoc) ->

    obj[prop] = linkFlatMap obj[prop], 'fields', false, false, true

    linkFields config, obj[prop].$$flat.$$list

    unless noHelpers

      assignKey = (fields, levelPrefix) ->

        for field in fields.$$list

          field.$$key = nextLevelPrefix = "#{levelPrefix}.field.#{field.name}"

          nextLevelPrefix = "type.#{field.udType[field.udType.length - 1]}" if field.hasOwnProperty('udType')

          assignKey field.fields, nextLevelPrefix if field.hasOwnProperty('fields')

          field.enum.$$list.forEach((e) -> e.$$key = "#{nextLevelPrefix}.enum.#{e.name}"; return) if field.hasOwnProperty('enum')

      assignKey obj[prop], prefix

      addValidate obj[prop]

      for field in obj[prop].$$flat.$$list when field.hasOwnProperty('fields')

        field.fields.$$new = $$newBuilder field.fields

      obj[prop].$$new = $$newBuilder obj[prop]

    for field in obj[prop].$$flat.$$list

      if opts?.server and isDoc

        field.$$field = snakeCase field.name

      field.enum.$$list.forEach ((i) -> freeze i; return) if field.hasOwnProperty('enum')

      freeze field.fields if field.hasOwnProperty('fields')

      freeze field

    return # linkFieldsWithHelpers =

  linkFields = (config, list) ->

    for field in list

      freeze field.udType if field.hasOwnProperty('udType')

      field.refers = (config.docs[refName] for refName in field.refers) if field.hasOwnProperty('refers')

      if field.hasOwnProperty('enum')

        field.enum = linkSortedMap field.enum, true, true

        freeze field.enum

        freeze field.enum.$$list

      if field.hasOwnProperty('regexp')

        i = regexp.lastIndexOf('/')

        field.regexp = new RegExp (field.regexp.substr 0, i - 1), (field.regexp.substr i + 1)

    return # linkFields =

  config.docs = linkSortedMap config.docs, true, true

  freeze config.docs

  freeze config.docs.$$list

  for doc in config.docs.$$list

    unless noHelpers

      doc.$$key = docKey = doc.name

    if opts and opts.server

      doc.$$table = snakeCase doc.name

    linkFieldsWithHelpers doc, 'fields', docKey, true

    doc.actions = linkSortedMap doc.actions, false, true

    doc.states = linkSortedMap doc.states, true, true

    unless noHelpers

      doc.actions.$$list.forEach (action) ->

        action.$$key = "#{docKey}.action.#{action.name}"

        freeze action

        return

      doc.$$access = $$accessBuilder doc, 'fields', methods and methods.docs[doc.name] and methods.docs[doc.name].access, true

      doc.$$validate = $$validateBuilder doc, 'fields', doc.$$access, methods and methods.docs[doc.name] and methods.docs[doc.name].validate

      doc.$$editValidateBuilder = $$editValidateBuilderBuilder doc, 'fields', doc.$$access, methods and methods.docs[doc.name] and methods.docs[doc.name].validate

      doc.$$getUpdate = $$getUpdateBuilder doc

      doc.$$applyUpdate = $$applyUpdateBuilder doc

    for state in doc.states.$$list

      unless noHelpers

        state.$$key = "#{docKey}.state.#{state.name}"

      state.view = freeze (new BitArray doc.fields.$$flat.$$list, state.view)

      state.update = freeze (new BitArray doc.fields.$$flat.$$list, state.update)

      state.transitions = linkSortedMap state.transitions, true, false

      for transition in state.transitions.$$list

        transition.next = doc.states[transition.next]

        freeze transition

      freeze state

    freeze doc

  config.api = linkSortedMap config.api, true, true

  freeze config.api

  freeze config.api.$$list

  for api in config.api.$$list

    unless noHelpers

      api.$$key = apiKey = "api.#{api.name}"

    api.methods = linkSortedMap api.methods, false, true

    freeze api.methods

    freeze api.methods.$$list

    for method in api.methods.$$list

      unless noHelpers

        method.$$key = "#{apiKey}.method.#{method.name}"

      linkFieldsWithHelpers method, 'arguments', "#{apiKey}.method.#{method.name}.arg"

      linkFieldsWithHelpers method, 'result', "#{apiKey}.method.#{method.name}.result"

      unless noHelpers

        method.arguments.$$access = $$accessBuilder method, 'arguments', methods and methods.api[api.name] and methods.api[api.name][method.name] and methods.api[api.name][method.name].argAccess
        method.arguments.$$validate = $$validateBuilder method, 'arguments', method.arguments.$$access, methods and methods.api[api.name] and methods.api[api.name][method.name] and methods.api[api.name][method.name].argValidE
        method.arguments.$$editValidateBuilder = $$editValidateBuilderBuilder method, 'arguments', method.arguments.$$access, method.arguments.$$access, methods and methods.api[api.name] and methods.api[api.name][method.name] and methods.api[api.name][method.name].argValidE

        method.result.$$access = $$accessBuilder method, 'result', methods and methods.api[api.name] and methods.api[api.name][method.name] and methods.api[api.name][method.name].resultAccess
        method.result.$$validate = $$validateBuilder method, 'result', method.result.$$access, methods and methods.api[api.name] and methods.api[api.name][method.name] and methods.api[api.name][method.name].resultValidate
        method.result.$$editValidateBuilder = $$editValidateBuilderBuilder method, 'result', method.arguments.$$access, method.arguments.$$access, methods and methods.api[api.name] and methods.api[api.name][method.name] and methods.api[api.name][method.name].resultValidate

      freeze method

    freeze api

  freeze config # link =

# ----------------------------

module.exports = link
