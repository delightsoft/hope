# - namespace'ы начинаются с маленьких букв и содержит буквы и цифры

checkTagsNamespace = (value) -> typeof value == 'string' && /^tags[._][a-z][a-zA-Z0-9]*$/.test value

# ----------------------------

module.exports = checkTagsNamespace
