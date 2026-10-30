# - namespaces start with a lowercase letter and contain letters and digits

checkTagsNamespace = (value) -> typeof value == 'string' && /^tags[._][a-z][a-zA-Z0-9]*$/.test value

# ----------------------------

module.exports = checkTagsNamespace
