Код DSCommon везде расчитывает, что:
- Глобальные Promise реализованны библиотекой bluebird

    {Result, compareStructures, utils: {err: {isResult}}} = require '../src'

    beforeEach ->

Весь код DSCommon3 ориентируется на то, что система будет работать с библиотекой bluebird.  При этом будет
переопределен голобальный Promise.  Это сделано, по аналогии, с тем как с Promise работает sequelize.js

      global.Pormise = require 'bluebird'

      global.moment  = require 'moment'

Для проверки что объект Result содержит определенные сообщения, делаем custom matcher

      jasmine.addMatchers

        resultContains: (util, customEqualityTesters) ->

          compare: (actual, expected) ->

            # проверяем что actual правильного типа

            unless isResult actual

              return {

                pass: false

                message: "Expected actual value to be a Result object, but it was '#{jasmine.pp actual}'."}

            # проверяем, что array

            unless (failed = not Array.isArray expected)

              failed = true for v in expected when not (typeof v == 'object' && v != null)

            if failed

              return {

                pass: false

                message: "Expected actual value to be an array of Result messages, but it is '#{jasmine.pp expected}'."}

            # ишем среди полученных сообщений, чтоб было каждое ожидаемое сообщение

            for expectedMessage in expected

              pass = false

              pass = true for actualMessage in actual.messages when util.equals expectedMessage, actualMessage, customEqualityTesters

              (missingMessages = []).push expectedMessage unless pass

            if missingMessages # compare: (actual, expected) ->

              pass: false

              # message: "Expected #{nodeJSUtil.inspect actual.messages} to has following messages #{nodeJSUtil.inspect missingMessages}"

              message: "Expected #{jasmine.pp actual.messages} to has following messages #{jasmine.pp missingMessages}."

            else

              pass: true

        sameStructure: (util, customEqualityTesters) ->

          compare: (actual, expected) ->

            compareStructures (result = new Result), actual, expected

            if result.messages.length > 0

              pass: false

              # message: "Diff: #{jasmine.pp result.messages}"
              message: "Diff: #{jasmine.pp result.messages};\n Actual: '#{jasmine.pp actual}';\n Expected: '#{jasmine.pp expected}'"

            else

              pass: true
