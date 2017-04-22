var Result, checkDocumentName, processActions, processDocs, processFields, processRefers, processStates, sortedMap;

checkDocumentName = require('../utils').checkDocumentName;

Result = require('../result');

sortedMap = require('../sortedMap');

processFields = require('./_processFields');

processActions = require('./_processActions');

processStates = require('./_processStates');

processRefers = require('./_processRefers');

processDocs = function(result, config) {
  if (!config.$$src.hasOwnProperty('docs')) {
    result.error('dsc.missingProp', {
      value: 'docs'
    });
    return;
  }
  return result.context(Result.prop('docs'), function() {
    var doc, res;
    res = sortedMap(result, config.$$src.docs, {
      checkName: checkDocumentName
    });
    if (!result.isError) {
      doc = void 0;
      result.context((function(path) {
        return (Result.item(doc.name))(path);
      }), function() {
        var i, len, ref;
        ref = res.$$list;
        for (i = 0, len = ref.length; i < len; i++) {
          doc = ref[i];
          result.isError = false;
          if (doc.name.indexOf('.') === -1) {
            delete res[doc.name];
            doc.name = "doc." + doc.name;
            res[doc.name] = doc;
          }
          doc.fields = processFields(result, doc, config);
          doc.actions = processActions(result, doc);
          if (!result.isError) {
            doc.states = processStates(result, doc, doc.fields, doc.actions);
          }
        }
      });
      res.$$list.sort(function(left, right) {
        if (left.name < right.name) {
          return -1;
        } else {
          return 1;
        }
      });
      sortedMap.finish(result, res);
      if (!result.isError) {
        processRefers(result, res);
        if (!result.isError) {
          config.docs = res;
        }
      }
    }
  });
};

module.exports = processDocs;
