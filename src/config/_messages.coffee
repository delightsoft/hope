i18n = require '../i18n'

messages =

  dsc:

    ambiguousProp: (args) -> "Ambiguous property #{args.name} values: #{args.value1} and #{args.value2}"

    compilerError: (args) -> "#{args.value}"

    duplicatedName: (args) -> "Dulicated name: #{args.value}"

    invalidExpression: (args) -> "Invalid expression at position #{args.position}: #{args.value}"

    invalidName: (args) -> "Invalid name: #{args.value}"

    invalidTagValue: (args) -> "Invalid tag value at position #{index}: #{value}"

    invalidValue: (args) -> "Invalid value: #{args.value}"

    invalidRegexp: (args) -> "Invalid regexp: #{args.value} (Error: #{args.msg})"

    keyAndNameHasDifferenValues: (args) -> "Key (value: #{args.value1} and name (value: #{value2} have different values"

    missingFile: (args) -> "Missing file: #{args.value}"

    missingProp: (args) -> "Missing property: #{args.value}"

    noSuchFile: (args) -> "Optional file is missing: #{args.value}"

    notApplicableForTheTypeProp: (args) -> "Property #{args.nameValue} is not applicable for type #{args.typeValue}"

    reservedName: (args) -> "Reserved name: #{args.value}"

    unexpectedProp: (args) -> "Unexpected property: #{args.value}"

    unknownAction: (args) -> "Unknown action: #{args.value}"

    unknownDocument: (args) -> "Unknown document: #{args.value}"

    # differentiate items to fields and actions
    unknownItem: (args) -> "Unknown item at position #{args.position}: #{args.value}"

    unknownState: (args) -> "Unknown state: #{args.value}"

    unknownType: (args) -> "Unknown type: #{args.value}"

    tooBig: (args) -> "Too big: #{args.value}"

    tooSmall: (args) -> "Too small: #{args.value}"

    unmatchParenthesis: (args) -> "Unmatch parenthesis at position #{args.position}: #{args.value}"

# DSDocument

    fieldIsReadonly: (args) -> "Field is read-only: #{args.value}"

  validate:

    invalidValue: (args) -> "Invalid value: #{args.value}"

    requiredField: (args) -> "Required field: #{args.value}"

    unexpectedField: (args) -> "Unexpected field: #{args.value}"

    tooShort: (args) -> "Value too short (min length: #{args.min}): '#{args.value}'"

    tooLong: (args) -> "Value too long (max length: #{args.max}): '#{args.value}'"

    tooSmall: (args) -> "Out of range (min: #{args.min}): #{args.value}"

    tooBig: (args) -> "Out of range (max: #{args.max}): #{args.value}"

# ----------------------------

module.exports = (result) ->

  res = i18n.link result, messages

  res unless result.isError
