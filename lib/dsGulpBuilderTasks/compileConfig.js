var Reporter, Result, changed, configCompile, configLoader, gutil, messagesCompile, path, ref, ref1, rename, through,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

path = require('path');

gutil = require('gulp-util');

rename = require('gulp-rename');

through = require('through2');

changed = require('gulp-changed');

ref = require('../index'), Result = ref.Result, Reporter = ref.Reporter, configLoader = ref.loader, (ref1 = ref.config, configCompile = ref1.compile, messagesCompile = ref1.messages);

module.exports = function(DSGulpBuilder) {
  var CompileConfig, TaskBase, invalidArg, invalidOptionType, missingArg, preprocessPath, ref2, tooManyArgs, unsupportedOption;
  ref2 = TaskBase = DSGulpBuilder.TaskBase, invalidArg = ref2.invalidArg, tooManyArgs = ref2.tooManyArgs, missingArg = ref2.missingArg, unsupportedOption = ref2.unsupportedOption, invalidOptionType = ref2.invalidOptionType, preprocessPath = ref2.preprocessPath;
  return CompileConfig = (function(superClass) {
    var oldMixinAssert, ref3;

    extend(CompileConfig, superClass);

    ref3 = [
      CompileConfig.prototype._mixinAssert, function() {
        if (typeof oldMixinAssert !== "undefined" && oldMixinAssert !== null) {
          oldMixinAssert.call(this);
        }
        if (this._configContainer === null) {
          throw new Error("Task '" + this._name + "': dest is not specified");
        }
      }
    ], oldMixinAssert = ref3[0], CompileConfig.prototype._mixinAssert = ref3[1];

    function CompileConfig(task, _src) {
      var ref4;
      this._src = _src;
      if (arguments.length < 2) {
        missingArg();
      }
      if (arguments.length > 2) {
        tooManyArgs();
      }
      CompileConfig.__super__.constructor.call(this, task);
      this._configContainer = null;
      if (!(typeof this._src === 'string' && this._src !== '')) {
        throw new Error('Invalid source file or directory name (1st argument)');
      }
      ref4 = preprocessPath(this._src, "**/*"), this._fixedSrc = ref4.path, this._singleFile = ref4.single;
      return;
    }

    CompileConfig.prototype.dest = function(configContainer) {
      var ref4;
      if (!(typeof configContainer === 'object' && configContainer !== null && typeof ((ref4 = configContainer.__proto__) != null ? ref4.watch : void 0) === 'function')) {
        invalidArg('configContainer', configContainer);
      }
      this._configContainer = configContainer;
      if (!(arguments.length <= 2)) {
        tooManyArgs();
      }
      return this;
    };

    CompileConfig.prototype._build = function() {
      var ReporterImpl;
      if (this._built) {
        return this._name;
      }
      if (typeof this._mixinAssert === "function") {
        this._mixinAssert();
      }
      TaskBase.addToWatch(((function(_this) {
        return function() {
          global.gulp.watch(_this._fixedSrc, [_this._name]);
        };
      })(this)));
      ReporterImpl = (function(superClass1) {
        extend(ReporterImpl, superClass1);

        function ReporterImpl() {
          return ReporterImpl.__super__.constructor.apply(this, arguments);
        }

        ReporterImpl.prototype.constructore = function() {
          return ReporterImpl.__super__.constructore.apply(this, arguments);
        };

        ReporterImpl.prototype._print = function(type, msg) {
          switch (type) {
            case 'error':
              console.error(gutil.colors.red(type + ": " + msg));
              break;
            case 'warn':
              console.warn(gutil.colors.green(type + ": " + msg));
              break;
            case 'info':
              console.info(type + ": " + msg);
              break;
            default:
              throw new Error("Unexpected 'type': " + type);
          }
        };

        return ReporterImpl;

      })(Reporter);
      global.gulp.task(this._name, this._deps, (function(_this) {
        return function(cb) {
          var messages, result;
          messages = messagesCompile((result = new ReporterImpl));
          if (result.isError) {
            cb();
          } else {
            result = new ReporterImpl(messages);
            configLoader(result, _this._src).then((function(loadedConfig) {
              var config;
              config = configCompile(result, loadedConfig);
              if (!result.isError) {
                _this._configContainer.set(config);
              }
              cb();
            }), (function() {
              cb();
            }));
          }
          return false;
        };
      })(this));
      this._built = true;
      return this._name;
    };

    return CompileConfig;

  })(TaskBase);
};
