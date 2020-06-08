# имя API:
# - начинаются с маленьких букв и содержит буквы и цифры

_checkAPIName = (value) -> typeof value == 'string' && /^[a-z][a-zA-Z0-9_]*$/.test value

# ----------------------------

module.exports = _checkAPIName
