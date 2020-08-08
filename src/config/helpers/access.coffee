$$accessBuilder = (type, fieldsProp, access, addActions) ->

  if typeof access == 'function'

    # TODO: Wrap and check result

    access # (type, fieldsProp, access) ->

  else

    do ->

      exceptSystem = if type[fieldsProp].$$tags.hasOwnProperty('system') then type[fieldsProp].$$tags.system.invert() else type[fieldsProp].$$tags.all

      allAccess =
        view: exceptSystem
        update: exceptSystem

      allAccess.actions = type.actions.$$tags.all if addActions

      if type.hasOwnProperty('actions')
        allAccess.actions = type.actions.$$tags.all

      (doc) -> allAccess # (type, fieldsProp, access) ->

# ----------------------------

module.exports = $$accessBuilder
