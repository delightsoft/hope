_clone = (obj, path, opts) ->

  all = opts?.all

  customClone = opts?.customClone

  for v, i in path by 2 when v == obj

    return path[i + 1]

  path.push obj

  if Array.isArray obj

    path.push clone = []

    for v, i in obj

      clone[i] = if typeof v == 'object' && v != null then _clone(v, path, opts) else v

  else

    path.push clone = {}

    for k, v of obj when all or not k.startsWith '$$'

      if cc = customClone?(k, v, path)

        [clone[k]] = cc unless !cc || cc[0] == undefined

      else

        clone[k] = if typeof v == 'object' && v != null then _clone(v, path, opts) else v

  path.length = path.length - 2

  clone # _clone =

deepClone = (obj, opts) ->

  if typeof obj == 'object' && obj != null then _clone(obj, [], opts) else obj # deepClone =

# ----------------------------

module.exports = deepClone
