var Result, builtInTypes, checkItemName, compile, invalidArg, invalidArgValue, isResult, ref, ref1, reservedTypes, setRequiredProp, sortedMap, takeBoolean, takeEnum, takeFields, takePositiveInt, takeString, takeStringOrArrayOfStrings, tooManyArgs, typeProps;

ref = require('../utils'), checkItemName = ref.checkItemName, (ref1 = ref.err, tooManyArgs = ref1.tooManyArgs, invalidArg = ref1.invalidArg, invalidArgValue = ref1.invalidArgValue, isResult = ref1.isResult);

Result = require('../result');

sortedMap = require('../sortedMap');

typeProps = ['length', 'enum', 'fields', 'refers', 'valueClass', 'nullable'];

builtInTypes = ['string', 'text', 'boolean', 'integer', 'double', 'time', 'date', 'dateonly', 'now', 'json', 'blob', 'uuid', 'enum', 'structure', 'subtable', 'refers', 'dsvalue'];

reservedTypes = ['long', 'float', 'decimal'];

compile = function(result, fieldDesc, res, opts) {
  var enumProp, fieldsProp, lengthProp, nullableProp, options, optionsEnd, optionsIndex, optionsLen, optsContext, precisionProp, prop, refersProp, scaleProp, sourceType, type, valueClass;
  if (!isResult(result)) {
    invalidArg('result', result);
  }
  if (!(typeof fieldDesc === 'object' && fieldDesc !== null)) {
    invalidArg('fieldDesc', fieldDesc);
  }
  if (!(res === void 0 || (typeof res === 'object' && res !== null && !Array.isArray(res)))) {
    invalidArg('res', fieldDesc);
  }
  if (!(opts === void 0 || (typeof opts === 'object' && opts !== null && !Array.isArray(opts)))) {
    invalidArg('opts', opts);
  }
  if (!(arguments.length <= 4)) {
    tooManyArgs();
  }
  if (!(opts != null ? opts.hasOwnProperty('context') : void 0)) {
    optsContext = null;
  } else {
    if (!((optsContext = opts.context) === 'field' || optsContext === 'udtype')) {
      invalidArgValue('opts.context', opts.context);
    }
  }
  if (!!fieldDesc.hasOwnProperty('$$tags')) {
    throw new Error("fieldDesc was alreay process by tags/compile()");
  }
  if (fieldDesc.hasOwnProperty('type')) {
    if ((optionsIndex = (type = sourceType = fieldDesc.type.trim()).indexOf('(')) !== -1) {
      if (!((optionsEnd = (options = type.indexOf(')'))) > optionsIndex)) {
        result.error('dsc.invalidTypeValue', {
          value: type
        });
        return;
      }
      if (optionsEnd !== type.length - 1) {
        result.error('dsc.invalidTypeValue', {
          value: type
        });
        return;
      }
      if ((optionsLen = optionsEnd - optionsIndex - 1) === 0) {
        result.error('dsc.invalidTypeValue', {
          value: type
        });
        return;
      }
      options = type.substr(optionsIndex + 1, optionsLen);
      type = type.substr(0, optionsIndex).trim();
    }
    if (!checkItemName(type)) {
      result.error('dsc.invalidTypeValue', {
        value: type
      });
      return;
    }
  } else if (fieldDesc.hasOwnProperty('enum')) {
    type = 'enum';
  } else if (fieldDesc.hasOwnProperty('fields')) {
    type = 'structure';
  } else if (fieldDesc.hasOwnProperty('refers')) {
    type = 'refers';
  } else {
    result.error('dsc.missingProp', {
      value: 'type'
    });
    return;
  }
  switch (type) {
    case 'str':
      type = 'string';
      break;
    case 'bool':
      type = 'boolean';
      break;
    case 'int':
      type = 'integer';
      break;
    case 'struct':
      type = 'structure';
      break;
    case 'ref':
      type = 'refers';
      break;
    case 'value':
      type = 'dsvalue';
  }
  if (!(builtInTypes.indexOf(type) >= 0)) {
    if (reservedTypes.indexOf(type) >= 0) {
      result.error('dsc.reservedType', {
        value: sourceType
      });
    } else if (options) {
      result.error('dsc.unknownType', {
        value: sourceType
      });
    } else {
      result.context((function(path) {
        return (Result.prop(prop))(path);
      }), function() {
        var i, len, prop, results;
        results = [];
        for (i = 0, len = typeProps.length; i < len; i++) {
          prop = typeProps[i];
          if (fieldDesc.hasOwnProperty(prop) && prop !== 'nullable') {
            results.push(result.error('dsc.notApplicableForTheTypeProp', {
              name: prop,
              type: type
            }));
          }
        }
        return results;
      });
      (res != null ? res : res = {}).udType = type;
      if (typeof nullableProp === 'boolean') {
        res.nullable = nullableProp;
      }
      if (!result.isError) {
        return res;
      }
    }
    return;
  }
  if ((optsContext === null || optsContext === 'field') && type === 'dsvalue') {
    result.error('dsc.notAllowedInFieldDef', {
      value: type
    });
    return;
  }
  prop = lengthProp = enumProp = precisionProp = scaleProp = fieldsProp = nullableProp = refersProp = valueClass = void 0;
  if (fieldDesc.hasOwnProperty('udType')) {
    result.error('dsc.reservedAttr', {
      value: 'udType'
    });
  }
  result.context((function(path) {
    return (Result.prop(prop))(path);
  }), function() {
    var i, len, ok, results;
    results = [];
    for (i = 0, len = typeProps.length; i < len; i++) {
      prop = typeProps[i];
      if (!(fieldDesc.hasOwnProperty(prop))) {
        continue;
      }
      ok = false;
      switch (prop) {
        case 'length':
          if ((ok = type === 'string')) {
            lengthProp = takePositiveInt(result, fieldDesc.length);
          }
          break;
        case 'enum':
          if ((ok = type === 'enum')) {
            enumProp = takeEnum(result, fieldDesc["enum"]);
          }
          break;
        case 'precision':
          if ((ok = type === 'decimal')) {
            precisionProp = takePositiveInt(result, fieldDesc.precision);
          }
          break;
        case 'scale':
          if ((ok = type === 'decimal')) {
            scaleProp = takePositiveInt(result, fieldDesc.scale);
          }
          break;
        case 'fields':
          if ((ok = type === 'structure' || type === 'subtable')) {
            fieldsProp = takeFields(result, fieldDesc.fields);
          }
          break;
        case 'nullable':
          if (optsContext === null || optsContext === 'field') {
            if ((ok = !(type === 'now' || type === 'structure' || type === 'subtable'))) {
              nullableProp = takeBoolean(result, fieldDesc.nullable);
            }
          } else {
            ok = true;
            result.error('dsc.notApplicableInUdtype');
          }
          break;
        case 'refers':
          if ((ok = type === 'refers')) {
            refersProp = takeStringOrArrayOfStrings(result, fieldDesc.refers);
          }
      }
      if (!ok) {
        results.push(result.error('dsc.notApplicableForTheTypeProp', {
          name: prop,
          type: type
        }));
      } else {
        results.push(void 0);
      }
    }
    return results;
  });
  if (result.isError) {
    return;
  }
  if (options) {
    result.context((function(path) {
      return (Result.prop("(" + options + ")"))(path);
    }), function() {
      var lengthPropFromOptions, refersPropFromOptions, value;
      switch (type) {
        case 'string':
          if (isNaN(value = parseInt(options))) {
            return result.error('dsc.invalidValue', {
              value: options
            });
          } else {
            lengthPropFromOptions = takePositiveInt(result, value);
            if (lengthProp) {
              return result.error('dsc.ambiguousProp', {
                name: 'length',
                value1: lengthPropFromOptions || options,
                value2: lengthProp
              });
            } else {
              return lengthProp = lengthPropFromOptions;
            }
          }
          break;
        case 'refers':
          if ((refersPropFromOptions = options.trim()).length === 0) {
            return result.error('dsc.invalidValue', {
              value: options
            });
          } else if (refersProp) {
            return result.error('dsc.ambiguousProp', {
              name: 'refers',
              value1: refersPropFromOptions || options,
              value2: refersProp
            });
          } else {
            return refersProp = refersPropFromOptions;
          }
          break;
        default:
          return result.error('dsc.unknownType', {
            value: sourceType
          });
      }
    });
  }
  if (result.isError) {
    return;
  }
  (res != null ? res : res = {}).type = type;
  if (typeof nullableProp === 'boolean') {
    res.nullable = nullableProp;
  }
  switch (type) {
    case 'string':
      setRequiredProp(result, res, 'length', lengthProp);
      break;
    case 'enum':
      setRequiredProp(result, res, 'enum', enumProp);
      break;
    case 'decimal':
      setRequiredProp(result, res, 'precision', precisionProp);
      if (typeof scaleProp === 'number') {
        res.scale = scaleProp;
      }
      break;
    case 'structure':
      setRequiredProp(result, res, 'fields', fieldsProp);
      break;
    case 'subtable':
      setRequiredProp(result, res, 'fields', fieldsProp);
      break;
    case 'refers':
      setRequiredProp(result, res, 'refers', refersProp);
  }
  return res;
};

