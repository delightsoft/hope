"use strict";

// Generated by CoffeeScript 2.5.1
(function () {
  // имя API:
  // - начинаются с маленьких букв и содержит буквы и цифры
  var _checkAPIName;

  _checkAPIName = function _checkAPIName(value) {
    return typeof value === 'string' && /^[a-z][a-zA-Z0-9_]*$/.test(value);
  }; // ----------------------------


  module.exports = _checkAPIName;
}).call(void 0);