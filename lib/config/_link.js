var BitArray, link, linkFields, linkSortedMap, linkTags;

BitArray = require('../bitArray');

linkSortedMap = function(collection, noIndex) {
  var i, j, len, res, v;
  res = {};
  for (i = j = 0, len = collection.length; j < len; i = ++j) {
    v = collection[i];
    res[v.name] = v;
    if (!noIndex) {
      v.$$index = i;
    }
  }
  res.$$list = collection;
  return res;
};

linkFields = function(collection) {
  var _linkLevel, list, map, res;
  map = {};
  list = [];
  _linkLevel = function(level) {
    var j, len, v;
    for (j = 0, len = level.length; j < len; j++) {
      v = level[j];
      if (v.hasOwnProperty('fields')) {
        v.fields = _linkLevel(v.fields);
      }
      v.$$index = list.length;
      list.push(v);
      map[v.name] = v;
    }
    return linkSortedMap(level, true);
  };
  res = _linkLevel(collection);
  (res.$$flat = map).$$list = list;
  return res;
};

linkTags = function(collection, tags) {
  var k, v;
  for (k in tags) {
    v = tags[k];
    tags[k] = new BitArray(collection, v);
  }
  return tags;
};

link = function(config) {
  var doc, j, l, len, len1, len2, m, ref, ref1, ref2, state, transition;
  config.udtypes = linkSortedMap(config.udtypes, true);
  config.docs = linkSortedMap(config.docs, true);
  ref = config.docs.$$list;
  for (j = 0, len = ref.length; j < len; j++) {
    doc = ref[j];
    doc.fields = (function() {
      var field, l, len1, ref1, refName, res, udt, udtList;
      res = linkFields(doc.fields.list);
      res.$$tags = linkTags(res.$$flat.$$list, doc.fields.tags);
      ref1 = res.$$list;
      for (l = 0, len1 = ref1.length; l < len1; l++) {
        field = ref1[l];
        if (field.hasOwnProperty('udType')) {
          udt = config.udtypes[field.udType];
          udtList = [udt.name];
          while (udt.hasOwnProperty('udType')) {
            udt = config.udtypes[udt.udType];
            udtList.push(udt.name);
          }
          field.udType = udtList;
        }
        if (field.hasOwnProperty('$$mask')) {
          field.$$mask = new BitArray(res, field.$$mask);
        }
        if (field.hasOwnProperty('refers')) {
          field.refers = (function() {
            var len2, m, ref2, results;
            ref2 = field.refers;
            results = [];
            for (m = 0, len2 = ref2.length; m < len2; m++) {
              refName = ref2[m];
              results.push(config.docs[refName]);
            }
            return results;
          })();
        }
      }
      return res;
    })();
    doc.actions = (function() {
      var res;
      res = linkSortedMap(doc.actions.list);
      res.$$tags = linkTags(res.$$list, doc.actions.tags);
      return res;
    })();
    doc.states = linkSortedMap(doc.states, true);
    ref1 = doc.states.$$list;
    for (l = 0, len1 = ref1.length; l < len1; l++) {
      state = ref1[l];
      state.view = new BitArray(doc.fields.$$flat.$$list, state.view);
      state.update = new BitArray(doc.fields.$$list, state.update);
      state.transitions = linkSortedMap(state.transitions, true);
      ref2 = state.transitions.$$list;
      for (m = 0, len2 = ref2.length; m < len2; m++) {
        transition = ref2[m];
        transition.next = doc.states[transition.next];
      }
    }
  }
  return config;
};

module.exports = link;
