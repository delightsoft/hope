var lightClone;

lightClone = function(obj) {
  var k, res, v;
  if (typeof obj === 'object' && obj !== null) {
    if (Array.isArray(obj)) {
      return obj.slice();
    } else {
      res = {};
      for (k in obj) {
        v = obj[k];
        if (!k.startsWith('$$')) {
          res[k] = v;
        }
      }
      return res;
    }
  } else {
    return obj;
  }
};

module.exports = lightClone;
