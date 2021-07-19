$$rightsBuilder = (docDesc, rootRights, docRights) ->

  funcs = []

  funcs.push rootRights.fullRights if rootRights?.fullRights

  funcs.push rootRights.relations if rootRights?.fullRights

  funcs.push rootRights.rights if rootRights?.fullRights

  funcs.push docRights.fullRights if docRights?.fullRights

  funcs.push docRights.relations if docRights?.fullRights

  funcs.push docRights.rights if docRights?.fullRights

  if funcs.length > 0 # args: {doc, user, view, update, actions, relations, fullFields, fullActions}

    (args) ->

      funcs.forEach (f) => f.call @, args

      return # (args) ->

# ----------------------------

module.exports = $$rightsBuilder
