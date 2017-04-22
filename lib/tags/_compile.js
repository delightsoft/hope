var BitArray, Result, checkItemName, compile, invalidArg, isResult, ref, ref1, tooManyArgs;

ref = require('../utils'), checkItemName = ref.checkItemName, (ref1 = ref.err, tooManyArgs = ref1.tooManyArgs, invalidArg = ref1.invalidArg, isResult = ref1.isResult);

Result = require('../result');

BitArray = require('../bitArray');

compile = function(result, collection) {
  var _addTag, isFlat, item, k, list, tags, v;
  if (!isResult(result)) {
    invalidArg('result', result);
  }
  if (!(typeof collection === 'object' && collection !== null && collection.hasOwnProperty('$$list'))) {
    invalidArg('collection', collection);
  }
  if (!(arguments.length <= 2)) {
    tooManyArgs();
  }
  tags = {
    all: (new BitArray(collection)).invert()
  };
  _addTag = function(result, dupCheck, tag, item) {
    if ((tag = tag.trim()).length > 0) {
      if (dupCheck.hasOwnProperty(tag)) {
        result.warn('dsc.duplicatedTag', {
          value: tag
        });
      } else {
        dupCheck[tag] = true;
        if (!checkItemName(tag)) {
          result.error('dsc.invalidName', {
            value: tag
          });
        } else if (tag === 'all') {
          result.error('dsc.reservedName', {
            value: 'all'
          });
        } else {
          (tags.hasOwnProperty(tag) ? tags[tag] : tags[tag] = new BitArray(collection)).set(item.$$index);
        }
      }
    }
  };
  list = (isFlat = collection.hasOwnProperty('$$flat')) ? collection.$$flat.$$list : collection.$$list;
  item = void 0;
  result.context((function(path) {
    return (Result.prop('tags', Result.item(item.name)))(path);
  }), function() {
    var dupCheck, i, j, len, results, srcTags, tag;
    results = [];
    for (j = 0, len = list.length; j < len; j++) {
      item = list[j];
      if (!(item.hasOwnProperty('$$src') && item.$$src.hasOwnProperty('tags'))) {
        continue;
      }
      dupCheck = {};
      srcTags = item.$$src.tags;
      if (typeof srcTags === 'string') {
        results.push((function() {
          var l, len1, ref2, results1;
          ref2 = srcTags.split(',');
          results1 = [];
          for (l = 0, len1 = ref2.length; l < len1; l++) {
            tag = ref2[l];
            results1.push(_addTag(result, dupCheck, tag, item));
          }
          return results1;
        })());
      } else if (Array.isArray(srcTags)) {
        results.push((function() {
          var l, len1, results1;
          results1 = [];
          for (i = l = 0, len1 = srcTags.length; l < len1; i = ++l) {
            tag = srcTags[i];
            if (typeof tag === 'string') {
              results1.push(_addTag(result, dupCheck, tag, item));
            } else {
              results1.push(result.error('dsc.invalidTagValue', {
                value: tag,
                index: i
              }));
            }
          }
          return results1;
        })());
      } else {
        results.push(result.error('dsc.invalidValue', {
          value: srcTags
        }));
      }
    }
    return results;
  });
  if (isFlat) {
    for (k in tags) {
      v = tags[k];
      v.fixVertical();
    }
  }
  collection.$$tags = tags;
  return collection;
};

module.exports = compile;
