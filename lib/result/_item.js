var _add, invalidArg, item, notEnoughArgs, ref, tooManyArgs;

ref = require('../utils').err, invalidArg = ref.invalidArg, notEnoughArgs = ref.notEnoughArgs, tooManyArgs = ref.tooManyArgs;

_add = function(name, path) {
  if (!(arguments.length > 0)) {
    notEnoughArgs();
  }
  if (typeof path !== 'string') {
    invalidArg('path', name);
  }
  if (!(arguments.length <= 2)) {
    tooManyArgs();
  }
  path += "[" + name + "]";
  return path;
};

item = function(name, pathFunc) {
  if (!(arguments.length > 0)) {
    notEnoughArgs();
  }
  if (!(typeof name === 'string' && name.length > 0)) {
    invalidArg('name', name);
  }
  if (!(arguments.length <= 2)) {
    tooManyArgs();
  }
  if (arguments.length === 1) {
    return function(path) {
      return _add(name, path);
    };
  }
  if (typeof pathFunc === 'function') {
    return function(path) {
      return _add(name, pathFunc(path));
    };
  }
  invalidArg('pathFunc', pathFunc);
};

module.exports = item;
