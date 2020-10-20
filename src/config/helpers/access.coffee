freezeBitArray = (ba) ->

  ba._buildList().lock() # (ba) ->

modify = (body) ->

  view = r.view.clone()
  update = r.update.clone()
  required = r.required.clone()
  access = r.access?.clone()

  body view, update, required, access

  r =
    view: view.lock()
    update: update.lock()
    required: required.lock()
    access: access?.lock()

  r.modidy = modify

  r

$$accessBuilder = (type, fieldsProp, access, addActions) ->

  res = if typeof access == 'function'

    # TODO: Wrap and check result
    (fields) ->

      r = access.apply @, arguments # (type, fieldsProp, access) ->

      if addActions
        r.view = freezeBitArray if r.view then r.view.add(type[fieldsProp].$$calc('#system-options', strict: false)) else type[fieldsProp].$$tags.all
        r.update = freezeBitArray if r.update then r.update.add(type[fieldsProp].$$calc('id,rev,state,deleted', strict: false)) else type[fieldsProp].$$tags.all
        r.required = freezeBitArray r.required or type[fieldsProp].$$tags.required unless r.required
        r.actions = type.actions.$$tags.all unless r.actions
      else
        r.view = freezeBitArray type[fieldsProp].$$tags.all unless r.view
        r.update = freezeBitArray type[fieldsProp].$$tags.all unless r.update
        r.required = freezeBitArray r.required or type[fieldsProp].$$tags.required unless r.required

      r.modify = modify

      r # (fields) ->

  else

    do ->

      allAccess =
        view: (type[fieldsProp].$$calc '#all-options', strict: false)._buildList()
        update: (type[fieldsProp].$$calc '(#all-#system),id,rev,deleted', strict: false)._buildList()

      if addActions
        allAccess.required = type[fieldsProp].$$tags.required
        allAccess.actions = type.actions.$$tags.all

      allAccess.modify = modify

      (doc) -> allAccess # (type, fieldsProp, access) ->

  res
# ----------------------------

module.exports = $$accessBuilder
