var i18n, messages;

i18n = require('../i18n');

messages = {
  dsc: {
    ambiguousProp: function(args) {
      return "Ambiguous property " + args.name + " values: " + value1 + " and " + value2;
    },
    compilerError: function(args) {
      return "" + args.value;
    },
    duplicatedName: function(args) {
      return "Dulicated name: " + args.value;
    },
    invalidExpression: function(args) {
      return "Invalid expression at position " + args.position + ": " + args.value;
    },
    invalidName: function(args) {
      return "Invalid name: " + args.value;
    },
    invalidTagValue: function(args) {
      return "Invalid tag value at position " + index + ": " + value;
    },
    invalidValue: function(args) {
      return "Invalid value: " + args.value;
    },
    keyAndNameHasDifferenValues: function(args) {
      return "Key (value: " + args.value1 + " and name (value: " + value2 + " have different values";
    },
    missingFile: function(args) {
      return "Missing file: " + args.value;
    },
    missingProp: function(args) {
      return "Missing property: " + args.value;
    },
    noSuchFile: function(args) {
      return "Optional file is missing: " + args.value;
    },
    notApplicableForTheTypeProp: function(args) {
      return "Property " + args.name + " is not applicable for type " + args.type;
    },
    reservedName: function(args) {
      return "Reserved name: " + args.value;
    },
    unexpectedProp: function(args) {
      return "Unexpected property: " + args.value;
    },
    unknownAction: function(args) {
      return "Unknown action: " + args.value;
    },
    unknownDocument: function(args) {
      return "Unknown document: " + args.value;
    },
    unknownItem: function(args) {
      return "Unknown item at position " + args.position + ": " + args.value;
    },
    unknownState: function(args) {
      return "Unknown state: " + args.value;
    },
    unknownType: function(args) {
      return "Unknown type: " + args.value;
    },
    unmatchParenthesis: function(args) {
      return "Unmatch parenthesis at position " + args.position + ": " + args.value;
    },
    fieldIsReadonly: function(args) {
      return "Field is read-only: " + args.value;
    }
  }
};

module.exports = function(result) {
  var res;
  res = i18n.link(result, messages);
  if (!result.isError) {
    return res;
  }
};
