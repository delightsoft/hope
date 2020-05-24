const {promisify} = require('util');
const path = require('path');
const {spawn: realSpawn} = require('child_process');
const chokidar = require('chokidar');
const copy = promisify(require('copy'));
const rimraf = promisify(require('rimraf'));
const cmd = require('commander');
const glob = promisify(require('glob'));

const {Task, serial, parallel, runTasks, spawn} = require('../../../server/src/common/build');

cmd
  .name(`node scripts/build.js`)
  .option(`-d, --dev`, `development mode`)
  .option(`-c, --coverage`, `build coverage`)
  .parse(process.argv);

const atch = !cmd.dev || cmd.coverage;

runTasks({

  watch: cmd.dev,

  tasks:
    serial([

      parallel([

        !cmd.coverage && new Task({
          name: `clean 'lib'`,
          run() {
            return rimraf(path.join(process.cwd(), 'lib/'));
          },
        }),

        new Task({
          name: `clean 'temp'`,
          run() {
            return rimraf(path.join(process.cwd(), 'temp/'));
          },
        }),

        !cmd.coverage && new Task({
          name: `clean 'docco'`,
          run() {
            return rimraf(path.join(process.cwd(), 'docco/'));
          },
        }),
      ]),

      parallel([

        serial([

          parallel([

            new Task({
              name: `compile 'src/' to 'temp/src/'`,
              run() {
                return spawn('node', ['node_modules/coffeescript/bin/coffee', '--transpile', '--output', path.join(process.cwd(), 'temp/src/'), path.join(process.cwd(), 'src/')]);
              },
              watch(cb) {
                chokidar.watch(path.join(process.cwd(), 'src/**/*.(coffee|litcoffee)'), {ignoreInitial: true}).on('all', cb);
              },
            }),

            new Task({
              name: `compile 'spec/' to 'temp/spec/'`,
              run() {
                return spawn('node', ['node_modules/coffeescript/bin/coffee', '--compile', '--output', path.join(process.cwd(), 'temp/spec/'), path.join(process.cwd(), 'spec/')]);
              },
              watch(cb) {
                chokidar.watch(path.join(process.cwd(), 'spec/**/*.(coffee|litcoffee)'), {ignoreInitial: true}).on('all', cb);
              },
            }),

            new Task({
              name: `copy 'samples/' to 'temp/samples/'`,
              run() {
                return copy(path.join(process.cwd(), 'samples/**/*'), path.join(process.cwd(), 'temp/samples/'));
              },
              watch(cb) {
                chokidar.watch(path.join(process.cwd(), 'spec/**/*'), {ignoreInitial: true}).on('all', cb);
              },
            }),
          ]),

          !cmd.coverage && new Task({
            name: `jasmine 'temp/spec/'`,
            run() {
              return spawn('node', ['node_modules/jasmine/bin/jasmine.js', path.join(process.cwd(), 'temp/spec/**/*.js')]);
            },
            watch(cb) {
              chokidar.watch(path.join(process.cwd(), 'spec/**/*.(coffee|litcoffee)'), {ignoreInitial: true}).on('all', cb);
            },
          }),

          cmd.coverage && new Task({
            name: `code coverage of 'temp/spec/' to 'lib/Icov-report/index.html'`,
            run() {
              return spawn('node', ['node_modules/istanbul/lib/cli.js', 'cover', 'node_modules/jasmine/bin/jasmine.js', path.join(process.cwd(), 'temp/spec/**/*.js')]);
            },
          }),

          !cmd.coverage && new Task({
            name: `copy 'temp/src/' to 'lib/'`,
            run() {
              return copy(path.join(process.cwd(), 'temp/src/**/*'), path.join(process.cwd(), 'lib/'));
            },
          }),

          !cmd.dev && new Task({
            name: `clean 'temp'`,
            run() {
              return rimraf(path.join(process.cwd(), 'temp/'));
            },
          }),
        ]),

        new Task({
          name: `docco 'spec/' to 'docco/'`,
          run() {
            return glob('spec/**/*.litcoffee')
              .then((files) => {
                return spawn('node', ['node_modules/docco/bin/docco', '--output', 'docco'].concat(files), {
                  stdio: 'ignore',
                });
              });
          },
          watch(cb) {
            chokidar.watch(path.join(process.cwd(), 'spec/**/*.litcoffee'), {ignoreInitial: true}).on('all', cb);
          },
        }),
      ]),
    ]),
});
