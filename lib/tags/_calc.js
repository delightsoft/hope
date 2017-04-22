var BitArray, Result, _tokenizer, calc, invalidArg, isResult, ref, tooManyArgs;

ref = require('../utils').err, tooManyArgs = ref.tooManyArgs, invalidArg = ref.invalidArg, isResult = ref.isResult;

Result = require('../result');

BitArray = require('../bitArray');

_tokenizer = function(result, expression) {
  var m, nextToken, p, s;
  p = -1;
  s = 0;
  m = null;
  nextToken = function() {
    var char, wrong;
    while (true) {
      if ((p + 1) === expression.length) {
        switch (s) {
          case 10:
          case 21:
            s = 1;
            return expression.substr(m, p - m + 1);
          case 20:
          case 30:
          case 31:
            result.error('dsc.invalidExpression', {
              value: expression,
              position: p + 1
            });
            s = 100;
            return;
        }
        s = 100;
        return null;
      }
      char = expression.charAt(++p);
      wrong = false;
      switch (s) {
        case 100:
          return null;
        case 0:
          if (/\s/i.test(char)) {
            void 0;
          } else if (/[a-z0-9]/i.test(char)) {
            s = 10;
            m = p;
          } else if (char === '!') {
            s = 31;
            return '!';
          } else if (char === '#') {
            s = 20;
            m = p;
          } else if (char === '(') {
            s = 0;
            return '(';
          } else {
            wrong = true;
          }
          break;
        case 1:
          if (/\s/i.test(char)) {
            void 0;
          } else if (char === ',') {
            s = 30;
            return '+';
          } else if (char === '+' || char === '-' || char === '&') {
            s = 30;
            return char;
          } else if (char === ')') {
            s = 1;
            m = p;
            return ')';
          } else {
            wrong = true;
          }
          break;
        case 10:
          if (/[a-z0-9\.]/i.test(char)) {
            void 0;
          } else {
            p--;
            s = 1;
            return expression.substr(m, p - m + 1);
          }
          break;
        case 20:
          if (/[a-z0-9]/i.test(char)) {
            s = 21;
          } else {
            wrong = true;
          }
          break;
        case 21:
          if (/[a-z0-9]/i.test(char)) {
            s = 21;
          } else {
            p--;
            s = 1;
            return expression.substr(m, p - m + 1);
          }
          break;
        case 30:
          if (/\s/i.test(char)) {
            void 0;
          } else if (/[a-z0-9]/i.test(char)) {
            s = 10;
            m = p;
          } else if (char === '#') {
            s = 20;
            m = p;
          } else if (char === '(') {
            s = 0;
            return '(';
          } else if (char === '!') {
            s = 31;
            return '!';
          } else {
            wrong = true;
          }
          break;
        case 31:
          if (/\s/i.test(char)) {
            void 0;
          } else if (/[a-z0-9]/i.test(char)) {
            s = 10;
            m = p;
          } else if (char === '#') {
            s = 20;
            m = p;
          } else if (char === '(') {
            s = 0;
            return '(';
          } else {
            wrong = true;
          }
          break;
        default:
          throw new Error("Unexpected s: " + s);
      }
      if (wrong) {
        result.error('dsc.invalidExpression', {
          value: expression,
          position: p
        });
        s = 100;
        return;
      }
    }
  };
  Object.defineProperty(nextToken, 'position', {
    get: function() {
      if (s === 1) {
        return m;
      } else {
        return p;
      }
    }
  });
  return nextToken;
};

calc = function(result, collection, expression) {
  var _calcExpr, expr, fieldMask, isFlat, level, levels, map, nextToken, res, tag, token;
  if (!isResult(result)) {
    invalidArg('result', result);
  }
  if (!(typeof collection === 'object' && collection !== null && collection.hasOwnProperty('$$list'))) {
    invalidArg('collection', collection);
  }
  if (typeof expression !== 'string') {
    invalidArg('expression', expression);
  }
  if (!(arguments.length <= 3)) {
    tooManyArgs();
  }
  nextToken = _tokenizer(result, expression);
  expr = [];
  levels = [];
  map = (isFlat = collection.hasOwnProperty('$$flat')) ? collection.$$flat : collection;
  while (token = nextToken()) {
    switch (token) {
      case '+':
      case '-':
      case '&':
      case '!':
        expr.push(token);
        break;
      case '(':
        expr.push(level = []);
        levels.push(expr);
        expr = level;
        break;
      case ')':
        if (!(levels.length > 0)) {
          result.error('dsc.unmatchParenthesis', {
            position: nextToken.position,
            value: expression
          });
        } else {
          expr = levels.pop();
        }
        break;
      default:
        if (token.startsWith('#')) {
          if (token === '#all') {
            expr.push(collection.$$tags.all);
          } else if (collection.$$tags.hasOwnProperty(tag = token.substr(1))) {
            expr.push(collection.$$tags[tag]);
          } else {
            result.error('dsc.unknownTag', {
              value: tag,
              position: nextToken.position
            });
          }
        } else {
          if (!map.hasOwnProperty(token)) {
            result.error('dsc.unknownItem', {
              value: token,
              position: nextToken.position
            });
          } else if (map[token].hasOwnProperty('$$mask')) {
            expr.push(map[token].$$mask);
          } else {
            fieldMask = new BitArray(collection);
            fieldMask.set(map[token].$$index);
            expr.push(fieldMask);
          }
        }
    }
  }
  if (result.isError) {
    return;
  }
  if (levels.length > 0) {
    result.error('dsc.unmatchParenthesis', {
      position: expression.length,
      value: expression
    });
    return;
  }
  _calcExpr = function(expr) {
    var i, j, k, len, p, v;
    for (i = j = 0, len = expr.length; j < len; i = ++j) {
      v = expr[i];
      if (Array.isArray(v)) {
        expr[i] = _calcExpr(v);
      }
    }
    for (i = k = expr.length - 1; k >= 0; i = k += -1) {
      v = expr[i];
      if (!(v === '!')) {
        continue;
      }
      expr[i + 1] = expr[i + 1].invert();
      expr.splice(i, 1);
    }
    p = 1;
    while (p < expr.length) {
      if ((v = expr[p]) === '+') {
        expr[p - 1] = expr[p - 1].or(expr[p + 1]);
        expr.splice(p, 2);
      } else if (v === '-') {
        expr[p - 1] = expr[p - 1].subtract(expr[p + 1]);
        expr.splice(p, 2);
      } else {
        p += 2;
      }
    }
    p = expr.length - 2;
    while (p > 0) {
      if (expr[p] === '&') {
        expr[p - 1] = expr[p - 1].and(expr[p + 1]);
      }
      p -= 2;
    }
    return expr[0];
  };
  res = _calcExpr(expr);
  if (isFlat) {
    res.clearVertical();
  }
  return res;
};

module.exports = calc;

module.exports._tokenizer = _tokenizer;
