Result = require '../result'

sortedMap = require '../sortedMap'

{calc: calcTags} = require '../tags'

processStates = (result, doc, fields, actions) ->

  unless doc.$$src.hasOwnProperty('states')

    return sortedMap.empty # processStates =

  res = undefined

  result.context (Result.prop 'states'), ->

    res = sortedMap result, doc.$$src.states

    unless result.isError

      state = undefined

      result.context ((path) -> (Result.prop state.name) path), ->

        for state in res.$$list

          result.context (Result.prop 'view'), ->

            unless state.$$src.hasOwnProperty('view')

              # TODO: Make all tag

              state.view = fields.$$tags.all

            else unless typeof state.$$src.view == 'string'

              result.error 'dsc.invalidValue', value: state.$$src.view

            else

              state.view = calcTags result, fields, state.$$src.view

            return # result.context

          result.context (Result.prop 'update'), ->

            unless state.$$src.hasOwnProperty('update')

              state.update = fields.$$tags.all

            else unless typeof state.$$src.update == 'string'

              result.error 'dsc.invalidValue', value: state.$$src.update

            else

              state.update = calcTags result, fields, state.$$src.update

            return # result.context

          result.context (Result.prop 'transitions'), ->

            unless state.$$src.hasOwnProperty('transitions')

              state.transitions = sortedMap.empty

            else

              state.transitions = sortedMap result, state.$$src.transitions

              , getValue: (result, value, res) ->

                if typeof value == 'string'

                  res.next = value

                  return true

              unless result.isError

                transition = undefined

                result.context ((path) -> (Result.prop transition.name) path), ->

                  for transition in state.transitions.$$list

                    result.isError = false

                    unless actions.hasOwnProperty(transition.name)

                      result.error 'dsc.unknownAction', value: transition.name

                    if transition.hasOwnProperty('$$src')

                      unless transition.$$src.hasOwnProperty('next')

                        result.error 'dsc.missingProp', value: 'next'

                      else unless typeof transition.$$src.next == 'string' && transition.$$src.next.length > 0

                        result.error (Result.prop 'next'), 'dsc.invalidValue', value: transition.$$src.next

                      else

                        transition.next = transition.$$src.next

                    if transition.hasOwnProperty('next')

                      unless res.hasOwnProperty(transition.next)

                        result.error (Result.prop 'next'), 'dsc.unknownState', value: transition.next

                      else

                        transition.next = res[transition.next]

                  return # result.context

                sortedMap.finish result, state.transitions unless result.isError

            return # result.context

        return # result.context

    sortedMap.finish result, res unless result.isError

    return # result.context

  res unless result.isError # processStates =

# ----------------------------

module.exports = processStates

