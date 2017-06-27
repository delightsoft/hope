var Reporter, Result, i18n, invalidArg, isResult, ref, tooManyArgs;

i18n = require('./i18n');

ref = require('./utils').err, tooManyArgs = ref.tooManyArgs, invalidArg = ref.invalidArg, isResult = ref.isResult;

Result = require('./result');

Reporter = (function() {
  function Reporter(i18n1) {
    this.i18n = i18n1;
    if (!(typeof this.i18n === 'undefined' || (typeof this.i18n === 'object' && this.i18n !== null))) {
      throw new Error("Invalid argument 'i18n'");
    }
    this.isError = this._err = false;
    this.pathFunc = function() {
      return '';
    };
    this.messages = 0;
    this.errors = 0;
    this.warnings = 0;
    return;
  }

  Reporter.prototype.log = function(typeOrMsg, pathFunc, code, args) {
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
      path = this.pathFunc(path);
      if (pathFunc) {
        path = pathFunc(path);
      }
      msg = Result._combineMsg(typeOrMsg, path, code, args);
    }
    switch (msg.type) {
      case 'error':
        this.errors++;
        this.isError = this._err = true;
        break;
      case 'warn':
        this.warnings++;
    }
    this._print((msg.type ? msg.type : 'info'), i18n.format(this.i18n, msg));
    return msg;
  };

  Reporter.prototype.error = Result.prototype.error;

  Reporter.prototype.warn = Result.prototype.warn;

  Reporter.prototype.info = Result.prototype.info;

  Reporter.prototype.logResult = function(result, pathFunc, msgCode, args) {
    var i, j, len, len1, msg, path, ref1, ref2, ref3, type;
    if (!isResult(result)) {
      invalidArg('result', result);
    }
    if (!(arguments.length <= 4)) {
      tooManyArgs();
    }
    if (pathFunc) {
      if (typeof pathFunc !== 'function') {
        ref1 = [msgCode, pathFunc, null], args = ref1[0], msgCode = ref1[1], pathFunc = ref1[2];
      }
      if (!((typeof msgCode === 'undefined') || (typeof msgCode === 'string' && msgCode.length > 0))) {
        invalidArg('msgCode', msgCode);
      }
      if (!((typeof args === 'undefined') || (msgCode && typeof args === 'object' && args !== null))) {
        invalidArg('args', args);
      }
      type = 'info';
      ref2 = result.messages;
      for (i = 0, len = ref2.length; i < len; i++) {
        msg = ref2[i];
        switch (msg.type) {
          case 'error':
            type = 'error';
            break;
          case 'warn':
            if (type === 'info') {
              type = 'warn';
            }
        }
      }
      path = pathFunc ? pathFunc('') : '';
      this._print(type, i18n.format(this.i18n, Result._combineMsg(type, path, msgCode, args)));
    }
    ref3 = result.messages;
    for (j = 0, len1 = ref3.length; j < len1; j += 1) {
      msg = ref3[j];
      this._print((msg.type ? msg.type : 'info'), i18n.format(this.i18n, msg));
    }
    return this;
  };

  Reporter.prototype.context = Result.prototype.context;

  return Reporter;

})();

module.exports = Reporter;
