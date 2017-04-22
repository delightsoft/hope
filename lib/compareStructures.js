var Result, _compactValue, _compareList, _compareMap, _compareValue, compareStructures;

Result = require('./result');

_compactValue = function(v) {
  if (typeof v === 'object') {
    if (v === null) {
      return 'null';
    } else if (Array.isArray(v)) {
      return '[Array]';
    } else if (v.hasOwnProperty('name')) {
      return "[Item(" + v.name + ")]";
    } else {
      return '[Object]';
    }
  } else {
    return v;
  }
};

_compareMap = function(result, path, actual, expected) {
  var k;
  if (!(path.indexOf(actual) >= 0)) {
    path.push(actual);
    k = void 0;
    result.context((function(path) {
      return ((expected.hasOwnProperty('$$list') && !k.startsWith('$') ? Result.item : Result.prop)(k))(path);
    }), function() {
      var j, l, len, len1, ref, ref1, results, v;
      ref = Object.keys(expected);
      for (j = 0, len = ref.length; j < len; j++) {
        k = ref[j];
        v = expected[k];
        if (!actual.hasOwnProperty(k)) {
          result.info('missing', {
            value: _compactValue(v)
          });
        } else {
          _compareValue(result, path, actual[k], v);
        }
      }
      ref1 = Object.keys(actual);
      results = [];
      for (l = 0, len1 = ref1.length; l < len1; l++) {
        k = ref1[l];
        if (!expected.hasOwnProperty(k)) {
          results.push(result.info('extra', {
            value: _compactValue(actual[k])
          }));
        }
      }
      return results;
    });
    path.pop();
  }
};

_compareList = function(result, path, actual, expected) {
  var i;
  if (!(path.indexOf(actual) >= 0)) {
    path.push(actual);
    i = void 0;
    result.context((function(path) {
      return (Result.index(i))(path);
    }), function() {
      var j, l, len, len1, ref, results, v;
      for (i = j = 0, len = expected.length; j < len; i = ++j) {
        v = expected[i];
        if (i < actual.length) {
          _compareValue(result, path, actual[i], v);
        } else {
          result.info('missing', {
            value: _compactValue(v)
          });
        }
      }
      ref = actual.slice(expected.length, actual.length);
      results = [];
      for (i = l = 0, len1 = ref.length; l < len1; i = ++l) {
        v = ref[i];
        results.push(result.info('extra', {
          value: _compactValue(v)
        }));
      }
      return results;
    });
    path.pop();
  }
};

_compareValue = function(result, path, actual, expected) {
  var atype, etype;
  if ((atype = typeof actual) === 'object') {
    atype = actual === null ? 'null' : Array.isArray(actual) ? 'array' : 'object';
  }
  if ((etype = typeof expected) === 'object') {
    etype = expected === null ? 'null' : Array.isArray(expected) ? 'array' : 'object';
  }
  if (atype !== etype) {
    result.info('diffType', {
      actual: atype,
      expected: etype
    });
  } else {
    switch (atype) {
      case 'object':
        _compareMap(result, path, actual, expected);
        break;
      case 'array':
        _compareList(result, path, actual, expected);
        break;
      default:
        if (actual !== expected) {
          result.info('diffValue', {
            actual: _compactValue(actual),
            expected: _compactValue(expected)
          });
        }
    }
  }
};

compareStructures = function(result, actual, expected) {
  _compareValue(result, [], actual, expected);
};

module.exports = compareStructures;
