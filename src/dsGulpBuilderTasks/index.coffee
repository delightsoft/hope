ConfigContainer = require './configContainer'

extend = (DSGulpBuilder) ->

  for taskName, taskClassDef of require('require-dir')( './tasks', { recurse: false })
    do (taskName, taskClassDef) =>

      taskClass = taskClassDef DSGulpBuilder

      ConfigContainer::[taskName[0].toLowerCase() + taskName.substr 1] = ->
        newInstance = Object.create(taskClass::)
        args = [@]
        args.push arg for arg in arguments
        taskClass.apply newInstance, args
        return newInstance


  taskClass = require('./compileConfig')(DSGulpBuilder)

  DSGulpBuilder.Task::compileConfig = ->
    newInstance = Object.create(taskClass::)
    args = [@]
    args.push arg for arg in arguments
    taskClass.apply newInstance, args
    return newInstance

  ConfigContainer # extend =

# ----------------------------

extend.default = extend

module.exports = extend