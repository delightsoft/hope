{err: {invalidArg}} = require '../../utils'

modify = (body) ->

  res =
    view: @view.clone()
    update: @update.clone()
    required: @required.clone()

  res.actions = @actions.clone() if @actions

  body res

  res.view.lock()
  res.update.lock()
  res.required.lock()
  res.actions.lock() if @actions

  res.modify = modify

  res

$$accessBuilder = (docDesc, fieldsProp, access, isDoc) ->

    if typeof access == 'function'

      unless isDoc

        (doc, user) ->

          invalidArg 'doc', doc unless doc == null or (typeof doc == 'object' and not Array.isArray(doc))
          invalidArg 'user', user unless user == null or (typeof user == 'object' and not Array.isArray(user))

          res =
            doc: doc
            view: docDesc[fieldsProp].$$tags.all.clone()
            update: docDesc[fieldsProp].$$tags.all.clone()
            required: docDesc[fieldsProp].$$tags.required.clone()

          access.call @, res

          # root access.js ???
          # default ???
          #  - empty
          #  - all system actions ?

          # TODO: doc == null -> system only list, all fields except options, static actions

          # TODO: doc != null && states -> view, update according to the stete, actions mentioned in the state, non static actions with proper mask without state transition

          # TODO: doc != null && no retrieve -> no fields, no action
          # TODO: doc != null && no update -> update fields is empty
          # TODO: doc != null -> system all except list, non static actions
          # TODO: doc != null && doc.id != null -> no create, update
          # TODO: doc != null && doc.id == null -> create, no update, no delete, no restore
          # TODO: doc != null -> all fields except options

          res.view.lock()
          res.update.lock()
          res.required.lock()

          delete res.doc
          res.modify = modify

          res # (doc) ->

      else

        (doc, user) ->

          invalidArg 'doc', doc unless doc == null or (typeof doc == 'object' and not Array.isArray(doc))
          invalidArg 'user', user unless user == null or (typeof user == 'object' and not Array.isArray(user))

          res =
            doc: doc
            view: docDesc[fieldsProp].$$tags.all.clone()
            update: docDesc[fieldsProp].$$tags.all.clone()
            required: docDesc[fieldsProp].$$tags.required.clone()
            actions: docDesc.actions.$$tags.all.clone()

          access.call @, res

          res.view.add('#system', strict: false).remove('options', strict: false).lock()

          res.update = if res.update

              res.update = res.update.remove('#system+#computed', strict: false)

              res.update = res.update.add('deleted') if docDesc.actions.delete and res.actions.get docDesc.actions.delete.$$index # в тестах может не быть системных действий

              res.update.lock()

          else

              docDesc[fieldsProp].$$calc '(#all-#system-#computed),deleted', strict: false

          res.view.lock()
          res.update.lock()
          res.required.lock()
          res.actions.lock()

          delete res.doc
          res.modify = modify

          res # (doc) ->

    else

      do ->

        allAccess =
          view: docDesc[fieldsProp].$$calc '#all-options', strict: false
          update: docDesc[fieldsProp].$$calc '(#all-#system-#computed),deleted', strict: false
          required: docDesc[fieldsProp].$$tags.required

        if isDoc
          allAccess.actions = docDesc.actions.$$tags.all

        allAccess.modify = modify

        (doc, user) ->

          invalidArg 'doc', doc unless doc == null or (typeof doc == 'object' and not Array.isArray(doc))
          invalidArg 'user', user unless user == null or (typeof user == 'object' and not Array.isArray(user))

          allAccess

# ----------------------------

module.exports = $$accessBuilder
