var ConfigContainer, extend;

ConfigContainer = require('./configContainer');

extend = function(DSGulpBuilder) {
  var fn, ref, taskClass, taskClassDef, taskName;
  ref = require('require-dir')('./tasks', {
    recurse: false
  });
  fn = (function(_this) {
    return function(taskName, taskClassDef) {
      var taskClass;
      taskClass = taskClassDef(DSGulpBuilder);
      return ConfigContainer.prototype[taskName[0].toLowerCase() + taskName.substr(1)] = function() {
        var arg, args, i, len, newInstance;
        newInstance = Object.create(taskClass.prototype);
        args = [this];
        for (i = 0, len = arguments.length; i < len; i++) {
          arg = arguments[i];
          args.push(arg);
        }
        taskClass.apply(newInstance, args);
        return newInstance;
      };
    };
  })(this);
  for (taskName in ref) {
    taskClassDef = ref[taskName];
    fn(taskName, taskClassDef);
  }
  taskClass = require('./compileConfig')(DSGulpBuilder);
  DSGulpBuilder.Task.prototype.compileConfig = function() {
    var arg, args, i, len, newInstance;
    newInstance = Object.create(taskClass.prototype);
    args = [this];
    for (i = 0, len = arguments.length; i < len; i++) {
      arg = arguments[i];
      args.push(arg);
    }
    taskClass.apply(newInstance, args);
    return newInstance;
  };
  return ConfigContainer;
};

extend["default"] = extend;

module.exports = extend;
