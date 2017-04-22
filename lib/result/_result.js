var Result, _combineMsg, invalidArg, invalidArgValue, isResult, ref, reservedAttrs, reservedPropName, tooManyArgs;

ref = require('../utils').err, invalidArg = ref.invalidArg, invalidArgValue = ref.invalidArgValue, tooManyArgs = ref.tooManyArgs, reservedPropName = ref.reservedPropName, isResult = ref.isResult;

reservedAttrs = ['type', 'path', 'code', 'context', 'text'];

_combineMsg = function(type, path, code, args) {
  var arg, i, k, len, msg, v;
  if (!((typeof type === 'undefined') || (typeof type === 'string' && type.length > 0))) {
    invalidArg('type', type);
  }
  if (type) {
    if (!(type === 'error' || type === 'warn' || type === 'info')) {
      invalidArgValue('type', type);
    }
  }
  if (!(!path || typeof path === 'string')) {
    invalidArg('path', path);
  }
  if (!(typeof code === 'string' && code.length > 0)) {
    invalidArg('code', code);
  }
  if (!((typeof args === 'undefined') || (typeof args === 'object' && args !== null))) {
    invalidArg('args', args);
  }
  if (args) {
    for (i = 0, len = reservedAttrs.length; i < len; i++) {
      arg = reservedAttrs[i];
      if (args.hasOwnProperty(arg)) {
        reservedPropName("args." + arg, args);
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
  return msg;
};

Result = (function() {
  function Result(pathFuncOrResult) {
    if (!(arguments.length <= 1)) {
      tooManyArgs();
    }
    if (arguments.length === 0 || pathFuncOrResult === null) {
      this.pathFunc = function() {
        return '';
      };
    } else {
      if (isResult(pathFuncOrResult)) {
        this.parent = pathFuncOrResult;
        this.pathFunc = pathFuncOrResult.pathFunc || function() {
          return '';
        };
      } else if (typeof pathFuncOrResult === 'function' && pathFuncOrResult !== Result) {
        this.pathFunc = pathFuncOrResult;
      } else {
        invalidArg('pathFuncOrResult', pathFuncOrResult);
      }
    }
    this.messages = [];
    this.isError = this._err = false;
    return;
  }

  Result.prototype.log = function(typeOrMsg, pathFunc, code, args) {
    var msg, path, ref1;
    if (typeof typeOrMsg === 'object' && typeOrMsg !== null) {
      if (!typeOrMsg.hasOwnProperty('code')) {
        invalidArg('typeOrMsg', typeOrMsg);
      }
      msg = typeOrMsg;
    } else {
      if (typeof pathFunc !== 'function') {
        ref1 = [code, pathFunc, null], args = ref1[0], code = ref1[1], pathFunc = ref1[2];
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
    return msg;
  };

  Result.prototype.error = function(pathFunc, code, args) {
    return this.log('error', pathFunc, code, args);
  };

  Result.prototype.warn = function(pathFunc, code, args) {
    return this.log('warn', pathFunc, code, args);
  };

  Result.prototype.info = function(pathFunc, code, args) {
    return this.log('info', pathFunc, code, args);
  };

  Result.prototype.add = function(result) {
    if (!isResult(result)) {
      invalidArg('result', result);
    }
    if (result.messages.length > 0) {
      Array.prototype.push.apply(this.messages, result.messages);
      this.isError = this.isError || result.isError;
      result.reset();
    }
    return this;
  };

  Result.prototype.reset = function() {
    this.isError = false;
    this.messages.length = 0;
  };

  Result.prototype.context = function(pathFunc, body) {
    var ref1;
    if (!(arguments.length <= 2)) {
      tooManyArgs();
    }
    if (arguments.length === 1) {
      ref1 = [pathFunc, this.pathFunc], body = ref1[0], pathFunc = ref1[1];
    }
    if (typeof pathFunc !== 'function') {
      invalidArg('pathFunc', pathFunc);
    }
    if (typeof body !== 'function') {
      invalidArg('body', body);
    }
    return (function(_this) {
      return function(oldIsError, oldErr, oldPathFunc) {
        var res;
        _this.isError = _this._err = false;
        _this.pathFunc = function(path) {
          return pathFunc(oldPathFunc(path));
        };
        res = body();
        _this.isError = _this._err || oldIsError;
        _this._err = _this._err || oldErr;
        _this.pathFunc = oldPathFunc;
        return res;
      };
    })(this)(this.isError, this._err, this.pathFunc);
  };

  Result.prototype.throwIfError = function() {
    var err;
    if (this.isError) {
      err = new Error(JSON.stringify(this.messages));
      this.reset();
      throw err;
    } else {
      this.reset();
    }
  };

  return Result;

})();

module.exports = Result;

module.exports._combineMsg = _combineMsg;

module.exports._reservedAttrs = reservedAttrs;
