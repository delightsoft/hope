var Result, checkItemName, finish, invalidArg, invalidArgValue, isResult, ref, ref1, sortedMap;

Result = require('./result');

ref = require('./utils'), checkItemName = ref.checkItemName, (ref1 = ref.err, invalidArg = ref1.invalidArg, invalidArgValue = ref1.invalidArgValue, isResult = ref1.isResult);

finish = function(result, resValue, opts) {
  var item, j, len, optsSkipProps, optsValidate, ref2;
  if (!isResult(result)) {
    invalidArg('result', result);
  }
  if (!(typeof resValue === 'object' && resValue !== null && resValue.hasOwnProperty('$$list'))) {
    invalidArg('resValue', resValue);
  }
  if (!(opts === void 0 || (typeof opts === 'object' && opts !== null && !Array.isArray(opts)))) {
    invalidArg('opts', opts);
  }
  if (!(opts != null ? opts.hasOwnProperty('skipProps') : void 0)) {
    optsSkipProps = void 0;
  } else {
    if (!((optsSkipProps = opts.skipProps) === void 0 || optsSkipProps === null || Array.isArray(optsSkipProps))) {
      invalidArgValue('opts.skipProps', opts.skipProps);
    }
  }
  if (!(opts != null ? opts.hasOwnProperty('validate') : void 0)) {
    optsValidate = true;
  } else {
    if (typeof (optsValidate = opts.validate) !== 'boolean') {
      invalidArgValue('opts.validate', opts.validate);
    }
  }
  if (result.isError) {
    optsValidate = false;
  }
  if (optsValidate) {
    item = void 0;
    result.context((function(path) {
      return (Result.item(item.name))(path);
    }), function() {
      var j, k, len, ref2;
      ref2 = resValue.$$list;
      for (j = 0, len = ref2.length; j < len; j++) {
        item = ref2[j];
        if (optsValidate && item.hasOwnProperty('$$src')) {
          for (k in item.$$src) {
            if (!(item.hasOwnProperty(k) || k.startsWith('$') || (optsSkipProps != null ? optsSkipProps.indexOf(k) : void 0) >= 0)) {
              result.error('dsc.unexpectedProp', {
                value: k
              });
            }
          }
        }
        delete item.$$src;
      }
    });
  } else {
    ref2 = resValue.$$list;
    for (j = 0, len = ref2.length; j < len; j++) {
      item = ref2[j];
      delete item.$$src;
    }
  }
};

