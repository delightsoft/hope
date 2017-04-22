flat = (dst, src, prefix) ->

  for k, v of src

    if typeof v == 'object' && v != null

      flat dst, v, "#{prefix}#{k}."

    else

      dst["#{prefix}#{k}"] = v

  return # flat =

# ----------------------------

flatTree = (src) ->

  flat (res = {}), src, ''

  res # flatTree:

# ----------------------------

module.exports = flatTree
