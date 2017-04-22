var MAX_LEVELS, MAX_LIST, prettyPrint, printList, printMap;

MAX_LIST = 10;

MAX_LEVELS = 2;

printList = function(list, level, maxLevel) {
  var i, res;
  res = ((function() {
    var j, ref, results;
    results = [];
    for (i = j = 0, ref = Math.min(list.length, MAX_LIST); 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
      results.push(prettyPrint(list[i], level, maxLevel));
    }
    return results;
  })()).join(', ');
  return "[" + res + (list.length > MAX_LIST ? ' ...]' : ']');
};

printMap = function(map, level, maxLevel) {
  var c, k, key, res, v, val;
  c = 0;
  res = ((function() {
    var results;
    results = [];
    for (k in map) {
      v = map[k];
      if (!(!k.startsWith('$'))) {
        continue;
      }
      if (!(c++ < MAX_LIST)) {
        break;
      }
      key = /^[\w_\$#\.]*$/g.test(k) ? "" + k : "'" + k + "'";
      val = prettyPrint(v, level, maxLevel);
      results.push(key + ": " + val);
    }
    return results;
  })()).join(', ');
  return "{" + res + (c > MAX_LIST ? ' ...}' : '}');
};

prettyPrint = function(arg, level, maxLevel) {
  if (typeof arg === 'object' && arg !== null) {
    level = level === void 0 ? 0 : level + 1;
    if (level === (maxLevel || MAX_LEVELS)) {
      if (Array.isArray(arg)) {
        return "[list]";
      } else {
        return "[object]";
      }
    } else if (Array.isArray(arg)) {
      return printList(arg, level, maxLevel);
    } else {
      return printMap(arg, level, maxLevel);
    }
  } else if (typeof arg === 'string') {
    return "'" + arg + "'";
  } else {
    return "" + arg;
  }
};

module.exports = prettyPrint;
