path = require 'path'
gutil = require 'gulp-util'
rename = require 'gulp-rename'
through = require 'through2'
changed = require 'gulp-changed'

{Result, Reporter, loader: configLoader, config: {compile: configCompile, messages: messagesCompile}} = require '../index'

module.exports = (DSGulpBuilder) ->

  {invalidArg, tooManyArgs, missingArg, unsupportedOption, invalidOptionType, preprocessPath} = TaskBase = DSGulpBuilder.TaskBase

  class CompileConfig extends TaskBase # module.exports =

    [oldMixinAssert, @::_mixinAssert] = [@::_mixinAssert, ->

      oldMixinAssert?.call @

      if @_configContainer == null

        throw new Error "Task '#{@_name}': dest is not specified"

      return]

    constructor: (task, @_src) ->

      missingArg() if arguments.length < 2
      tooManyArgs() if arguments.length > 2

      super task

      @_configContainer = null

      throw new Error 'Invalid source file or directory name (1st argument)' unless typeof @_src == 'string' && @_src != ''

      {path: @_fixedSrc, single: @_singleFile} = preprocessPath @_src, "**/*"

      return # constructor:

    dest: (configContainer) ->

      invalidArg 'configContainer', configContainer unless typeof configContainer == 'object' && configContainer != null && typeof configContainer.__proto__?.watch == 'function'

      @_configContainer = configContainer

      tooManyArgs() unless arguments.length <= 2

      @ # dest:

    _build: ->

      return @_name if @_built

      @_mixinAssert?()

      TaskBase.addToWatch (=>
        global.gulp.watch @_fixedSrc, [@_name]
        return)

      class ReporterImpl extends Reporter

        _print: (type, msg) ->

          # TODO: Add messages limit

          switch type
            when 'error' then console.error gutil.colors.red "#{type}: #{msg}"
            when 'warn' then console.warn gutil.colors.green "#{type}: #{msg}"
            when 'info' then console.info "#{type}: #{msg}"
            else throw new Error "Unexpected 'type': #{type}"

          return # class ReporterImpl

      global.gulp.task @_name, @_deps, (cb) =>

        messages = messagesCompile (result = new ReporterImpl)

        if result.isError

          cb()

        else

          result = new ReporterImpl messages

          configLoader result, @_src
          .then ((loadedConfig) =>

            config = configCompile result, loadedConfig

            unless result.isError

              @_configContainer.set config

            cb()

            return), (-> cb(); return)

        return false # GLOBAL.gulp.task

      @_built = true
      return @_name # _build:

