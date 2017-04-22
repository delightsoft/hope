#istanbul = require 'gulp-coffee-istanbul'

{task, async, sync, go, gutil} = require('ds-gulp-builder')(gulp = require('gulp'))
#{task, async, sync, go, gutil, errorHandler} = require('C://GIT//DSGulpBuilder//main//lib')(gulp = require('gulp'), -> gutil.env.production)

tasks = []

# Clear ./build and ./generated folders
clearFolders = [

  task('clear-build').clearFolder('./build').keep('.git')

  task('clear-generated').clearFolder('./generated').keep('.git')

  task('clear-docs').clearFolder('./docs').keep('.git')
]

# ----------------------------
# Compile specs to ./generated/*.js  This helps to debug a problem in some rear cases

if gutil.env.production

  tasks.push task('compile-es5-src').coffee2js("./src").dest("./lib")

if gutil.env.compilespec

  tasks.push task('compile-src').coffee2js("./src").dest("./generated/src")

  tasks.push task('compile-specs').coffee2js("./spec").dest("./generated/spec")

# ----------------------------
# Build HTML verison

buildTasks = []

#buildTasks.push task('build-js').browserify('./src/index.coffee').dest('./build')
#
#buildTasks.push task('build-html').jade('./src').dest('./build')
#
#tasks.push sync [buildTasks, task('browser-sync', buildTasks).browserSync('./build')]

# ----------------------------
# Run specs

unless gutil.env.compilespec

  # specsFilter = /\/200\/.*$/i
  # specsFilter = /$/i
  # tasks.push task('run-specs').jasmine('./spec', debug: true, filter: specsFilter, coverage: !!gutil.env.cover, includeStackTrace: !!gutil.env.stack, stackFilter: require('./src/utils/_lightStack')).watch(["./src/**/*.+(coffee|litcoffee|js)", "./src-gulp/**/*.+(coffee|litcoffee|js)"])
  tasks.push task('run-specs').jasmine('./spec', debug: true, coverage: !!gutil.env.cover, includeStackTrace: !!gutil.env.stack, stackFilter: require('./src/utils/_lightStack')).watch(["./src/**/*.+(coffee|litcoffee|js)", "./src-gulp/**/*.+(coffee|litcoffee|js)"])

#  do (name = 'docco', src = "./spec/**/*.litcoffee", dest = './docs') ->
#
#    tasks.push name
#    gulp.task name, ->
#
#      gulp.watch src, [name]
#
#      gulp.src src
#      .pipe (require 'gulp-docco')()
#      .pipe gulp.dest dest # gulp.task name, ->

# ----------------------------
# Run

go sync [clearFolders, tasks]
