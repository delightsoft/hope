{lightClone} = require '../utils'

unlinkTags = (collection) ->

  res = {}

  res[k] = v._mask for k, v of collection.$$tags

  res # unlinkTags =

unlinkFields = (docOrField) ->

  for field in docOrField.fields.$$list # unlinkFields =

    res = lightClone field

    res.udType = field.udType[0] if field.hasOwnProperty('udType')

    res.refers = (ref.name for ref in field.refers) if field.hasOwnProperty('refers')

    res.fields = unlinkFields(field) if field.hasOwnProperty('fields')

    res.$$mask = field.$$mask._mask if field.hasOwnProperty('$$mask')

    res

unlink = (config) ->

    udtypes: config.udtypes.$$list

    docs:

      (for doc in config.docs.$$list

        name: doc.name

        fields:

          list: unlinkFields doc

          tags: unlinkTags doc.fields

        actions:

          list: (lightClone action for action in doc.actions.$$list)

          tags: unlinkTags doc.actions

        states: (

          for state in doc.states.$$list

            name: state.name

            view: state.view._mask

            update: state.update._mask

            transitions: (

              for transition in state.transitions.$$list

                res = lightClone transition

                res.next = res.next.name

                res)
        )

      )

# ----------------------------

module.exports = unlink