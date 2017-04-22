_clone = (obj, customClone, path) ->

  for v, i in path by 2 when v == obj

    return path[i + 1]

  path.push obj

  if Array.isArray obj

    path.push clone = []

    for v, i in obj

      clone[i] = if typeof v == 'object' && v != null then _clone(v, customClone, path) else v

  else

    path.push clone = {}

    for k, v of obj when not k.startsWith '$$'

      if cc = customClone?(k, v, path)

        [clone[k]] = cc unless !cc || cc[0] == undefined

      else

        clone[k] = if typeof v == 'object' && v != null then _clone(v, customClone, path) else v

  path.length = path.length - 2

  clone # _clone =

deepClone = (obj, customClone, path) ->

  # Fastest way found in http://stackoverflow.com/questions/122102/what-is-the-most-efficient-way-to-clone-an-object/5344074#5344074

  # JSON.parse JSON.stringify obj

  if typeof obj == 'object' && obj != null then _clone(obj, customClone, (path || [])) else obj # deepClone =

# ----------------------------

module.exports = deepClone
