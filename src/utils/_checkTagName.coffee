# имя тега - это один namespace или ни одного разделенных точками:
# - namespace'ы начинаются с маленьких букв и содержит буквы и цифры
# - имя документа начинается с маленьких букв и содержит буквы и цифры

checkTagName = (value) -> typeof value == 'string' && /^([a-z][a-zA-Z0-9]*\.)?[a-z][a-zA-Z0-9]*$/.test value

# ----------------------------

module.exports = checkTagName
