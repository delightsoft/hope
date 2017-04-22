var Result, calcTags, processStates, sortedMap;

Result = require('../result');

sortedMap = require('../sortedMap');

calcTags = require('../tags').calc;

processStates = function(result, doc, fields, actions) {
  var res;
  if (!doc.$$src.hasOwnProperty('states')) {
    return sortedMap.empty;
  }
  res = void 0;
  result.context(Result.prop('states'), function() {
    var state;
    res = sortedMap(result, doc.$$src.states);
    if (!result.isError) {
      state = void 0;
      result.context((function(path) {
        return (Result.item(state.name))(path);
      }), function() {
        var i, len, ref;
        ref = res.$$list;
        for (i = 0, len = ref.length; i < len; i++) {
          state = ref[i];
          result.context(Result.prop('view'), function() {
            if (!state.$$src.hasOwnProperty('view')) {
              state.view = fields.$$tags.all;
            } else if (typeof state.$$src.view !== 'string') {
              result.error('dsc.invalidValue', {
                value: state.$$src.view
              });
            } else {
              state.view = calcTags(result, fields, state.$$src.view);
            }
          });
          result.context(Result.prop('update'), function() {
            if (!state.$$src.hasOwnProperty('update')) {
              state.update = fields.$$tags.all;
            } else if (typeof state.$$src.update !== 'string') {
              result.error('dsc.invalidValue', {
                value: state.$$src.update
              });
            } else {
              state.update = calcTags(result, fields, state.$$src.update);
            }
          });
          result.context(Result.prop('transitions'), function() {
            var transition;
            if (!state.$$src.hasOwnProperty('transitions')) {
              state.transitions = sortedMap.empty;
            } else {
              state.transitions = sortedMap(result, state.$$src.transitions, {
                getValue: function(result, value, res) {
                  if (typeof value === 'string') {
                    res.next = value;
                    return true;
                  }
                }
              });
              if (!result.isError) {
                transition = void 0;
                result.context((function(path) {
                  return (Result.item(transition.name))(path);
                }), function() {
                  var j, len1, ref1;
                  ref1 = state.transitions.$$list;
                  for (j = 0, len1 = ref1.length; j < len1; j++) {
                    transition = ref1[j];
                    result.isError = false;
                    if (!actions.hasOwnProperty(transition.name)) {
                      result.error('dsc.unknownAction', {
                        value: transition.name
                      });
                    }
                    if (transition.hasOwnProperty('$$src')) {
                      if (!transition.$$src.hasOwnProperty('next')) {
                        result.error('dsc.missingProp', {
                          value: 'next'
                        });
                      } else if (!(typeof transition.$$src.next === 'string' && transition.$$src.next.length > 0)) {
                        result.error(Result.prop('next'), 'dsc.invalidValue', {
                          value: transition.$$src.next
                        });
                      } else {
                        transition.next = transition.$$src.next;
                      }
                    }
                    if (transition.hasOwnProperty('next')) {
                      if (!res.hasOwnProperty(transition.next)) {
                        result.error(Result.prop('next'), 'dsc.unknownState', {
                          value: transition.next
                        });
                      } else {
                        transition.next = res[transition.next];
                      }
                    }
                  }
                });
                if (!result.isError) {
                  sortedMap.finish(result, state.transitions, res);
                }
              }
            }
          });
        }
      });
    }
    if (!result.isError) {
      sortedMap.finish(result, res);
    }
  });
  if (!result.isError) {
    return res;
  }
};

module.exports = processStates;
