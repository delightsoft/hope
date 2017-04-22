MAX_LIST = 10
MAX_LEVELS = 2

printList = (list, level, maxLevel) ->

  res = (for i in [0...Math.min(list.length, MAX_LIST)]

    prettyPrint list[i], level, maxLevel).join ', '

  "[#{res}#{if list.length > MAX_LIST then ' ...]' else ']'}"

printMap = (map, level, maxLevel) ->

  c = 0

  res = (for k, v of map when not k.startsWith '$'

    break unless c++ < MAX_LIST

    key = if /^[\w_\$#\.]*$/g.test k then "#{k}" else "'#{k}'"

    val = prettyPrint v, level, maxLevel

    "#{key}: #{val}").join ', '

  "{#{res}#{if c > MAX_LIST then ' ...}' else '}'}"

prettyPrint = (arg, level, maxLevel) ->

  if typeof arg == 'object' && arg != null

    level = if level == undefined then 0 else level + 1

    if level == (maxLevel || MAX_LEVELS)

      if Array.isArray(arg) then "[list]" else "[object]"

    else if Array.isArray(arg)

      printList arg, level, maxLevel

    else

      printMap arg, level, maxLevel

  else if typeof arg == 'string'

    "'#{arg}'"

  else

    "#{arg}"

# ----------------------------

module.exports = prettyPrint