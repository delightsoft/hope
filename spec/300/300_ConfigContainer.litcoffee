ConfigContainer
==============================

    SpecSteps = require '../_helpers/SpecSteps'

    ConfigContainer = require '../../src/dsGulpBuilderTasks/configContainer'

    focusOnCheck = ""
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return
    xcheck = (itName, itBody) -> return

    describe '300_ConfigContainer:', ->

      beforeEach ->

        @cc = new ConfigContainer

        @config = {}

        @config2 = {}

Вызывает метод watch, когда загрузчик сохраняет новую конфигурацию, срабатывает watch

      check 'watch on set', (done) ->

        new SpecSteps @, done, false

        .step # 1

          action: ->

            @cc.set @config

          expect: (done) ->

            unwatch = @cc.watch (config) =>

              expect(config).toBe @config

              unwatch(); done()

        .step # 2

          action: ->

            @cc.set @config2

          expect: (done) ->

            unwatch = @cc.watch (config) =>

              expect(config).toBe @config2

              unwatch(); done()

Если watch подключается, когда конфигурация

      check 'initial watch call', (done) ->

        @cc.set @config

        unwatch = @cc.watch (config) =>

          expect(config).toBe @config

          unwatch(); done()
