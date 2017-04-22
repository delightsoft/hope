# String::endsWith
# ----------------------------

unless String::endsWith
  String::endsWith = (searchString, position) ->
    subjectString = @toString()
    if position == undefined or position > subjectString.length
      position = subjectString.length
    position -= searchString.length
    lastIndex = subjectString.indexOf(searchString, position)
    lastIndex != -1 and lastIndex == position # String::endsWith =


unless Array::indexOf
  Array::indexOf = (searchElement, fromIndex) ->
    k = undefined
    if `this == null`
      throw new TypeError('"this" is null or not defined')
    O = Object(this)
    len = O.length >>> 0
    if `len == 0`
      return -1
    n = +fromIndex or 0
    if `Math.abs(n) == Infinity`
      n = 0
    if n >= len
      return -1
    k = Math.max (if n >= 0 then n else len - Math.abs(n)), 0
    while k < len
      if k of O and `O[k] == searchElement`
        return k
      k++
    -1 # indexOf

unless Array::lastIndexOf
  Array::lastIndexOf = (searchElement) ->
    if `this == void 0` or `this == null`
      throw new TypeError
    n = undefined
    k = undefined
    t = Object(this)
    len = t.length >>> 0
    if `len == 0`
      return -1
    n = len - 1
    if arguments.length > 1
      n = Number(arguments[1])
      if `n != n`
        n = 0
      else if `n != 0` and `n != 1 / 0` and `n != -(1 / 0)`
        n = (n > 0 or -1) * Math.floor(Math.abs(n))
    k = if n >= 0 then Math.min(n, len - 1) else len - Math.abs(n)
    while k >= 0
      if k of t and `t[k] == searchElement`
        return k
      k--
    -1 # lastIndexOf
