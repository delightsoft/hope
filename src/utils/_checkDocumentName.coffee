# a document name is several namespaces separated by dots:
# - namespaces start with a lowercase letter and contain letters and digits
# - a document name starts with an uppercase letter and contains letters and digits

checkDocumentName = (value) -> typeof value == 'string' && /^([a-z][a-zA-Z0-9]*\.)*[A-Z][a-zA-Z0-9]*$/.test value

# ----------------------------

module.exports = checkDocumentName
