const path = require('path');
const {spawn: realSpawn} = require('child_process');
const chokidar = require('chokidar');

const blockProcessTimer = setTimeout(function () {
}, (1 << 32) - 1);

class Task {
  constructor({name, run, watch}) {
    this.name = name;
    this.run = run;
    this.lastRun = null;
    this.working = false;
    if (this.watch = watch) {
      watch(() => {
        // console.info(30, arguments)
        this.updateTime = Date.now();
        startOver();
      });
    }
  }

  _run() {
    if (this.working) return;
    this.working = true;
    const startTime = Date.now();
    console.info(`${this.name}: started`);
    const prevUpdateTime = this.updateTime;
    const res = this.run();
    res.then(() => {
      console.info(32, prevUpdateTime !== this.upateTime)
      console.info(`${this.name}: completed in ${Math.round((Date.now() - startTime) / 10) / 100} sec`);
      this.lastRun = Date.now();
      console.info(33, prevUpdateTime !== this.upateTime)
      if (prevUpdateTime !== this.upateTime) this.upateTime = this.lastRun; // there was a watch event while task was running
    }, (err) => {
      console.info(`${this.name}: failed: ${err.message}`);
    }).finally(() => {
      this.working = false;
    });
    return res;
  }
}

const tasks = serial([
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
      console.info(88, restartTasks)
      if (restartTasks) startOver();
    });
}

startOver();
// .finally(function () {
//   clearTimeout(blockProcessTimer);
// });


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
  const task = tasks.find((t, i) => {
    if (!t) return; // empty
    if (t.lastRun === null) return true; // it's first time
    if (i > 0 && t.lastRun < tasks[i - 1].lastRun) return true; // previous task result was updated
    console.info(115, t.updateTime - t.lastRun, this.name)
    if (typeof t.updateTime === 'number' && t.updateTime >= t.lastRun) return true; // there was a signal from 'watch' to run this task again
  });
  if (task) {
    task._run().then(
      () => {
        console.info(120, restartTasks)
        if (restartTasks) { resolve(); return; }
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
