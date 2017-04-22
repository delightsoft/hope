var Result, checkResult, combineMsg, flatTree, format, formatNoI18n, formatPart, invalidArg, link, ref, ref1, tooManyArgs;

Result = require('./result');

ref = require('./utils'), combineMsg = ref.combineMsg, flatTree = ref.flatTree, (ref1 = ref.err, tooManyArgs = ref1.tooManyArgs, invalidArg = ref1.invalidArg, checkResult = ref1.checkResult);

formatNoI18n = function(message) {
  var res;
  res = "" + message.code + (JSON.stringify(message, function(name, val) {
    if (Result._reservedAttrs.indexOf(name) >= 0) {
      return void 0;
    } else {
      return val;
    }
  }));
  if (res.endsWith('{}')) {
    return res.substr(0, res.length - 2);
  }
  return res;
};

formatPart = function(i18nPart, message) {
  var template;
  if (typeof (template = i18nPart[message.code]) === 'function') {
    return template(message);
  } else if (typeof template !== 'undefined') {
    return "" + template;
  } else {
    return formatNoI18n(message);
  }
};

format = function(i18n, message) {
  var res;
  if (!(typeof i18n === 'undefined' || typeof i18n === 'object')) {
    invalidArg('i18n', i18n);
  }
  if (!(typeof message === 'object' && message !== null && message.hasOwnProperty('code'))) {
    invalidArg('message', message);
  }
  if (!(arguments.length <= 2)) {
    tooManyArgs();
  }
  res = [];
  if (message.hasOwnProperty('path')) {
    res.push(message.path + ": ");
  }
  if (i18n) {
    res.push(formatPart(i18n, message));
  } else {
    res.push(formatNoI18n(message));
  }
  return res.join('');
};

link = function(result, i18n) {
  checkResult(result);
  if (!(typeof i18n === 'object' && i18n !== null)) {
    invalidArg('i18n', config);
  }
  if (!(arguments.length <= 2)) {
    tooManyArgs();
  }
  return flatTree(i18n);
};

module.exports = {
  link: link,
  format: format
};
