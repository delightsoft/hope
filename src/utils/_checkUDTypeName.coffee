# a ud type name is several namespaces separated by dots:
# - namespaces start with a lowercase letter and contain letters and digits
# - a document name starts with a lowercase letter and contains letters and digits

checkUDTypeName = (value) -> typeof value == 'string' && /^([a-z][a-zA-Z0-9]*\.)*[a-z][a-zA-Z0-9]*$/.test value

# ----------------------------

module.exports = checkUDTypeName
