const {promisify} = require('util');
const debounce = require('lodash/debounce')
const path = require('path');
const {spawn: realSpawn} = require('child_process');
const chokidar = require('chokidar');
const chalk = require('chalk');
const copy = promisify(require('copy'));
const rimraf = promisify(require('rimraf'));
const cmd = require('commander');

const blockProcessTimer = setTimeout(() => {
}, 0x7FFFFFFF);

cmd
  .name(`node scripts/build.js`)
  .option(`-d, --dev`, `development mode`)
  .parse(process.argv);

class Task {
  constructor({name, run, watch}) {
    if (!(typeof name === 'string' && name.length > 0)) throw new Error(`Invalid argument 'name': ${name}`);
    if (!(typeof run === 'function')) throw new Error(`Invalid argument 'run': ${run}`);
    if (!(!watch || (typeof watch === 'function' && watch.length === 1))) throw new Error(`Invalid argument 'watch': ${watch}`);
    this.parent = null;
    this.name = name;
    this.run = run;
    this.lastRun = null;
    this.working = false;
    this.updateTime = null;
    if (watch) {
      watch(debounce(() => {
        const t = Date.now();
        let level = this;
        while (level) {
          level.updateTime = t;
          level = level.parent;
        }
        startOver();
      }, 250, {maxWait: 30 * 1000}));
    }
  }

  _run() {
    if (this.working) return;
    this.working = true;
    const startTime = Date.now();
    console.info(`${this.name}: ${chalk.blue(`started`)}`);
    const prevUpdateTime = this.updateTime;
    let res;
    try {
      res = this.run();
    } catch (err) {
      console.error(err);
    }
    res.then(() => {
      console.info(`${this.name}: ${chalk.green(`completed in ${Math.round((Date.now() - startTime) / 10) / 100} sec`)}`);
      if (!restartTasks && prevUpdateTime === this.updateTime) this.lastRun = Date.now(); // there was NO a watch event while task was running
    }, (err) => {
      console.info(`${this.name}: ${chalk.red(`failed:`)} ${err.message}`);
    }).finally(() => {
      this.working = false;
    });
    return res;
  }
}

