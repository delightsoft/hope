$$rightsBuilder = (docDesc, rootRights, docRights) ->

  funcs = []

  funcs.push rootRights.fullRights if rootRights?.fullRights

  funcs.push rootRights.relations if rootRights?.fullRights

  funcs.push rootRights.rights if rootRights?.fullRights

  funcs.push docRights.fullRights if docRights?.fullRights

  funcs.push docRights.relations if docRights?.fullRights

  funcs.push docRights.rights if docRights?.fullRights

  (args) -> # args: {doc, user, view, update, actions, relations, fullFields, fullActions}

    args.docDesc = docDesc

    funcs.forEach (f) -> f(args)

    return

# ----------------------------

module.exports = $$rightsBuilder
