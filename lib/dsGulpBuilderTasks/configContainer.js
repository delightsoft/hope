var ConfigContainer, fs, invalidArg, invalidValue, path, ref, ref1, ref2, ref3, tooManyArgs, unlinkConfig;

fs = require('fs');

path = require('path');

ref = require('../index'), (ref1 = ref.config, unlinkConfig = ref1.unlink), (ref2 = ref.utils, (ref3 = ref2.err, invalidArg = ref3.invalidArg, invalidValue = ref3.invalidValue, tooManyArgs = ref3.tooManyArgs));

ConfigContainer = (function() {
  function ConfigContainer() {
    this._config = null;
    this._watch = [];
  }

  ConfigContainer.prototype.set = function(config) {
    var i, listener, ref4;
    this._config = config;
    ref4 = this._watch;
    for (i = ref4.length - 1; i >= 0; i += -1) {
      listener = ref4[i];
      listener(config);
    }
  };

  ConfigContainer.prototype.watch = function(listener) {
    var active, watch;
    if (typeof listener !== 'function') {
      invalidArg('listener', listener);
    }
    (watch = this._watch).push(listener);
    if (this._config) {
      process.nextTick((function(_this) {
        return function() {
          listener(_this._config);
        };
      })(this));
    }
    active = true;
    return function() {
      if (active) {
        active = false;
        return watch.splice(watch.indexOf(listener), 1);
      }
    };
  };

  ConfigContainer.prototype.save = function(destFile, opts) {
    var k, tab, v;
    if (!(typeof destFile === 'string' && destFile.length > 0)) {
      invalidArg('destFile', destFile);
    }
    if (!(typeof opts === 'undefined' || (typeof opts === 'object' && opts !== null))) {
      invalidArg('opts', opts);
    }
    if (!(arguments.length <= 2)) {
      tooManyArgs();
    }
    tab = void 0;
    if (opts) {
      for (k in opts) {
        v = opts[k];
        switch (k) {
          case 'tab':
            if (typeof v !== 'string') {
              invalidValue('opts.tab', v);
            }
            tab = v;
            break;
          default:
            invalidArg("opts." + k, v);
        }
      }
    }
    this.watch((function(_this) {
      return function(config) {
        var dir, file;
        dir = path.join(process.cwd(), path.dirname(destFile));
        if (!fs.existsSync(dir)) {
          fs.mkdirSync(dir);
        }
        file = path.join(dir, path.basename(destFile));
        if (fs.existsSync(file)) {
          fs.unlinkSync(file);
        }
        fs.writeFileSync(file, JSON.stringify(unlinkConfig(config), null, tab));
      };
    })(this));
  };

  return ConfigContainer;

})();

module.exports = ConfigContainer;
