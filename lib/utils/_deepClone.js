"use strict";

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { if (typeof Symbol === "undefined" || !(Symbol.iterator in Object(arr))) return; var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

function _typeof(obj) { "@babel/helpers - typeof"; if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof = function _typeof(obj) { return typeof obj; }; } else { _typeof = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof(obj); }

// Generated by CoffeeScript 2.5.1
(function () {
  var _clone2, deepClone, nindex;

  nindex = 0;

  _clone2 = function _clone(obj, map, opts) {
    var all, cc, clone, customClone, i, j, k, len, v;
    all = opts != null ? opts.all : void 0;
    customClone = opts != null ? opts.customClone : void 0;

    if (v = map.get(obj)) {
      return v;
    }

    if (Array.isArray(obj)) {
      map.set(obj, clone = []);

      for (i = j = 0, len = obj.length; j < len; i = ++j) {
        v = obj[i];
        clone[i] = _typeof(v) === 'object' && v !== null ? _clone2(v, map, opts) : v;
      }
    } else {
      map.set(obj, clone = Object.create(obj.__proto__ || null));

      for (k in obj) {
        v = obj[k];

        if (all || !k.startsWith('$$')) {
          if (cc = typeof customClone === "function" ? customClone(k, v, map) : void 0) {
            if (!(!cc || cc[0] === void 0)) {
              var _cc = cc;

              var _cc2 = _slicedToArray(_cc, 1);

              clone[k] = _cc2[0];
            }
          } else {
            clone[k] = _typeof(v) === 'object' && v !== null ? _clone2(v, map, opts) : v;
          }
        }
      }
    }

    return clone; // _clone =
  };

  deepClone = function deepClone(value, opts) {
    if (_typeof(value) === 'object' && value !== null) {
      return _clone2(value, new WeakMap(), opts);
    } else {
      return value; // deepClone =
    }
  }; // ----------------------------


  module.exports = deepClone;
}).call(void 0);