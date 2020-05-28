Result = require '../result'

processRefers = (result, docs) ->

  _processRef = (doc, ref) ->

    refers = (if ref.indexOf('.') != -1 then ref
    else doc.name.substr(0, (doc.name.lastIndexOf('.') + 1)) + ref)

    unless docs.hasOwnProperty(refers)

      result.error 'dsc.unknownDocument', value: refers

      return

    docs[refers] # _processRef

  _processRefsArray = (doc, field, refList) ->

    isAll = false

    res = []

    i = undefined

    result.context ((path) -> (Result.index i, Result.prop 'refers') path), ->

      for ref, i in refList

        ref = ref.trim()

        result.isError = false

        if ref == '#all'

          isAll = true

        else

          v = _processRef doc, ref

          res.push v unless result.isError || res.indexOf(v) >= 0

    field.refers = if isAll then [] else (res.sort(); res)

    return # _processRefsArray

  _processFields = (doc, docOrField) ->

    field = undefined

    result.context ((path) -> (Result.item field.name, Result.prop 'fields') path), ->

      for field in docOrField.fields.$$list

        if field.type == 'refers'

          if Array.isArray field.refers

            _processRefsArray doc, field, field.refers

          else

            _processRefsArray doc, field, field.refers.split ','

        else if field.hasOwnProperty('fields')

          _processFields doc, field

    return

  doc = undefined

  result.context ((path) -> (Result.item doc.name, Result.prop 'docs') path), -> # processRefers =

    _processFields doc, doc for doc in docs.$$list

    return # result.context

  return

# ----------------------------

module.exports = processRefers
