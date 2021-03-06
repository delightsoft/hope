"use strict";

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); return Constructor; }

function _typeof(obj) { "@babel/helpers - typeof"; if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof = function _typeof(obj) { return typeof obj; }; } else { _typeof = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof(obj); }

// Generated by CoffeeScript 2.5.1
(function () {
  var Result, _combineMsg, invalidArg, isResult, reservedAttrs, reservedPropName, tooManyArgs;

  var _require = require('../utils');

  var _require$err = _require.err;
  invalidArg = _require$err.invalidArg;
  tooManyArgs = _require$err.tooManyArgs;
  reservedPropName = _require$err.reservedPropName;
  isResult = _require$err.isResult;
  // ----------------------------
  reservedAttrs = ['type', 'path', 'code', 'text'];

  _combineMsg = function _combineMsg(type, path, code, args) {
    var arg, i, k, len, msg, v;

    if (!(typeof type === 'undefined' || typeof type === 'string' && type.length > 0)) {
      invalidArg('type', type);
    }

    if (type) {
      if (!(type === 'error' || type === 'warn' || type === 'info')) {
        invalidArg('type', type);
      }
    }

    if (!(!path || typeof path === 'string')) {
      invalidArg('path', path);
    }

    if (!(typeof code === 'string' && code.length > 0)) {
      invalidArg('code', code);
    }

    if (!(typeof args === 'undefined' || _typeof(args) === 'object' && args !== null)) {
      invalidArg('args', args);
    }

    if (args) {
      for (i = 0, len = reservedAttrs.length; i < len; i++) {
        arg = reservedAttrs[i];

        if (args.hasOwnProperty(arg)) {
          reservedPropName("args.".concat(arg), args);
        }
      }
    }

    msg = {};

    if (type && type !== 'info') {
      msg.type = type;
    }

    if (path) {
      msg.path = path;
    }

    msg.code = code;

    if (args) {
      for (k in args) {
        v = args[k];
        msg[k] = v;
      }
    }

    return msg; // _combineMsg =
  };

  Result = /*#__PURE__*/function () {
    function Result(pathFuncOrResult) {
      _classCallCheck(this, Result);

      if (!(arguments.length <= 1)) {
        tooManyArgs();
      }

      if (arguments.length === 0 || pathFuncOrResult === null) {
        this.pathFunc = function () {
          return '';
        };
      } else {
        if (isResult(pathFuncOrResult)) {
          this.parent = pathFuncOrResult;

          this.pathFunc = pathFuncOrResult.pathFunc || function () {
            return '';
          };
        } else if (typeof pathFuncOrResult === 'function' && pathFuncOrResult !== Result) {
          // with special protection from the case when instead of 'new Result', is written just 'Result'
          this.pathFunc = pathFuncOrResult;
        } else {
          invalidArg('pathFuncOrResult', pathFuncOrResult);
        }
      }

      this.messages = [];
      this.isError = this._err = false; // constructor:

      return;
    }

    _createClass(Result, [{
      key: "log",
      value: function log(typeOrMsg, pathFunc, code, args) {
        var msg, path;

        if (_typeof(typeOrMsg) === 'object' && typeOrMsg !== null) {
          if (!typeOrMsg.hasOwnProperty('code')) {
            invalidArg('typeOrMsg', typeOrMsg);
          }

          msg = typeOrMsg;
        } else {
          if (typeof pathFunc !== 'function') {
            var _ref = [code, pathFunc, null];
            args = _ref[0];
            code = _ref[1];
            pathFunc = _ref[2];
          }

          path = this.pathFunc('');

          if (pathFunc) {
            path = pathFunc(path);
          }

          msg = _combineMsg(typeOrMsg, path, code, args);
        }

        this.messages.push(msg);

        if (msg.type === 'error') {
          this.isError = this._err = true;
        }

        return msg; // log =
      }
    }, {
      key: "error",
      value: function error(pathFunc, code, args) {
        return this.log('error', pathFunc, code, args); // error: (code, args) ->
      }
    }, {
      key: "warn",
      value: function warn(pathFunc, code, args) {
        return this.log('warn', pathFunc, code, args); // warn: (code, args) ->
      }
    }, {
      key: "info",
      value: function info(pathFunc, code, args) {
        return this.log('info', pathFunc, code, args); // info: (code, args) ->
      }
    }, {
      key: "add",
      value: function add(result) {
        if (!isResult(result)) {
          invalidArg('result', result);
        }

        if (result.messages.length > 0) {
          Array.prototype.push.apply(this.messages, result.messages);
          this.isError = this.isError || result.isError;
          result.reset();
        }

        return this;
      }
    }, {
      key: "reset",
      value: function reset() {
        this.isError = false;
        this.messages.length = 0; // reset:
      }
    }, {
      key: "context",
      value: function context(pathFunc, body) {
        var _this = this;

        if (!(arguments.length <= 2)) {
          tooManyArgs();
        }

        if (arguments.length === 1) {
          var _ref2 = [pathFunc, this.pathFunc];
          body = _ref2[0];
          pathFunc = _ref2[1];
        }

        if (typeof pathFunc !== 'function') {
          invalidArg('pathFunc', pathFunc);
        }

        if (typeof body !== 'function') {
          invalidArg('body', body);
        }

        return function (oldIsError, oldErr, oldPathFunc) {
          // context:
          var res;
          _this.isError = _this._err = false;

          _this.pathFunc = function (path) {
            return pathFunc(oldPathFunc(path));
          };

          res = body();
          _this.isError = _this._err || oldIsError;
          _this._err = _this._err || oldErr;
          _this.pathFunc = oldPathFunc;
          return res;
        }(this.isError, this._err, this.pathFunc);
      }
    }, {
      key: "throwIfError",
      value: function throwIfError() {
        var err;

        if (this.isError) {
          err = new Error(JSON.stringify(this.messages));
          err.code = 'dsc.result';
          this.reset(); // so global Result object could be reused in specs

          throw err; // throwIfError:
        } else {
          this.reset(); // throwIfError: ->
        }
      }
    }]);

    return Result;
  }(); // ----------------------------


  module.exports = Result;
  module.exports._combineMsg = _combineMsg;
  module.exports._reservedAttrs = reservedAttrs;
}).call(void 0);