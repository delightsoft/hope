freezeBitArray = (ba) ->

  # _buildList() чтобы тесты срабатывали когда маски сравниваются с тегами

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

  r.modify = modify

  r

$$accessBuilder = (type, fieldsProp, access, isDoc) ->

  res = if typeof access == 'function'

    # TODO: Wrap and check result
    (fields) ->

      r = access.apply @, arguments # (type, fieldsProp, access) ->

      if isDoc

        r.actions = type.actions.$$tags.all unless r.actions

        r.view = if r.view
          freezeBitArray r.view.add '#system-options', strict: false
        else
          type[fieldsProp].$$tags.all

        r.update = if r.update

            r.update = r.update.remove('#system+#computed', strict: false)

            r.update = r.update.add('deleted') if type.actions.delete and r.actions.get type.actions.delete.$$index # в тестах может не быть системных действий

            freezeBitArray r.update

        else

            type[fieldsProp].$$calc '(#all-#system-#computed),deleted', strict: false

        r.required = freezeBitArray r.required or type[fieldsProp].$$tags.required unless r.required

      else

        r.view = type[fieldsProp].$$tags.all unless r.view
        r.update = type[fieldsProp].$$tags.all unless r.update
        r.required = type[fieldsProp].$$tags.required unless r.required

      r.modify = modify

      r # (fields) ->

  else

    do ->

      allAccess =
        view: type[fieldsProp].$$calc '#all-options', strict: false
        update: type[fieldsProp].$$calc '(#all-#system-#computed),deleted', strict: false
        required: type[fieldsProp].$$tags.required

      if isDoc
        allAccess.actions = type.actions.$$tags.all

      allAccess.modify = modify

      (doc) -> allAccess # (type, fieldsProp, access) ->

  res
# ----------------------------

module.exports = $$accessBuilder
