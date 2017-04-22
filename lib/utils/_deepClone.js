var _clone, deepClone;

_clone = function(obj, customClone, path) {
  var cc, clone, i, j, k, l, len, len1, v;
  for (i = j = 0, len = path.length; j < len; i = j += 2) {
    v = path[i];
    if (v === obj) {
      return path[i + 1];
    }
  }
  path.push(obj);
  if (Array.isArray(obj)) {
    path.push(clone = []);
    for (i = l = 0, len1 = obj.length; l < len1; i = ++l) {
      v = obj[i];
      clone[i] = typeof v === 'object' && v !== null ? _clone(v, customClone, path) : v;
    }
  } else {
    path.push(clone = {});
    for (k in obj) {
      v = obj[k];
      if (!k.startsWith('$$')) {
        if (cc = typeof customClone === "function" ? customClone(k, v, path) : void 0) {
          if (!(!cc || cc[0] === void 0)) {
            clone[k] = cc[0];
          }
        } else {
          clone[k] = typeof v === 'object' && v !== null ? _clone(v, customClone, path) : v;
        }
      }
    }
  }
  path.length = path.length - 2;
  return clone;
};

deepClone = function(obj, customClone, path) {
  if (typeof obj === 'object' && obj !== null) {
    return _clone(obj, customClone, path || []);
  } else {
    return obj;
  }
};

module.exports = deepClone;
