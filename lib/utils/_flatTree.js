var flat, flatTree;

flat = function(dst, src, prefix) {
  var k, v;
  for (k in src) {
    v = src[k];
    if (typeof v === 'object' && v !== null) {
      flat(dst, v, "" + prefix + k + ".");
    } else {
      dst["" + prefix + k] = v;
    }
  }
};

flatTree = function(src) {
  var res;
  flat((res = {}), src, '');
  return res;
};

module.exports = flatTree;
