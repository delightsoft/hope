var Result, compileTags, processActions, sortedMap;

Result = require('../result');

sortedMap = require('../sortedMap');

compileTags = require('../tags').compile;

processActions = function(result, doc) {
  if (!doc.$$src.hasOwnProperty('actions')) {
    return {
      $$list: [],
      $$tags: {}
    };
  }
  return result.context(Result.prop('actions'), function() {
    var action, res;
    res = sortedMap(result, doc.$$src.actions, {
      index: true,
      getValue: function(result, value, res) {
        if (typeof value === 'function') {
          res.value = value;
          return true;
        }
        return false;
      }
    });
    if (!result.isError) {
      action = void 0;
      result.context((function(path) {
        return (Result.item(action.name))(path);
      }), function() {
        var i, len, ref;
        ref = res.$$list;
        for (i = 0, len = ref.length; i < len; i++) {
          action = ref[i];
          if (action.hasOwnProperty('$$src')) {
            if (!action.$$src.hasOwnProperty('value')) {
              result.error('dsc.missingProp', {
                value: 'value'
              });
            } else if (typeof action.$$src.value !== 'function') {
              result.error('dsc.invalidValue', {
                value: action.$$src.value
              });
            } else {
              action.value = action.$$src.value;
            }
          }
        }
      });
      compileTags(result, res);
      sortedMap.finish(result, res, {
        skipProps: ['tags']
      });
      if (!result.isError) {
        return res;
      }
    }
  });
};

module.exports = processActions;
