const {promisify} = require('util');
const glob = promisify(require('glob'));
const docco = require('docco');

const blockProcessTimer = setTimeout(() => {
}, 0x7FFFFFFF);

glob('spec/**/*.litcoffee')
  .then((files) => {
    console.info(10, files);
  })
  .finally(function () {
    clearTimeout(blockProcessTimer);
  });




