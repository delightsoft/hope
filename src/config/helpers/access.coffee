freezeBitArray = (ba) ->

  ba.list

  ba # (ba) ->

$$accessBuilder = (type, fieldsProp, access, addActions) ->

  if typeof access == 'function'

    # TODO: Wrap and check result
    (fields) ->

      r = access.apply @, arguments # (type, fieldsProp, access) ->

      if addActions
        r.view = freezeBitArray if r.view then r.view.or(type[fieldsProp].$$calc('#system-options', strict: false)) else type[fieldsProp].$$tags.all
        r.update = freezeBitArray if r.update then r.update.or(type[fieldsProp].$$calc('id,rev,deleted', strict: false)) else type[fieldsProp].$$tags.all
        r.required = freezeBitArray r.required or type[fieldsProp].$$tags.required unless r.required
        r.actions = type.actions.$$tags.all unless r.actions
      else
        r.view = type[fieldsProp].$$tags.all unless r.view
        r.update = type[fieldsProp].$$tags.all unless r.update

      r # (fields) ->

  else

    do ->

      allAccess =
        view: type[fieldsProp].$$calc '#all-options', strict: false
        update: type[fieldsProp].$$calc '(#all-#system),id,rev,deleted', strict: false

      if addActions
        allAccess.required = type[fieldsProp].$$tags.required
        allAccess.actions = type.actions.$$tags.all

      (doc) -> allAccess # (type, fieldsProp, access) ->

# ----------------------------

module.exports = $$accessBuilder
