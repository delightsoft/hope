# имя поля документа может состояить только из английских букв и цифр. и начинаться может только
# c маленькой буквы.

checkItemName = (value) -> typeof value == 'string' && /^[a-z][a-zA-Z0-9]*$/.test value

# ----------------------------

module.exports = checkItemName