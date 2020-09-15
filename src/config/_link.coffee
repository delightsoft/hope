Result = require '../result'

BitArray = require '../bitArray'

hasOwnProperty = Object::hasOwnProperty

{isResult} = require '../utils/_err'

$$calcBuilder = require './helpers/calc'

$$fixBuilder = require './helpers/fix'

$$newBuilder = require './helpers/new'

$$getBuilder = require './helpers/get'

$$setBuilder = require './helpers/set'

$$updateBuilder = require './helpers/update'

$$wasTouchedBuilder = require './helpers/wasTouched'

$$vueDebugWatchBuilderBuilder = require './helpers/vueDebugWatchBuilder'

{structure: validateStructure, addValidate} = require '../validate'

$$accessBuilder = require('./helpers/access')

$$validateBuilder = require('./helpers/validate')

$$editValidateBuilder = require('./helpers/editValidate')

snakeCase = require('lodash/snakeCase')

link = (config, noHelpers, opts) ->

  if typeof noHelpers == 'object' and noHelpers != null

    methods = noHelpers

    noHelpers = false

  freeze = (obj) ->

    if noHelpers then return obj

    if obj.hasOwnProperty('_mask')

      obj._buildList().lock()

    Object.freeze obj

  deepFreeze = (obj) ->

    freeze obj

    deepFreeze fld for fldName, fld of obj when typeof fld == 'object' && fld != null

  freezeBitArray = (ba) ->

    ba.lock()

    freeze ba # (ba) ->


  EMPTY_LIST = freeze []


  EMPTY_MAP = {$$list: EMPTY_LIST}

  EMPTY_MASK = freezeBitArray new BitArray EMPTY_MAP

  EMPTY_MAP.$$tags = freeze {all: EMPTY_MASK, none: EMPTY_MASK}

  freeze EMPTY_MAP


  EMPTY_MAP_WITH_TAGS = {$$list: EMPTY_LIST}

  EMPTY_MASK_WITH_TAGS = freezeBitArray new BitArray EMPTY_MAP_WITH_TAGS

  EMPTY_MAP_WITH_TAGS.$$tags = freeze {all: EMPTY_MASK_WITH_TAGS, none: EMPTY_MASK_WITH_TAGS}

  freeze EMPTY_MAP_WITH_TAGS


  EMPTY_FLAT_MAP = $$list: EMPTY_LIST, $$flat: freeze {$$list: EMPTY_LIST}

  EMPTY_FLAT_MAP_TAGS = freezeBitArray new BitArray EMPTY_MAP_WITH_TAGS

  EMPTY_FLAT_MAP.$$tags = freeze {all: EMPTY_FLAT_MAP_TAGS, none: EMPTY_FLAT_MAP_TAGS}

  freeze EMPTY_FLAT_MAP


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

      all: freezeBitArray (new BitArray res).invert()

      none: freezeBitArray new BitArray res

    if res.$$flat # only 'fields' are flatMap

      requiredMask = tags.required = new BitArray res

      requiredMask.set fld.$$index for fld in res.$$flat.$$list when fld.required

      freezeBitArray(requiredMask)

    tags[k] = freezeBitArray (new BitArray res.$$flat?.$$list or res.$$list, v, res) for k, v of collection.tags

    tags = res.$$tags = freeze tags

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

      addValidate obj[prop], obj[prop], methods?.validators

      for field in obj[prop].$$flat.$$list when ~['structure', 'subtable'].indexOf field.type

        if field.type == 'subtable'

          field.fields.$$fix = $$fixBuilder field.fields, obj[prop]

          field.fields.$$new = $$newBuilder field.fields

          field.fields.$$get = $$getBuilder field.fields

          field.fields.$$set = $$setBuilder field.fields

        field.fields.$$wasTouched = $$wasTouchedBuilder field.fields

      obj[prop].$$calc = $$calcBuilder obj[prop]

      obj[prop].$$fix = $$fixBuilder obj[prop], obj[prop]

      obj[prop].$$new = $$newBuilder obj[prop]

      obj[prop].$$get = $$getBuilder obj[prop]

      obj[prop].$$set = $$setBuilder obj[prop]

      obj[prop].$$update = $$updateBuilder obj

      obj[prop].$$wasTouched = $$wasTouchedBuilder obj[prop]

      obj[prop].$$vueDebugWatchBuilder = $$vueDebugWatchBuilderBuilder obj[prop] unless opts?.server

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

        i = field.regexp.lastIndexOf('/')

        field.regexp = new RegExp (field.regexp.substr 1, i - 1), (field.regexp.substr i + 1)

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

    doc.actions.$$list.forEach (action) ->

      linkFieldsWithHelpers action, 'arguments' if action.arguments

      return

    doc.states = linkSortedMap doc.states, true, true

    unless noHelpers

      actions = methods?.docs?[doc.name]?.actions

      doc.actions.$$list.forEach (action) ->

        action.$$key = "#{docKey}.action.#{action.name}"

        if action.arguments

          action.arguments.$$access = $$accessBuilder action, 'arguments', actions?["#{action.name}Access"]

          action.arguments.$$validate = $$validateBuilder action, 'arguments', actions?["#{action.name}Validate"]

          action.arguments.$$editValidate = $$editValidateBuilder action, 'arguments', action.arguments.$$access, actions?["#{action.name}Validate"]

        action.$$code = actions[action.name] if actions and actions[action.name]

        freeze action

        return

      doc.$$access = $$accessBuilder doc, 'fields', methods?.docs?[doc.name]?.access, true

      doc.$$validate = $$validateBuilder doc, 'fields', methods?.docs?[doc.name]?.validate

      doc.$$editValidate = $$editValidateBuilder doc, 'fields', doc.$$access, methods?.docs?[doc.name]?.validate

      doc.fields.$$validate = $$validateBuilder doc, 'fields', methods?.docs?[doc.name]?.validate

      doc.fields.$$editValidate = $$editValidateBuilder doc, 'fields', doc.$$access, methods?.docs?[doc.name]?.validate

    for state in doc.states.$$list

      unless noHelpers

        state.$$key = "#{docKey}.state.#{state.name}"

      state.view = freezeBitArray new BitArray doc.fields.$$flat.$$list, state.view, doc.fields

      state.update = freezeBitArray new BitArray doc.fields.$$flat.$$list, state.update, doc.fields

      state.transitions = linkSortedMap state.transitions, true, true

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

    unless api.methods

      api.methods = EMPTY_MAP_WITH_TAGS

    else

      api.methods = linkSortedMap api.methods, false, true

      freeze api.methods

      freeze api.methods.$$list

      for method in api.methods.$$list

        unless noHelpers

          method.$$key = "#{apiKey}.method.#{method.name}"

        linkFieldsWithHelpers method, 'arguments', "#{apiKey}.method.#{method.name}.arg"

        linkFieldsWithHelpers method, 'result', "#{apiKey}.method.#{method.name}.result"

        unless noHelpers

          method.arguments.$$access = $$accessBuilder method, 'arguments', methods?.api?[api.name]?[method.name]?.argAccess
          method.arguments.$$validate = $$validateBuilder method, 'arguments', methods?.api?[api.name]?[method.name]?.argValidE
          method.arguments.$$editValidate = $$editValidateBuilder method, 'arguments', method.arguments.$$access, methods?.api?[api.name]?[method.name]?.argValidate

          method.result.$$access = $$accessBuilder method, 'result', methods?.api?[api.name]?[method.name]?.resultAccess
          method.result.$$validate = $$validateBuilder method, 'result', methods?.api?[api.name]?[method.name]?.resultValidate
          method.result.$$editValidate = $$editValidateBuilder method, 'result', method.arguments.$$access, methods?.api?[api.name]?[method.name]?.resultValidate

        freeze method

    freeze api

  freeze config # link =

# ----------------------------

module.exports = link
