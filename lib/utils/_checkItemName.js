var checkItemName;

checkItemName = function(value) {
  return typeof value === 'string' && /^[a-z][a-zA-Z0-9]*$/.test(value);
};

module.exports = checkItemName;
