var Result, compileTags, compileType, flatMap, processFields, ref, ref1, typeProps;

Result = require('../result');

flatMap = require('../flatMap');

ref = require('../types'), compileType = ref.compile, (ref1 = ref.compile, typeProps = ref1._typeProps);

compileTags = require('../tags').compile;

processFields = function(result, doc, config) {
  if (!doc.$$src.hasOwnProperty('fields')) {
    result.error('dsc.missingProp', {
      value: 'fields'
    });
    return;
  }
  return result.context(Result.prop('fields'), function() {
    var _processLevel, res;
    res = flatMap(result, doc.$$src.fields, 'fields', {
      index: true,
      mask: true
    });
    if (!result.isError) {
      _processLevel = function(level) {
        var field;
        field = void 0;
        result.context((function(path) {
          return (Result.item(field.name))(path);
        }), function() {
          var i, j, len, len1, prop, ref2, udt, udtList;
          ref2 = level.$$list;
          for (i = 0, len = ref2.length; i < len; i++) {
            field = ref2[i];
            result.isError = false;
            compileType(result, field.$$src, field, {
              context: 'field'
            });
            if (field.hasOwnProperty('udType') && config.hasOwnProperty('udtypes')) {
              if (!config.udtypes.hasOwnProperty(field.udType)) {
                result.error('dsc.unknownType', {
                  value: field.udType
                });
              } else {
                udt = config.udtypes[field.udType];
                field.type = udt.type;
                for (j = 0, len1 = typeProps.length; j < len1; j++) {
                  prop = typeProps[j];
                  if (udt.hasOwnProperty(prop)) {
                    field[prop] = udt[prop];
                  }
                }
                udtList = [udt.name];
                while (udt.hasOwnProperty('udType')) {
                  udt = config.udtypes[udt.udType];
                  udtList.push(udt.name);
                }
                field.udType = udtList;
              }
            }
            if (!result.isError) {
              if (field.hasOwnProperty('fields')) {
                result.context(Result.prop('fields'), function() {
                  return _processLevel(field.fields);
                });
              }
            }
          }
        });
      };
      _processLevel(res);
      compileTags(result, res);
      flatMap.finish(result, res, 'fields', {
        skipProps: ['tags']
      });
      if (!result.isError) {
        return res;
      }
    }
  });
};

module.exports = processFields;
