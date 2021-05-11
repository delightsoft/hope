{err: {invalidArg}} = require '../../utils'

modify = (body) ->

  res =
    view: @view.clone()
    update: @update.clone()
    required: @required.clone()

  res.access = @access.clone() if @access

  body res

  res.view.lock()
  res.update.lock()
  res.required.lock()
  res.access.lock() if @access

  res.modify = modify

  res

$$accessBuilder = (docDesc, fieldsProp, access, isDoc) ->

    if typeof access == 'function'

      unless isDoc

        (doc) ->

          invalidArg 'doc', doc unless doc == null or (typeof doc == 'object' and not Array.isArray(doc))

          res =
            doc: doc
            view: docDesc[fieldsProp].$$tags.all.clone()
            update: docDesc[fieldsProp].$$tags.all.clone()
            required: docDesc[fieldsProp].$$tags.required.clone()

          access.call @, res

          res.view.lock()
          res.update.lock()
          res.required.lock()

          delete res.doc
          res.modify = modify

          res # (doc) ->

      else

        (doc) ->

          invalidArg 'doc', doc unless doc == null or (typeof doc == 'object' and not Array.isArray(doc))

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

        (doc) ->

          invalidArg 'doc', doc unless doc == null or (typeof doc == 'object' and not Array.isArray(doc))

          allAccess

# ----------------------------

module.exports = $$accessBuilder
