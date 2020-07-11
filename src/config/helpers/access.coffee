$$accessBuilder = (type, fieldsProp, access, addActions) ->

  if typeof access == 'function'

    # TODO: Wrap and check result

    access # (type, fieldsProp, access) ->

  else

    do ->

      allAccess =
        view: type[fieldsProp].$$tags.all
        update: type[fieldsProp].$$tags.all

      allAccess.actions = type.actions.$$tags.all if addActions

      if type.hasOwnProperty('actions')
        allAccess.actions = type.actions.$$tags.all

      (doc) -> allAccess # (type, fieldsProp, access) ->

# ----------------------------

module.exports = $$accessBuilder
