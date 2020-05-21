const blockProcessTimer = setTimeout(function () {
}, (1 << 32) - 1);

const time = Date.now();

const failed = new Promise((resolve, reject) => {
  setTimeout(() => { resolve(123) }, 100);
});

const ok = new Promise((resolve, reject) => {
  setTimeout(() => { resolve(321) }, 3000);
});

// Promise.all([failed, ok])
awaitAll([failed, 1, 3, ok])
  .then(
    (data) => {
      console.info(10, Date.now() - time, data);
    },
    () => {
      console.info(11, Date.now() - time);
    })
  .finally(() => {
    clearTimeout(blockProcessTimer);
  });

const hasOwnProperty = Object.prototype.hasOwnProperty;

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
