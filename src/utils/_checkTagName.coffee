# a tag name is one namespace or none, separated by dots:
# - namespaces start with a lowercase letter and contain letters and digits
# - a document name starts with a lowercase letter and contains letters and digits

checkTagName = (value) -> typeof value == 'string' && /^([a-z][a-zA-Z0-9]*\.)?[a-z][a-zA-Z0-9]*$/.test value

# ----------------------------

module.exports = checkTagName
