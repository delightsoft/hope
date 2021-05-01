nindex = 0

_clone = (obj, map, opts) ->

  all = opts?.all

  customClone = opts?.customClone

  return v if (v = map.get obj)

  if Array.isArray obj

    map.set obj, clone = []

    for v, i in obj

      clone[i] = if typeof v == 'object' && v != null then _clone(v, map, opts) else v

  else

    map.set obj, clone = Object.create obj.__proto__ || null

    for k, v of obj when all or not k.startsWith '$$'

      if cc = customClone?(k, v, map)

        [clone[k]] = cc unless !cc || cc[0] == undefined

      else

        clone[k] = if typeof v == 'object' && v != null then _clone(v, map, opts) else v

  clone # _clone =

deepClone = (value, opts) ->

  if typeof value == 'object' && value != null then _clone(value, new WeakMap, opts) else value # deepClone =

# ----------------------------

module.exports = deepClone
