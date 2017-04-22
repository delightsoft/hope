require('./polyfills');

module.exports = {
  Result: require('./result'),
  BitArray: require('./bitArray'),
  Reporter: require('./reporter'),
  loader: require('./loader'),
  i18n: require('./i18n'),
  utils: require('./utils'),
  types: require('./types'),
  tags: require('./tags'),
  config: require('./config'),
  sortedMap: require('./sortedMap'),
  flatMap: require('./flatMap'),
  compareStructures: require('./compareStructures')
};

module.exports["default"] = module.exports;
