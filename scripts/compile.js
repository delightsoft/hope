const debounce = require('lodash/debounce')
const path = require('path');
const {spawn: realSpawn} = require('child_process');
const chokidar = require('chokidar');
const chalk = require('chalk');

const blockProcessTimer = setTimeout(function () {
}, (1 << 32) - 1);

class Task {
  constructor({name, run, watch}) {
    this.name = name;
    this.run = run;
    this.lastRun = null;
    this.working = false;
    this._updateTime = null;
    if (this.watch = watch) {
      watch(debounce(() => {
        this.updateTime = Date.now();
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
    const res = this.run();
    res.then(() => {
      console.info(`${this.name}: ${chalk.green(`completed in ${Math.round((Date.now() - startTime) / 10) / 100} sec`)}`);
      this.lastRun = Date.now();
      if (prevUpdateTime !== this.updateTime) this.updateTime = this.lastRun; // there was a watch event while task was running
    }, (err) => {
      console.info(`${this.name}: ${chalk.red(`failed:`)} ${err.message}`);
    }).finally(() => {
      this.working = false;
    });
    return res;
  }
}

const tasks = parallel([
// const tasks = serial([
  new Task({
    name: 'compile src',
    run() {
      return spawn('node', ['node_modules/coffeescript/bin/coffee', '--transpile', '--output', path.join(process.cwd(), 'lib/src/'), path.join(process.cwd(), 'src/')]);
    },
    watch(cb) {
      chokidar.watch(path.join(process.cwd(), 'src/**/*.(coffee|litcoffee)'), {ignoreInitial: true}).on('all', cb);
    },
  }),
  new Task({
    name: 'compile spec',
    run() {
      return spawn('node', ['node_modules/coffeescript/bin/coffee', '--compile', '--output', path.join(process.cwd(), 'lib/spec/'), path.join(process.cwd(), 'spec/')]);
    },
    watch(cb) {
      chokidar.watch(path.join(process.cwd(), 'spec/**/*.(coffee|litcoffee)'), {ignoreInitial: true}).on('all', cb);
    },
  }),
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

startOver();
// .finally(function () {
//   clearTimeout(blockProcessTimer);
// });

function parallel(tasks) {
  return {
    lastRun: null,
    working: false,
    _run(prevLastRun) {
      if (this.working) return;
      this.working = true;
      const promises = tasks.reduce((acc, t) => {
        if (!t) return acc; // empty
        if (t.lastRun === null) acc.push(t._run()); // it's first time
        else if (prevLastRun !== null && t.lastRun < prevLastRun) acc.push(t._run()); // previous task result was updated
        else if (typeof t.updateTime === 'number' && t.updateTime >= t.lastRun) acc.push(t._run()); // there was a signal from 'watch' to run this task again
        return acc;
      }, []);
      return awaitAll(promises)
        .then(() => {
          this.lastRun = Date.now();
        })
        .finally(() => {
          this.working = false;
        });
    }
  };
}

function serial(tasks) {
  return {
    lastRun: null,
    working: false,
    _run() {
      if (this.working) return;
      this.working = true;
      return (new Promise((resolve, reject) => {
        return _serial(tasks, resolve, reject)
      }))
        .then(() => {
          this.lastRun = Date.now();
        })
        .finally(() => {
          this.working = false;
        });
    }
  }
}

function _serial(tasks, resolve, reject) {
  if (!Array.isArray(tasks)) throw new Error(`Invalid argument 'tasks': %{tasks}`);
  let prevLastRun = null;
  const task = tasks.find((t, i) => {
    if (!t) return; // empty
    if (t.lastRun === null) return true; // it's first time
    if (i > 0) {
      prevLastRun = tasks[i - 1].lastRun;
      if (i > 0 && t.lastRun < prevLastRun) return true; // previous task result was updated
    }
    if (typeof t.updateTime === 'number' && t.updateTime >= t.lastRun) return true; // there was a signal from 'watch' to run this task again
  });
  if (task) {
    task._run(prevLastRun).then(
      () => {
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
