var Result, deleteRequireCache, invalidArg, isResult, loader, path, ref, tooManyArgs;

path = require('path');

Result = require('./result');

ref = require('./utils').err, tooManyArgs = ref.tooManyArgs, invalidArg = ref.invalidArg, isResult = ref.isResult;

deleteRequireCache = function(id) {
  var files;
  if (!id || id.indexOf('node_modules') !== -1) {
    return;
  }
  files = require.cache[id];
  if (files !== void 0) {
    Object.keys(files.children).forEach(function(file) {
      deleteRequireCache(files.children[file].id);
    });
    delete require.cache[id];
  }
};

loader = function(result, sourceDir) {
  if (!isResult(result)) {
    invalidArg('result', result);
  }
  if (!(typeof sourceDir === 'string' && sourceDir.length > 0)) {
    invalidArg('sourceDir', sourceDir);
  }
  if (!(arguments.length <= 2)) {
    tooManyArgs();
  }
  return new Promise(function(resolve, reject) {
    var dir, loadFile, res, rights, udt;
    dir = path.join(process.cwd(), sourceDir);
    loadFile = function(filename, required) {
      var err, isFileItself, modId;
      try {
        filename = path.join(dir, filename);
        modId = require.resolve(filename);
        deleteRequireCache(modId);
        return require(filename);
      } catch (error) {
        err = error;
        isFileItself = (err.message.indexOf(filename)) >= 0;
        if (isFileItself) {
          if (required) {
            result.error('dsc.missingFile', {
              value: filename
            });
          } else {
            result.warn('dsc.noSuchFile', {
              value: filename
            });
          }
        } else {
          result.error((function() {
            return filename;
          }), 'dsc.compilerError', {
            value: err.message,
            stack: err.stack
          });
        }
      }
    };
    res = {
      docs: loadFile('docs', true)
    };
    if ((udt = loadFile('udt', false))) {
      res.udt = udt;
    }
    if ((rights = loadFile('rights', false))) {
      res.rights = rights;
    }
    if (result.isError) {
      reject(result);
    } else {
      resolve(res);
    }
  });
};

module.exports = loader;
