var Result, builtInTypes, compileType, processUdtypes, ref, ref1, reservedTypes, sortedMap, typeProps;

Result = require('../result');

sortedMap = require('../sortedMap');

ref = require('../types'), compileType = ref.compile, (ref1 = ref.compile, builtInTypes = ref1._builtInTypes, reservedTypes = ref1._reservedTypes, typeProps = ref1._typeProps);

processUdtypes = function(result, config) {
  if (!config.$$src.hasOwnProperty('udtypes')) {
    return {};
  }
  return result.context(Result.prop('udtypes'), function() {
    var cycledTypes, i, len, processUdtype, ref2, res, udType, udt;
    res = sortedMap(result, config.$$src.udtypes);
    if (result.isError) {
      return;
    }
    udType = void 0;
    result.context((function(path) {
      return (Result.item(udType.name))(path);
    }), function() {
      var i, j, k, len, len1, len2, ref2, results, t;
      for (i = 0, len = builtInTypes.length; i < len; i++) {
        t = builtInTypes[i];
        if (!(res.hasOwnProperty(t))) {
          continue;
        }
        udType = res[t];
        result.error('dsc.builtInTypeName');
      }
      for (j = 0, len1 = reservedTypes.length; j < len1; j++) {
        t = reservedTypes[j];
        if (!(res.hasOwnProperty(t))) {
          continue;
        }
        udType = res[t];
        result.error('dsc.reservedTypeName');
      }
      if (!result.isError) {
        ref2 = res.$$list;
        results = [];
        for (k = 0, len2 = ref2.length; k < len2; k++) {
          udType = ref2[k];
          results.push(compileType(result, udType.$$src, udType, {
            context: 'udtype'
          }));
        }
        return results;
      }
    });
    if (result.isError) {
      return;
    }
    cycledTypes = [];
    processUdtype = function(udt, stack) {
      var i, j, len, len1, parent, prop, results, t;
      if (stack && stack.indexOf(udt.name) >= 0) {
        if (!cycledTypes.hasOwnProperty(udt.name)) {
          result.error('dsc.cycledUdtypes', {
            value: stack
          });
          for (i = 0, len = stack.length; i < len; i++) {
            t = stack[i];
            cycledTypes[t] = true;
          }
        }
        return;
      }
      if (!udt.hasOwnProperty('type')) {
        if (!res.hasOwnProperty(udt.udType)) {
          result.error({
            code: 'dsc.unknownType',
            value: udt.udType
          });
        }
        parent = res[udt.udType];
        if (!parent.hasOwnProperty('type')) {
          processUdtype(parent, (stack ? (stack.push(udt.name), stack) : [udt.name]));
        }
        if (parent.hasOwnProperty('type')) {
          udt.type = parent.type;
          udt.udType = parent.name;
          results = [];
          for (j = 0, len1 = typeProps.length; j < len1; j++) {
            prop = typeProps[j];
            if (parent.hasOwnProperty(prop)) {
              results.push(udt[prop] = parent[prop]);
            }
          }
          return results;
        }
      }
    };
    ref2 = res.$$list;
    for (i = 0, len = ref2.length; i < len; i++) {
      udt = ref2[i];
      processUdtype(udt);
    }
    if (!result.isError) {
      sortedMap.finish(result, res);
      if (!result.isError) {
        config.udtypes = res;
      }
    }
  });
};

module.exports = processUdtypes;
