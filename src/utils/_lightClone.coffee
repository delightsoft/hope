lightClone = (obj) ->

  if typeof obj == 'object' && obj != null

    if Array.isArray(obj)

      obj.slice() # lightClone =

    else

      res = {}

      for k, v of obj when not k.startsWith('$$')

        res[k] = v

      res # lightClone =

  else

    obj # lightClone =

# ----------------------------

module.exports = lightClone