const tasks =
  serial([
    parallel([
      new Task({
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
      new Task({
        name: `clean 'docs'`,
        run() {
          return rimraf(path.join(process.cwd(), 'html/'));
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
              cmd.dev && chokidar.watch(path.join(process.cwd(), 'src/**/*.(coffee|litcoffee)'), {ignoreInitial: true}).on('all', cb);
            },
          }),
          new Task({
            name: `compile 'spec/' to 'temp/spec/'`,
            run() {
              return spawn('node', ['node_modules/coffeescript/bin/coffee', '--compile', '--output', path.join(process.cwd(), 'temp/spec/'), path.join(process.cwd(), 'spec/')]);
            },
            watch(cb) {
              cmd.dev && chokidar.watch(path.join(process.cwd(), 'spec/**/*.(coffee|litcoffee)'), {ignoreInitial: true}).on('all', cb);
            },
          }),
          new Task({
            name: `copy 'samples/' to 'temp/samples/'`,
            run() {
              return copy(path.join(process.cwd(), 'samples/**/*'), path.join(process.cwd(), 'temp/samples/'));
            },
            watch(cb) {
              cmd.dev && chokidar.watch(path.join(process.cwd(), 'spec/**/*'), {ignoreInitial: true}).on('all', cb);
            },
          }),
        ]),
        new Task({
          name: `jasmine 'temp/spec/'`,
          run() {
            return spawn('node', ['node_modules/jasmine/bin/jasmine.js', path.join(process.cwd(), 'temp/spec/**/*.js')]);
          },
          watch(cb) {
            cmd.dev && chokidar.watch(path.join(process.cwd(), 'spec/**/*.(coffee|litcoffee)'), {ignoreInitial: true}).on('all', cb);
          },
        }),
        new Task({
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
      /*
            new Task({
              name: `docco 'spec/' to 'html/'`,
              run() {
                return spawn('node', ['node_modules/docco/bin/docco', '--transpile', '--output', path.join(process.cwd(), 'lib/'), path.join(process.cwd(), 'src/')]);
              },
              watch(cb) {
                chokidar.watch(path.join(process.cwd(), 'src/!**!/!*.(coffee|litcoffee)'), {ignoreInitial: true}).on('all', cb);
              },
            }),
      */
    ]),
  ]);

let restartTasks;

function startOver() {
  if (tasks.working) {
    restartTasks = true;
    return;
  }
  restartTasks = false;
  return tasks._run()
    .catch((err) => {
      // console.error(err);
    })
    .then(() => {
      if (restartTasks) startOver();
    });
}

startOver()
  .finally(function () {
    !cmd.dev && clearTimeout(blockProcessTimer);
  });

function parallel(tasks) {
  const task = {
    lastRun: null,
    working: false,
    _run(prevLastRun) {
      if (this.working) return;
      this.working = true;
      try {
        const prevUpdateTime = this.updateTime;
        const promises = tasks.reduce((acc, t) => {
          if (!t) return acc; // empty
          if ((t.lastRun === null) || // it's first time
            (prevLastRun !== null && t.lastRun < prevLastRun) || // previous task result was updated
            (typeof t.updateTime === 'number' && t.updateTime >= t.lastRun)) { // there was a signal from 'watch' to run this task again
            acc.push(t._run(prevLastRun));
          }
          return acc;
        }, []);
        return awaitAll(promises)
          .then(() => {
            if (!restartTasks && prevUpdateTime === this.updateTime) this.lastRun = Date.now(); // there was NO a watch event while task was running
          })
          .finally(() => {
            this.working = false;
          });
      } catch (err) {
        console.error(err)
      }
    }
  };
  tasks.forEach(v => {
    v.parent = task;
  });
  return task;
}

function serial(tasks) {
  const task = {
    lastRun: null,
    working: false,
    _run() {
      if (this.working) return;
      this.working = true;
      const prevUpdateTime = this.updateTime
      return (new Promise((resolve, reject) => {
        return _serial(tasks, resolve, reject)
      }))
        .then(() => {
          if (!restartTasks && prevUpdateTime === this.updateTime) this.lastRun = Date.now(); // there was NO a watch event while task was running
        })
        .finally(() => {
          this.working = false;
        });
    }
  };
  tasks.forEach(v => {
    v.parent = task;
  });
  return task;
}

function _serial(tasks, resolve, reject) {
  if (!Array.isArray(tasks)) throw new Error(`Invalid argument 'tasks': %{tasks}`);
  let prevLastRun = null;
  const task = tasks.find((t, i) => {
    if (!t) return; // empty
    if (t.lastRun === null) return true; // it's first time
    if (i > 0) {
      prevLastRun = tasks[i - 1].lastRun;
      if (t.lastRun < prevLastRun) return true; // previous task result was updated
    }
    if (typeof t.updateTime === 'number' && t.updateTime >= t.lastRun) return true; // there was a signal from 'watch' to run this task again
  });
  if (task) {
    const prevUpdateTime = this.updateTime;
    task._run(prevLastRun).then(
      () => {
        if (prevUpdateTime === task.updateTime) task.lastRun = Date.now(); // there was NO a watch event while task was running
        if (restartTasks) {
          resolve();
          return;
        }
        _serial(tasks, resolve, reject);
      },
      (err) => {
        reject(err);
      });
  } else {
    resolve();
  }
}

function spawn(command, args, options) {
  return new Promise((resolve, reject) => {
    const p = realSpawn(command, args || [], Object.assign({
      stdio: [process.stdin, process.stdout, process.stderr],
    }, options));
    p.on('error', (err) => reject(err));
    p.on('exit', () => {
      p.exitCode !== 0 ? reject(new Error(`exitCode: ${p.exitCode}`)) : resolve(p);
    });
  });
}

function awaitAll(promises) {
  if (!Array.isArray(promises)) throw new Error(`Invalid argument 'promises': ${promises}`);
  let left = 0, isErr, err;
  return new Promise((resolve, reject) => {
    const res = promises.map((v, i) => {
      if (typeof v === 'object' && v !== null && typeof v.then === 'function') {
        left++;
        v.then(
          (data) => {
            res[i] = data;
            if (--left === 0) isErr ? reject(err) : resolve(res);
          },
          (_err) => {
            if (--left === 0) reject(isErr ? err : _err);
            else if (!isErr) {
              isErr = true;
              err = _err;
            }
          }
        );
      } else {
        return v;
      }
    });
    if (left === 0) resolve();
  });
}
