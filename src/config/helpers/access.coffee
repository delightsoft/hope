$$accessBuilder = (type, fieldsProp, access) ->

  if typeof access == 'function'

    access # (type, fieldsProp, access) ->

  else

    do ->

      allAccess =
        view: type[fieldsProp].$$tags.all
        update: type[fieldsProp].$$tags.all

      if type.hasOwnProperty('actions')
        allAccess.actions = type.actions.$$tags.all

      (doc) -> allAccess # (type, fieldsProp, access) ->

# ----------------------------

module.exports = $$accessBuilder
