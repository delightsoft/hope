var extend;

extend = function(dest) {
  var i, j, k, l, len, ref, ref1, s;
  for (i = j = 1, ref = arguments.length; j < ref; i = j += 1) {
    if (s = arguments[i]) {
      ref1 = Object.keys(s);
      for (l = 0, len = ref1.length; l < len; l++) {
        k = ref1[l];
        dest[k] = s[k];
      }
    }
  }
  return dest;
};

module.exports = extend;
