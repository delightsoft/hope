BitArray = require '../../bitArray'

{err: {invalidArg}} = require '../../utils'

$$docAccessBuilder = (docDesc, access, rights) ->

  unless rights

    (doc, user) ->

      invalidArg 'doc', doc unless doc == null or (typeof doc == 'object' and not Array.isArray(doc))
      invalidArg 'user', user unless user == null or (typeof user == 'object' and not Array.isArray(user))

      access.call docDesc, doc, user # (doc, user) ->

  else

    (doc, user) ->

      invalidArg 'doc', doc unless doc == null or (typeof doc == 'object' and not Array.isArray(doc))
      invalidArg 'user', user unless user == null or (typeof user == 'object' and not Array.isArray(user))

      docAccess = access.call docDesc, doc, user

      docRights =

        doc: doc
        user: user

        view: allFields = (new BitArray docDesc.fields).set('#all-options', {strict: false})
        update: allFields.clone()
        fullFields: allFields.clone()
        relations: new BitArray docDesc.fields

        actions: allActions = (new BitArray docDesc.actions).invert()
        fullActions: allActions.clone()

      rights.call docDesc, docRights

      docRights.view.subtract('options', {strict: false}).add('id').lock()
      docRights.update.subtract('#system', {strict: false}).lock()
      docRights.fullFields.add('id').lock()
      docRights.relations.lock()

      docRights.actions.lock()
      docRights.fullActions.lock()

      #      console.info 46, docRights.fullFields.list.map((v) => v.fullname or v.name).join(', ')

      viewExceedFullRights = docRights.view.subtract(docRights.fullFields)
      unless viewExceedFullRights.isEmpty()
        (error or (error = []))
          .push "Doc '#{docDesc.name}': view rights exceeds full rights: #{viewExceedFullRights.list.map((v) -> v.fullname or v.name).join(', ')}"

      updateExceedFullRights = docRights.update.subtract(docRights.fullFields)
      unless updateExceedFullRights.isEmpty()
        (error or (error = []))
          .push "Doc '#{docDesc.name}': update rights exceeds full rights: #{updateExceedFullRights.list.map((v) -> v.fullname or v.name).join(', ')}"

      actionsExceedFullRights = docRights.actions.subtract(docRights.fullActions)
      unless actionsExceedFullRights.isEmpty()
        (error or (error = []))
          .push "Doc '#{docDesc.name}': actions rights exceeds full rights: #{actionsExceedFullRights.list.map((v) -> v.name).join(', ')}"

      relationsMissingInViewAndUpdate = docRights.relations.subtract(docRights.view).subtract(docRights.update)
      unless relationsMissingInViewAndUpdate.isEmpty()
        (error or (error = []))
          .push "Doc '#{docDesc.name}': relations missing in view and update: #{relationsMissingInViewAndUpdate.list.map((v) -> v.fullname or v.name).join(', ')}"

      throw new Error error.join('\n') if error

      docAccess.modify ({view, update, actions}) -> # (doc, user) ->

        view.and(docRights.view.or(docRights.update))

        update.and docRights.update

        actions.and docRights.actions

        return # (view, update, actions) ->

# ----------------------------

module.exports = $$docAccessBuilder
