# API name:
# - starts with a lowercase letter and contains letters and digits

_checkAPIName = (value) -> typeof value == 'string' && /^[a-z][a-zA-Z0-9_]*$/.test value

# ----------------------------

module.exports = _checkAPIName
