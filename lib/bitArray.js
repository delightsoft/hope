var BitArray, invalidArg, ref, tooManyArgs;

ref = require('./utils').err, invalidArg = ref.invalidArg, tooManyArgs = ref.tooManyArgs;

BitArray = (function() {
  function BitArray(arg1, arg2) {
    var collection, i, j, len, mask, ref1;
    if (Array.isArray(arg1)) {
      this._collection = arg1;
      this._mask = arg2;
    } else {
      if (!(typeof arg1 === 'object' && arg1 !== null && arg1.hasOwnProperty('$$list'))) {
        invalidArg('arg1', arg1);
      }
      if (!(arguments.length <= 1)) {
        tooManyArgs();
      }
      this._collection = collection = arg1.hasOwnProperty('$$flat') ? arg1.$$flat.$$list : arg1.$$list;
      this._mask = mask = new Array(len = Math.trunc((collection.length + 31) / 32));
      for (i = j = 0, ref1 = len; 0 <= ref1 ? j < ref1 : j > ref1; i = 0 <= ref1 ? ++j : --j) {
        mask[i] = 0;
      }
    }
    return;
  }

  BitArray.prototype.set = function(index, value) {
    var m;
    if (!(typeof index === 'number' && index % 1 === 0)) {
      invalidArg('index');
    }
    if (value === void 0) {
      value = true;
    } else {
      if (typeof value !== 'boolean') {
        invalidArg('value', value);
      }
    }
    if (!(arguments.length <= 2)) {
      tooManyArgs();
    }
    if (this.hasOwnProperty('_list')) {
      throw new Error("set() is not allowed in this state");
    }
    if (!((0 <= index && index < this._collection.length))) {
      throw new Error("index out of range: " + index);
    }
    m = 1 << index % 32;
    if (value) {
      this._mask[Math.trunc(index / 32)] |= m;
    } else {
      this._mask[Math.trunc(index / 32)] &= ~m;
    }
    return this;
  };

  BitArray.prototype.get = function(index) {
    var value;
    if (!(typeof index === 'number' && index % 1 === 0)) {
      invalidArg('index');
    }
    if (value === void 0) {
      value = true;
    }
    if (!(arguments.length <= 1)) {
      tooManyArgs();
    }
    if (!((0 <= index && index < this._collection.length))) {
      throw new Error("index out of range: " + index);
    }
    return (this._mask[Math.trunc(index / 32)] & (1 << index % 32)) !== 0;
  };

  BitArray.prototype.and = function(bitArray) {
    var collection, i, j, leftMask, len, ref1, resMask, rightMask;
    if (!(typeof bitArray === 'object' && bitArray !== null && bitArray.hasOwnProperty('_mask'))) {
      invalidArg('bitArray', bitArray);
    }
    if (!(arguments.length <= 1)) {
      tooManyArgs();
    }
    if (this._collection !== (collection = bitArray._collection)) {
      throw new Error('given bitArray is different collection');
    }
    resMask = new Array((len = (leftMask = this._mask).length));
    rightMask = bitArray._mask;
    for (i = j = 0, ref1 = len; j < ref1; i = j += 1) {
      resMask[i] = leftMask[i] & rightMask[i];
    }
    return new BitArray(collection, resMask);
  };

  BitArray.prototype.or = function(bitArray) {
    var collection, i, j, leftMask, len, ref1, resMask, rightMask;
    if (!(typeof bitArray === 'object' && bitArray !== null && bitArray.hasOwnProperty('_mask'))) {
      invalidArg('bitArray', bitArray);
    }
    if (!(arguments.length <= 1)) {
      tooManyArgs();
    }
    if (this._collection !== (collection = bitArray._collection)) {
      throw new Error('given bitArray is different collection');
    }
    resMask = new Array((len = (leftMask = this._mask).length));
    rightMask = bitArray._mask;
    for (i = j = 0, ref1 = len; j < ref1; i = j += 1) {
      resMask[i] = leftMask[i] | rightMask[i];
    }
    return new BitArray(collection, resMask);
  };

  BitArray.prototype.subtract = function(bitArray) {
    var collection, i, j, leftMask, len, ref1, resMask, rightMask;
    if (!(typeof bitArray === 'object' && bitArray !== null && bitArray.hasOwnProperty('_mask'))) {
      invalidArg('bitArray', bitArray);
    }
    if (!(arguments.length <= 1)) {
      tooManyArgs();
    }
    if (this._collection !== (collection = bitArray._collection)) {
      throw new Error('given bitArray is different collection');
    }
    resMask = new Array((len = (leftMask = this._mask).length));
    rightMask = bitArray._mask;
    for (i = j = 0, ref1 = len; j < ref1; i = j += 1) {
      resMask[i] = leftMask[i] & ~rightMask[i];
    }
    return new BitArray(collection, resMask);
  };

  BitArray.prototype.invert = function() {
    var i, j, leftMask, len, r, ref1, resMask;
    if (arguments.length !== 0) {
      tooManyArgs();
    }
    resMask = new Array((len = (leftMask = this._mask).length));
    for (i = j = 0, ref1 = len; j < ref1; i = j += 1) {
      resMask[i] = ~leftMask[i];
    }
    if ((r = this._collection.length % 32) > 0) {
      resMask[len - 1] &= (1 << r) - 1;
    }
    return new BitArray(this._collection, resMask);
  };

  BitArray.prototype.isEmpty = function() {
    var j, len1, ref1, v;
    ref1 = this._mask;
    for (j = 0, len1 = ref1.length; j < len1; j++) {
      v = ref1[j];
      if (v !== 0) {
        return false;
      }
    }
    return true;
  };

  BitArray.prototype.fixVertical = function() {
    var i, item, itemMask, j, k, l, len1, mask, noSubfields, ref1, ref2, ref3;
    ref1 = this._collection;
    for (j = 0, len1 = ref1.length; j < len1; j++) {
      item = ref1[j];
      if (!(item.hasOwnProperty('$$mask'))) {
        continue;
      }
      itemMask = item.$$mask._mask;
      mask = this._mask;
      noSubfields = true;
      for (i = k = 0, ref2 = mask.length; k < ref2; i = k += 1) {
        if (!((mask[i] & itemMask[i]) !== 0)) {
          continue;
        }
        noSubfields = false;
        break;
      }
      if (this.get(item.$$index)) {
        if (noSubfields) {
          for (i = l = 0, ref3 = mask.length; l < ref3; i = l += 1) {
            mask[i] |= itemMask[i];
          }
        }
      } else if (!noSubfields) {
        this.set(item.$$index);
      }
    }
  };

  BitArray.prototype.clearVertical = function() {
    var i, item, itemMask, j, k, mask, noSubfields, ref1, ref2;
    ref1 = this._collection;
    for (j = ref1.length - 1; j >= 0; j += -1) {
      item = ref1[j];
      if (!(item.hasOwnProperty('$$mask'))) {
        continue;
      }
      itemMask = item.$$mask._mask;
      mask = this._mask;
      noSubfields = true;
      for (i = k = 0, ref2 = mask.length; k < ref2; i = k += 1) {
        if (!((mask[i] & itemMask[i]) !== 0)) {
          continue;
        }
        noSubfields = false;
        break;
      }
      this.set(item.$$index, !noSubfields);
    }
  };

  BitArray.prototype.valueOf = function() {
    var collection, i, j, len, m, mask, p, ref1, res, v;
    res = [];
    len = (collection = this._collection).length;
    m = 1;
    v = (mask = this._mask)[p = 0];
    for (i = j = 0, ref1 = len; j < ref1; i = j += 1) {
      if ((v & m) !== 0) {
        res.push(i);
      }
      if ((m <<= 1) === 0) {
        m = 1;
        v = mask[++p];
      }
    }
    return res;
  };

  return BitArray;

})();

Object.defineProperty(BitArray.prototype, 'list', {
  configurable: true,
  enumerable: true,
  get: function() {
    var collection, i, j, len, list, m, mask, p, ref1, v;
    if (!this.hasOwnProperty('_list')) {
      this._list = list = [];
      len = (collection = this._collection).length;
      m = 1;
      v = (mask = this._mask)[p = 0];
      for (i = j = 0, ref1 = len; j < ref1; i = j += 1) {
        if ((v & m) !== 0) {
          list.push(collection[i]);
        }
        if ((m <<= 1) === 0) {
          m = 1;
          v = mask[++p];
        }
      }
    }
    return this._list;
  }
});

module.exports = BitArray;
