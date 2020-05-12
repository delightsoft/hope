
# TODO: заменить на Object.assign

extend = (dest) ->

  for i in [1...arguments.length] by 1

    if s = arguments[i]

      for k in Object.keys(s)

        dest[k] = s[k]

  dest # extend =

# ----------------------------

module.exports = extend
