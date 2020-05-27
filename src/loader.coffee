path = require 'path'

Result = require './result'

{err: {tooManyArgs, invalidArg, isResult}} = require './utils'

hasOwnProperty = Object::hasOwnProperty

deleteRequireCache = (id) ->

  if !id or id.indexOf('node_modules') != -1
    return

  files = require.cache[id]

  if files != undefined
    Object.keys(files.children).forEach (file) ->
      deleteRequireCache files.children[file].id
      return

    delete require.cache[id]

  return


loader = (result, sourceDir) ->

  invalidArg 'result', result unless isResult result
  invalidArg 'sourceDir', sourceDir unless typeof sourceDir == 'string' && sourceDir.length > 0
  tooManyArgs() unless arguments.length <= 2

  new Promise (resolve, reject) -> # loader =

    dir = path.resolve process.cwd(), sourceDir

    loadFile = (filename, required) ->

      try

        filename = path.join dir, filename

        modId = require.resolve filename

        deleteRequireCache modId

        res = require filename

        res = res.default || res if typeof res == 'object' && res != null && hasOwnProperty.call(res, 'default')

        res = res result if typeof res == 'function'

        res # loadFile =

      catch err

        isFileItself = (err.message.indexOf filename) >= 0

        if isFileItself

          if required

            result.error 'dsc.missingFile', value: filename

          else

            result.warn 'dsc.noSuchFile', value: filename

        else

          result.error (-> filename), 'dsc.compilerError', value: err.message, stack: err.stack

        return # loadFile =

    res =

      docs: loadFile 'docs', true

    res.udtypes = types if (types = loadFile 'types', false)

#    res.rights = rights if (rights = loadFile 'rights', false)

    res.api = api if (api = loadFile 'api', false)

    resolve res

    return # new Promise

# ----------------------------

module.exports = loader
