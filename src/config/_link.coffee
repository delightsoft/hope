BitArray = require '../bitArray'

linkSortedMap = (collection, noIndex) ->

  res = {}

  for v, i in collection

    res[v.name] = v

    v.$$index = i unless noIndex

  res.$$list = collection

  res # linkSortedMap =

linkFields = (collection) ->

  map = {}

  list = []

  _linkLevel = (level, prefix = '') ->

    for v in level

      v.$$index = list.length

      if level.hasOwnProperty('mask')

        v.$$mask = new BitArray collection, v.mask

        delete v.mask

      list.push v

      v.fields = _linkLevel v.fields, "#{prefix}#{v.name}." if v.hasOwnProperty 'fields'

      map["#{prefix}#{v.name}"] = v

    linkSortedMap level, true # _linkLevel

  res =  _linkLevel collection

  (res.$$flat = map).$$list = list

  res # linkFlatMap =

linkTags = (collection, tags) ->

  tags[k] = new BitArray collection, v for k, v of tags

  tags # linkTags =

link = (config) ->

  config.udtypes = linkSortedMap config.udtypes, true

  config.docs = linkSortedMap config.docs, true

  for doc in config.docs.$$list

    doc.fields = do ->

      res = linkFields doc.fields.list

      res.$$tags = linkTags res.$$flat.$$list, doc.fields.tags

      for field in res.$$flat.$$list

        if field.hasOwnProperty('udType')

          udt = config.udtypes[field.udType]

          udtList = [udt.name]

          while udt.hasOwnProperty('udType')

            udt = config.udtypes[udt.udType]

            udtList.push udt.name

          field.udType = udtList

        if field.hasOwnProperty('mask')

          field.$$mask = new BitArray res.$$flat.$$list, field.mask

          delete field.mask

        field.refers = (config.docs[refName] for refName in field.refers) if field.hasOwnProperty('refers')

      res

    doc.actions = do ->

      res = linkSortedMap doc.actions.list

      res.$$tags = linkTags res.$$list, doc.actions.tags

      res

    doc.states = linkSortedMap doc.states, true

    for state in doc.states.$$list

      state.view = new BitArray doc.fields.$$flat.$$list, state.view

      state.update = new BitArray doc.fields.$$list, state.update

      state.transitions = linkSortedMap state.transitions, true

      transition.next = doc.states[transition.next] for transition in state.transitions.$$list

  config # link =

# ----------------------------

module.exports = link
