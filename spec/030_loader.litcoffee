loader
==============================

    {Result, loader,
    utils: {deepClone, prettyPrint}} = require '../src'

    focusOnCheck = ""
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe "030_loader", ->

      check 'general', (done) ->

        loader (result = new Result), './samples'
        .then (config) ->
          expect(config.docs).toBeDefined()
          done()
          return
        .catch (err) ->
          expect(err.messages).toEqual []
          done()