takePositiveInt = function(result, value) {
  if (!(typeof value === 'number' && Math.floor(value) === value && value > 0)) {
    result.error('dsc.invalidValue', {
      value: value
    });
    return;
  }
  return value;
};

takeBoolean = function(result, value) {
  if (typeof value !== 'boolean') {
    result.error('dsc.invalidValue', {
      value: value
    });
    return;
  }
  return value;
};

takeString = function(result, value) {
  if (typeof value === 'string') {
    return value;
  }
  result.error('dsc.invalidValue', {
    value: value
  });
};

takeStringOrArrayOfStrings = function(result, value) {
  var i, len, ok, s;
  if (typeof value === 'string') {
    return value;
  } else if (Array.isArray(value)) {
    ok = true;
    for (i = 0, len = value.length; i < len; i++) {
      s = value[i];
      if (typeof s !== 'string') {
        ok = false;
        break;
      }
    }
    if (ok) {
      return value;
    }
  }
  result.error('dsc.invalidValue', {
    value: value
  });
};

takeEnum = function(result, value) {
  return sortedMap(result, value, {
    string: true,
    boolean: true
  });
};

takeFields = function(result, value) {
  return sortedMap(result, value);
};

setRequiredProp = function(result, res, propName, value) {
  if (typeof value === 'undefined') {
    result.error('dsc.missingProp', {
      name: propName
    });
    return;
  }
  res[propName] = value;
};

module.exports = compile;

compile._builtInTypes = builtInTypes;

compile._reservedTypes = reservedTypes;

compile._typeProps = typeProps;
