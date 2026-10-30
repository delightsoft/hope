# a document field name can consist only of English letters and digits. and it can only start
# with a lowercase letter.

checkItemName = (value) -> typeof value == 'string' && /^[a-z][a-zA-Z0-9]*$/.test value

# ----------------------------

module.exports = checkItemName