# имя документа - это несколько namespace'ов разделенных точками:
# - namespace'ы начинаются с маленьких букв и содержит буквы и цифры
# - имя документа начинается с большой буквы и содержит буквы и цифры

checkItemName = (value) -> typeof value == 'string' && /^([a-z][a-zA-Z0-9]*\.)*[A-Z][a-zA-Z0-9]*$/.test value

# ----------------------------

module.exports = checkItemName