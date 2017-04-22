fs = require 'fs'
path = require 'path'

{config: {unlink: unlinkConfig}, utils: {err: {invalidArg, invalidValue, tooManyArgs}}} = require '../index'

class ConfigContainer

  constructor: ->

    @_config = null

    @_watch = []

  set: (config) ->

    @_config = config

    #listener config for listener in @_watch by -1
    for listener in @_watch by -1

      listener config

    return

  watch: (listener) ->

    invalidArg 'listener', listener unless typeof listener == 'function'

    (watch = @_watch).push listener

    if @_config # first I should return 'unwatch'

      process.nextTick =>

        listener @_config

        return

    active = true
    return ->
      if active
        active = false
        watch.splice watch.indexOf(listener), 1

  save: (destFile, opts) ->

    invalidArg  'destFile', destFile unless typeof destFile == 'string' && destFile.length > 0
    invalidArg 'opts', opts unless typeof opts == 'undefined' || (typeof opts == 'object' && opts != null)
    tooManyArgs() unless arguments.length <= 2

    tab = undefined

    if opts
      for k, v of opts
        switch k
          when 'tab'
            invalidValue 'opts.tab', v unless typeof v == 'string'
            tab = v
          else
            invalidArg "opts.#{k}", v

    @watch (config) =>

      dir = path.join process.cwd(), path.dirname(destFile)

      fs.mkdirSync dir unless fs.existsSync dir

      file = path.join(dir, path.basename(destFile))

      fs.unlinkSync file if fs.existsSync file

      fs.writeFileSync file, JSON.stringify unlinkConfig(config), null, tab

      return # @watch

    return # save:

# ----------------------------

module.exports = ConfigContainer