sortedMap = function(result, value, opts) {
  var i, items, j, k, len, list, optsBoolean, optsCheckName, optsGetValue, optsIndex, optsString, res, v;
  if (!isResult(result)) {
    invalidArg('result', result);
  }
  if (!(opts === void 0 || (typeof opts === 'object' && opts !== null && !Array.isArray(opts)))) {
    invalidArg('opts', opts);
  }
  if (!(opts != null ? opts.hasOwnProperty('checkName') : void 0)) {
    optsCheckName = null;
  } else {
    if (typeof (optsCheckName = opts.checkName) !== 'function') {
      invalidArgValue('opts.checkName', opts.checkName);
    }
  }
  if (!(opts != null ? opts.hasOwnProperty('getValue') : void 0)) {
    optsGetValue = null;
  } else {
    if (typeof (optsGetValue = opts.getValue) !== 'function') {
      invalidArgValue('opts.getValue', opts.getValue);
    }
  }
  if (!(opts != null ? opts.hasOwnProperty('string') : void 0)) {
    optsString = false;
  } else {
    if (typeof (optsString = opts.string) !== 'boolean') {
      invalidArgValue('opts.string', opts.string);
    }
  }
  if (!(opts != null ? opts.hasOwnProperty('boolean') : void 0)) {
    optsBoolean = false;
  } else {
    if (typeof (optsBoolean = opts.boolean) !== 'boolean') {
      invalidArgValue('opts.boolean', opts.boolean);
    }
  }
  if (!(opts != null ? opts.hasOwnProperty('index') : void 0)) {
    optsIndex = false;
  } else {
    if (typeof (optsIndex = opts.index) !== 'boolean') {
      invalidArgValue('opts.index', opts.index);
    }
  }
  res = {};
  list = [];
  if (optsString && typeof value === 'string' && value.length > 0 && optsString) {
    items = (function() {
      var j, len, ref2, results;
      ref2 = value.split(',');
      results = [];
      for (j = 0, len = ref2.length; j < len; j++) {
        v = ref2[j];
        if (v.trim()) {
          results.push(v.trim());
        }
      }
      return results;
    })();
    if (items.length === 0) {
      result.error('dsc.invalidValue', {
        value: value
      });
    } else {
      for (i = j = 0, len = items.length; j < len; i = ++j) {
        v = items[i];
        if (!!res.hasOwnProperty(v)) {
          result.error(Result.index(i), 'dsc.duplicatedName', {
            value: v
          });
          continue;
        }
        if (optsIndex) {
          clone.$$index = list.length;
        }
        list.push((res[v] = {
          name: v
        }));
      }
    }
  } else if (typeof value === 'object' && value !== null) {
    if (Array.isArray(value)) {
      i = void 0;
      result.context((function(path) {
        return (Result.index(i))(path);
      }), function() {
        var clone, l, len1;
        for (i = l = 0, len1 = value.length; l < len1; i = ++l) {
          v = value[i];
          if (optsString && typeof v === 'string' && v.length > 0) {
            res[v] = clone = {
              name: v
            };
          } else if (!(typeof v === 'object' && v !== null && !Array.isArray(v))) {
            result.error('dsc.invalidValue', {
              value: v
            });
            continue;
          } else if (!v.hasOwnProperty('name')) {
            result.error('dsc.missingProp', {
              value: 'name'
            });
            continue;
          } else if (!(optsCheckName ? optsCheckName(v.name) : checkItemName(v.name))) {
            result.error('dsc.invalidName', {
              value: v.name
            });
            continue;
          } else if (!!res.hasOwnProperty(v.name)) {
            result.error('dsc.duplicatedName', {
              value: v.name
            });
            continue;
          } else {
            res[v.name] = clone = {
              name: v.name,
              $$src: v
            };
          }
          if (optsIndex) {
            clone.$$index = list.length;
          }
          list.push(clone);
        }
      });
    } else {
      if (value.hasOwnProperty('$$list')) {
        throw new Error('Value was already processed by sortedMap()');
      }
      k = void 0;
      result.context((function(path) {
        return (Result.prop(k))(path);
      }), function() {
        var clone;
        for (k in value) {
          v = value[k];
          if (!(optsCheckName ? optsCheckName(k) : checkItemName(k))) {
            result.error('dsc.invalidName', {
              value: k
            });
          }
          res[k] = clone = {
            name: k
          };
          if (typeof v === 'object' && v !== null && !Array.isArray(v)) {
            if (!(!v.hasOwnProperty('name') || k === v.name)) {
              result.error('dsc.keyAndNameHasDifferenValues', {
                value1: k,
                value2: v.name
              });
              continue;
            } else {
              clone.$$src = v;
            }
          } else if (optsGetValue && optsGetValue(result, v, clone)) {
            void 0;
          } else if (optsBoolean && typeof v === 'boolean' && v === true) {
            res[k] = clone = {
              name: k
            };
          } else {
            result.error('dsc.invalidValue', {
              value: v
            });
            continue;
          }
          if (optsIndex) {
            clone.$$index = list.length;
          }
          list.push(clone);
        }
      });
    }
  } else {
    result.error('dsc.invalidValue', {
      value: value
    });
  }
  if (!result.isError) {
    if (list.length > 0) {
      res.$$list = list;
      return res;
    } else {
      result.error('dsc.invalidValue', {
        value: value
      });
    }
  }
};

module.exports = sortedMap;

sortedMap.finish = finish;

sortedMap.empty = {
  $$list: []
};
