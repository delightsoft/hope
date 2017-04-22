path = require 'path'

cwd = process.cwd()

err = path.join cwd, 'utils/_err'

node_modules = path.join cwd, 'node_modules'

lightStack = (stack) ->

  rows = stack.split '\n'

  for r, i in rows by -1

    if (p = r.indexOf cwd) >= 0 && not (r.indexOf(err) >= 0 || r.indexOf(node_modules) >= 0)

      end = r.substr (p + cwd.length)

      rows[i] = r.substr(0, p) + end

    else

      rows.splice i, 1

  rows.join '\n' # lightStack =

# ----------------------------

module.exports = lightStack