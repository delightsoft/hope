var BitArray, Result, deepClone, finish, flatMap, invalidArg, invalidArgValue, isResult, ref, ref1, sortedMap;

Result = require('./result');

sortedMap = require('./sortedMap');

BitArray = require('./bitArray');

ref = require('./utils'), deepClone = ref.deepClone, (ref1 = ref.err, invalidArg = ref1.invalidArg, invalidArgValue = ref1.invalidArgValue, isResult = ref1.isResult);

finish = function(result, resValue, subitemsField, opts) {
  var _processSublevel;
  if (!isResult(result)) {
    invalidArg('result', result);
  }
  if (!(typeof resValue === 'object' && resValue !== null && resValue.hasOwnProperty('$$flat'))) {
    invalidArg('resValue', resValue);
  }
  if (!(typeof subitemsField === 'string' && subitemsField.length > 0)) {
    invalidArg('subitemsField', subitemsField);
  }
  if (!(opts === void 0 || (typeof opts === 'object' && opts !== null && !Array.isArray(opts)))) {
    invalidArg('opts', opts);
  }
  _processSublevel = function(level) {
    var item;
    item = void 0;
    result.context((function(path) {
      return (Result.item(item.name))(path);
    }), function() {
      var i, len, ref2;
      ref2 = level.$$list;
      for (i = 0, len = ref2.length; i < len; i++) {
        item = ref2[i];
        if (item.hasOwnProperty(subitemsField)) {
          result.context(Result.prop(subitemsField), function() {
            _processSublevel(item[subitemsField]);
            sortedMap.finish(result, item[subitemsField], opts);
          });
        }
      }
    });
  };
  _processSublevel(resValue);
  sortedMap.finish(result, resValue, opts);
};

flatMap = function(result, value, subitemsField, opts) {
  var _processLevel, name, optsIndex, optsMask, resList, resMap;
  if (!isResult(result)) {
    invalidArg('result', result);
  }
  if (!(typeof subitemsField === 'string' && subitemsField.length > 0)) {
    invalidArg('subitemsField', subitemsField);
  }
  if (!(opts === void 0 || (typeof opts === 'object' && opts !== null && !Array.isArray(opts)))) {
    invalidArg('opts', opts);
  }
  if (!(opts != null ? opts.hasOwnProperty('index') : void 0)) {
    optsIndex = false;
  } else {
    if (typeof (optsIndex = opts.index) !== 'boolean') {
      invalidArgValue('opts.index', opts.index);
    }
    if (optsIndex) {
      opts = deepClone(opts);
      opts.index = false;
    }
  }
  if (!(opts != null ? opts.hasOwnProperty('mask') : void 0)) {
    optsMask = false;
  } else {
    if (typeof (optsMask = opts.mask) !== 'boolean') {
      invalidArgValue('opts.mask', opts.mask);
    }
    if (!optsIndex) {
      throw new Error('opts.mask requires opts.index to be true');
    }
  }
  name = [];
  resList = [];
  resMap = {};
  _processLevel = function(parentItem) {
    var i, item, len, ref2, ref3;
    ref2 = parentItem.$$list;
    for (i = 0, len = ref2.length; i < len; i++) {
      item = ref2[i];
      if (optsIndex) {
        item.$$index = resList.length;
      }
      resList.push(item);
      name.push(item.name);
      resMap[name.join('.')] = item;
      if ((ref3 = item.$$src) != null ? ref3.hasOwnProperty(subitemsField) : void 0) {
        result.context(Result.item(item.name, Result.prop(subitemsField)), function() {
          var resLevel;
          item[subitemsField] = resLevel = sortedMap(result, item.$$src[subitemsField], opts);
          if (!result.isError) {
            _processLevel(resLevel);
          }
        });
      }
      name.pop();
    }
  };
  return result.context(function() {
    var buildMask, masks, res;
    res = sortedMap(result, value, opts);
    if (!result.isError) {
      _processLevel(res);
      if (!result.isError) {
        (res.$$flat = resMap).$$list = resList;
        if (optsMask) {
          masks = [];
          buildMask = function(list) {
            var i, item, j, len, len1, mask, v;
            for (i = 0, len = list.length; i < len; i++) {
              item = list[i];
              for (j = 0, len1 = masks.length; j < len1; j++) {
                v = masks[j];
                v.set(item.$$index);
              }
              if (item.hasOwnProperty(subitemsField)) {
                masks.push(item.$$mask = mask = new BitArray(res));
                buildMask(item[subitemsField].$$list);
                masks.pop();
              }
            }
          };
          buildMask(res.$$list);
        }
        return res;
      }
    }
  });
};

module.exports = flatMap;

flatMap.finish = finish;

flatMap.empty = {
  $$list: [],
  $$flat: {
    $$list: []
  }
};
